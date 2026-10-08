import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hats.dart';
import '../models/meme_character.dart';
import '../services/achievements.dart';
import '../services/local_store.dart';
import '../services/sound.dart';
import 'components/backdrop.dart';
import 'components/effects.dart';
import 'components/enemy.dart';
import 'components/items.dart';
import 'components/player.dart';
import 'level.dart';
import 'level_gen.dart';

/// Tiles visible vertically (sets the zoom).
const double kTilesVisible = 9.5;

/// World units of extra ground drawn under the level.
const kGroundBelow = kTile * 2;

/// Dev aid: `--dart-define=MEMES_START_COL=120` drops the player at that
/// column to test the end of a level.
const _debugStartCol = int.fromEnvironment('MEMES_START_COL');

/// Buttons currently held, fed by the keyboard and the touch controls.
class GameInput {
  bool left = false;
  bool right = false;
  bool jump = false;

  /// A recent jump press, consumed by the player (makes jumps forgiving).
  double jumpBuffer = 0;
  bool specialQueued = false;

  void pressJump() {
    jump = true;
    jumpBuffer = 0.14;
  }

  void clear() {
    left = right = jump = specialQueued = false;
    jumpBuffer = 0;
  }
}

/// "Memes: the game" — a 2D platformer starring real memes.
class MemesGame extends FlameGame with KeyboardEvents {
  MemesGame({required this.character, required this.levelIndex})
    : level = levelAt(levelIndex).copy();

  static const overlayHud = 'hud';
  static const overlayPause = 'pause';
  static const overlayComplete = 'complete';
  static const overlayGameOver = 'gameOver';
  static const overlayIntro = 'intro';
  static const overlayBoss = 'boss';

  final MemeCharacter character;
  final int levelIndex;
  final LevelData level;
  final input = GameInput();

  late final Player player;

  /// Hat equipped in the shop (cosmetic).
  final Hat? hat = LocalStore.ready
      ? Hat.byId(LocalStore.instance.equippedHat)
      : null;
  final List<Enemy> enemies = [];
  final List<MovingPlatform> platforms = [];

  /// When each spring tile was last used (for its animation).
  final Map<int, double> springTimes = {};

  // Run state.
  double elapsed = 0;
  int likes = 0;

  /// Seconds of slow motion for enemies (Chihuahua Relax's holidays).
  double slowMo = 0;
  double get enemyTimeScale => slowMo > 0 ? 0.3 : 1;
  int likeScore = 0;
  int kills = 0;
  int enemyScore = 0;
  bool finished = false;

  /// True once the player has lost a heart in this run.
  bool damageTaken = false;

  bool _bossIntroDone = false;

  /// Countdown to the "level complete" screen after touching the flag.
  double? _completeIn;
  bool isOver = false;
  bool _bossAlive = false;
  late Vector2 _checkpoint;
  double _shake = 0;
  double _shakeDur = 1;
  double _shakeAmp = 0;
  double _hitStop = 0;
  final _rnd = Random();

  /// Bumped ~10 times a second so Flutter overlays can rebuild.
  final hudTick = ValueNotifier<int>(0);
  double _hudAcc = 0;

  /// Counted before any block is opened.
  late final int totalLikes;
  int get timeBonus => max(0, level.parTime - elapsed.floor()) * 5;
  int get score =>
      likeScore + enemyScore + (finished ? timeBonus + player.hearts * 100 : 0);

  /// 1 star for finishing, 2 with half the likes, 3 with 90% of them.
  int get stars {
    if (!finished) return 0;
    final ratio = totalLikes == 0 ? 1 : likes / totalLikes;
    return ratio >= .9 ? 3 : (ratio >= .5 ? 2 : 1);
  }

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    totalLikes = level.totalLikes;
    await images.loadAll([
      character.spriteSheet,
      ?character.afterSpecialSheet,
      for (final k in EnemyKind.values) k.spritePath,
      'sprites/tiles_${level.theme.name}.png',
      'sprites/moving_${level.theme.name}.png',
      'sprites/props_${level.theme.name}.png',
      'sprites/bg_${level.theme.name}_mid.png',
      'sprites/dust.png',
      'sprites/powerups.png',
      'sprites/sunglasses.png',
      Hat.sheet,
      'sprites/sparkle.png',
      'sprites/bg_${level.theme.name}_far.png',
      'sprites/bg_${level.theme.name}_clouds.png',
      'sprites/like.png',
      'sprites/flag.png',
      'sprites/checkpoint.png',
      'sprites/ratio.png',
    ]);

    camera.backdrop.add(Backdrop());
    world.add(LevelMap());
    world.add(Props());

    Vector2? start;
    for (final s in level.spawns) {
      final kind = EnemyKind.fromCode(s.code);
      if (kind != null) {
        world.add(Enemy(kind: kind, position: s.feet));
        if (kind.isBoss) _bossAlive = true;
        continue;
      }
      switch (s.code) {
        case 'P':
          start = s.feet;
        case 'o':
          world.add(Like(position: s.feet - Vector2(0, kTile / 2)));
        case 'K':
          world.add(Checkpoint(position: s.feet));
        case 'F':
          world.add(FinishFlag(position: s.feet));
        case 'M':
          world.add(MovingPlatform(spawn: s));
      }
    }
    _checkpoint = start ?? Vector2(kTile * 2, kTile * 10);
    if (_debugStartCol > 0) {
      _checkpoint = Vector2((_debugStartCol + .5) * kTile, kTile * 2);
    }
    player = Player(character: character, position: _checkpoint.clone());
    world.add(player);

    // Follow a point a bit below the feet, so the player sits above the
    // touch controls.
    final target = _CameraTarget(player);
    world.add(target);
    camera.follow(target);
    Sound.music('level');
    overlays.add(overlayIntro);
    if (LocalStore.ready) {
      LocalStore.instance.markPlayedWith(character.id);
      Achievements.checkStats();
    }
  }

  /// Keeps the view inside the level (Flame's viewport-aware bounds ignore
  /// the zoom). The extra ground below the level lifts the action above the
  /// touch controls at the bottom of the screen.
  /// Open sky the camera may show above the level, so high jumps don't end
  /// up under the HUD.
  static const _skyAbove = kTile * 2.5;

  void _clampCamera() {
    final vf = camera.viewfinder;
    final half = size / vf.zoom / 2;
    final maxY = level.height + kGroundBelow;
    vf.position = Vector2(
      half.x * 2 >= level.width
          ? level.width / 2
          : vf.position.x.clamp(half.x, level.width - half.x),
      half.y * 2 >= maxY + _skyAbove
          ? (maxY - _skyAbove) / 2
          : vf.position.y.clamp(half.y - _skyAbove, maxY - half.y),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Show ~9.5 tiles vertically, whatever the screen: big enough to read
    // the memes on a phone, with plenty of room ahead in landscape.
    camera.viewfinder.zoom = size.y / (kTile * kTilesVisible);
  }

  @override
  void update(double dt) {
    dt = min(dt, 1 / 30);
    if (_hitStop > 0) {
      _hitStop -= dt;
      _updateShake(dt);
      return;
    }
    if (slowMo > 0) slowMo -= dt;
    if (!finished && !isOver) elapsed += dt;
    if (input.jumpBuffer > 0) input.jumpBuffer -= dt;
    final overIn = _gameOverIn;
    if (overIn != null) {
      _gameOverIn = overIn - dt;
      if (_gameOverIn! <= 0) {
        _gameOverIn = null;
        overlays.add(overlayGameOver);
        pauseEngine();
      }
    }
    final completeIn = _completeIn;
    if (completeIn != null) {
      _completeIn = completeIn - dt;
      if (_completeIn! <= 0) {
        _completeIn = null;
        overlays.remove(overlayHud);
        overlays.add(overlayComplete);
      }
    }
    super.update(dt);
    if (isLoaded) {
      _clampCamera();
      _checkBossIntro();
    }
    _updateShake(dt);
    _hudAcc += dt;
    if (_hudAcc > 0.1) {
      _hudAcc = 0;
      hudTick.value++;
    }
  }

  // ----------------------------------------------------------------- input

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    bool any(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);
    const jumpKeys = [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyZ,
    ];
    input.left = any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA]);
    input.right = any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]);
    input.jump = any(jumpKeys);
    if (event is KeyDownEvent) {
      final k = event.logicalKey;
      if (jumpKeys.contains(k)) input.pressJump();
      if (k == LogicalKeyboardKey.keyX ||
          k == LogicalKeyboardKey.keyK ||
          k == LogicalKeyboardKey.keyJ ||
          k == LogicalKeyboardKey.keyC ||
          k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight) {
        input.specialQueued = true;
      }
      if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.keyP) {
        togglePause();
      }
    }
    return KeyEventResult.handled;
  }

  // ----------------------------------------------------------- level events

  // Likes picked up in quick succession play rising notes.
  int _likeStreak = 0;
  double _lastLike = -1;

  void collectLike(Like like) {
    likes++;
    _likeStreak = elapsed - _lastLike < 0.6 ? _likeStreak + 1 : 0;
    _lastLike = elapsed;
    final value =
        10 * multiplier * (character.passive == Passive.jewels ? 2 : 1);
    likeScore += value;
    Sound.play(
      _likeStreak == 0 ? 'like' : 'like_${min(_likeStreak, 5)}',
      volume: .45,
    );
    if (likes == totalLikes && totalLikes > 0) {
      // Every like in the level: a little party.
      Sound.play('checkpoint');
      world.add(Confetti(position: player.position - Vector2(0, 40)));
      world.add(
        FloatingText(
          position: player.position - Vector2(0, 90),
          text: 'TUTTI I LIKE!',
          fontSize: 16,
          color: const Color(0xFFFF82B4),
          duration: 1.6,
        ),
      );
    }
    world.add(Sparkles(position: like.position.clone()));
    world.add(
      FloatingText(
        position: like.position - Vector2(0, 10),
        text: '+$value',
        fontSize: 8,
        color: const Color(0xFFFF82B4),
        duration: 0.6,
      ),
    );
  }

  void springUsed(int col, int row) {
    springTimes[row * 10000 + col] = elapsed;
  }

  /// The player's head hit a solid tile from below.
  void bumpBlock(int col, int row) {
    final t = level.tileAt(col, row);
    if (t == '!') {
      Sound.play('block');
      Sound.play('special', volume: .4);
      level.setTile(col, row, 'U');
      final kinds = PowerUpKind.values;
      world.add(
        PowerUpItem(
          position: Vector2((col + .5) * kTile, row * kTile - 2),
          kind: kinds[(col * 31 + row * 17 + level.index) % kinds.length],
        ),
      );
      return;
    }
    if (t != '?') return;
    Sound.play('block');
    level.setTile(col, row, 'U');
    world.add(
      Like(
        position: Vector2((col + .5) * kTile, row * kTile - 6),
        popped: true,
      ),
    );
  }

  void collectPowerUp(PowerUpItem item) {
    Sound.play('checkpoint');
    Sound.haptic();
    world.add(Confetti(position: item.position.clone(), count: 24));
    world.add(
      FloatingText(
        position: player.position - Vector2(0, 74),
        text: item.kind.shout,
        fontSize: 14,
        color: const Color(0xFFFFD86A),
        duration: 1.4,
      ),
    );
    player.applyPowerUp(item.kind);
    if (item.kind == PowerUpKind.sunglasses) Achievements.unlock('deal');
    if (item.kind == PowerUpKind.stonks) Achievements.unlock('stonks');
  }

  /// Points multiplier while the Stonks power-up is active.
  int get multiplier => player.power == PowerUpKind.stonks ? 2 : 1;

  void reachCheckpoint(Checkpoint cp) {
    _checkpoint = cp.position.clone();
    player.onCheckpoint();
    Sound.play('checkpoint');
    world.add(Confetti(position: cp.position - Vector2(0, 30), count: 30));
    world.add(
      FloatingText(position: cp.position - Vector2(0, 52), text: 'SALVATO!'),
    );
  }

  void onEnemyKilled(Enemy e) {
    kills++;
    final drip = character.passive == Passive.drip ? 3 : 1;
    enemyScore += e.kind.score * multiplier * drip;
    world.add(
      FloatingText(
        position: e.position - Vector2(0, 34),
        text: '+${e.kind.score * multiplier * drip}',
        fontSize: 9,
        color: const Color(0xFFFFD86A),
        duration: 0.7,
      ),
    );
    if (e.kind.isBoss) {
      _bossAlive = false;
      _openGates();
      shake(0.6);
      camera.viewport.add(ScreenFlash(color: const Color(0x662ECC71)));
      world.add(
        FloatingText(
          position: e.position - Vector2(0, 70),
          text: 'ALGORITMO SCONFITTO!',
          fontSize: 14,
          color: const Color(0xFFFFD54F),
          duration: 2.2,
        ),
      );
    }
  }

  /// When the player gets close to L'Algoritmo: roar, banner, boss music.
  void _checkBossIntro() {
    if (_bossIntroDone || !_bossAlive) return;
    for (final e in enemies) {
      if (e.kind.isBoss && (e.position.x - player.position.x).abs() < 380) {
        _bossIntroDone = true;
        Sound.music('boss');
        Sound.play('boss_roar');
        shake(0.6);
        overlays.add(overlayBoss);
        return;
      }
    }
  }

  void spawnMinion(Vector2 at) {
    if (!_bossAlive) return;
    final kind = _rnd.nextBool() ? EnemyKind.normie : EnemyKind.cringe;
    world.add(Enemy(kind: kind, position: at - Vector2(0, 30)));
  }

  void _openGates() {
    for (var r = 0; r < level.rows; r++) {
      for (var c = 0; c < level.cols; c++) {
        if (level.tileAt(c, r) == 'G') level.setTile(c, r, ' ');
      }
    }
  }

  void fellInPit() {
    if (finished || isOver) return;
    if (character.passive == Passive.respawnCheat) {
      // GTA rules: you just wake up at the hospital (the checkpoint).
      Sound.play('hurt');
      player.respawn(_checkpoint.clone());
      camera.viewfinder.position = _checkpoint + Vector2(20, 12);
      world.add(
        FloatingText(
          position: _checkpoint - Vector2(0, 70),
          text: 'WASTED',
          fontSize: 20,
          color: const Color(0xFFFF4D5E),
          duration: 1.6,
        ),
      );
      return;
    }
    player.hearts--;
    damageTaken = true;
    Sound.play('hurt');
    shake(0.3);
    if (player.hearts <= 0) {
      gameOver();
      return;
    }
    player.respawn(_checkpoint.clone());
    camera.viewfinder.position = _checkpoint + Vector2(20, 12);
  }

  void finish() {
    if (finished) return;
    finished = true;
    input.clear();
    Sound.stopMusic();
    Sound.play('finish');
    Sound.haptic(strong: true);
    world.add(Confetti(position: player.position - Vector2(0, 40), count: 80));
    world.add(
      FloatingText(
        position: player.position - Vector2(0, 80),
        text: 'VIRALE!',
        fontSize: 18,
        color: const Color(0xFFFFD54F),
        duration: 2,
      ),
    );
    _completeIn = 1.4;
  }

  void gameOver() {
    if (isOver) return;
    isOver = true;
    input.clear();
    recordRunStats();
    Sound.stopMusic();
    Sound.play('gameover');
    Sound.haptic(strong: true);
    hudTick.value++;
    overlays.remove(overlayHud);
    // The meme does a sad little hop off the screen before the panel.
    player.die();
    shake(0.3, intensity: 5);
    _gameOverIn = 1.5;
  }

  double? _gameOverIn;

  /// Likes this run adds to the shop wallet (hen hustle, meme of the day).
  int get walletGain =>
      (likes *
              (character.passive == Passive.hustle ? 1.5 : 1) *
              (character.isOfTheDay ? 2 : 1))
          .round();

  /// Saves likes (to the shop wallet) and stomps from this run.
  void recordRunStats() {
    if (!LocalStore.ready || _statsRecorded) return;
    _statsRecorded = true;
    final s = LocalStore.instance;
    s.addToWallet(walletGain);
    s.addStat('likes', likes);
    s.addStat('stomps', kills);
    Achievements.checkStats();
  }

  bool _statsRecorded = false;

  void togglePause() {
    if (isOver || finished) return;
    if (overlays.isActive(overlayPause)) {
      overlays.remove(overlayPause);
      resumeEngine();
      Sound.resumeMusic();
    } else {
      input.clear();
      overlays.add(overlayPause);
      pauseEngine();
      Sound.pauseMusic();
    }
  }

  // ----------------------------------------------------------- camera shake

  /// Screen shake that fades out; [intensity] is the max offset in pixels.
  void shake(double seconds, {double intensity = 4}) {
    if (_shake <= 0 || intensity >= _shakeAmp * (_shake / _shakeDur)) {
      _shake = seconds;
      _shakeDur = seconds;
      _shakeAmp = intensity;
    }
  }

  /// Freezes the action for a few frames to sell an impact.
  void hitStop(double seconds) => _hitStop = max(_hitStop, seconds);

  void _updateShake(double dt) {
    if (_shake > 0) {
      _shake -= dt;
      final a = _shakeAmp * max(0.0, _shake / _shakeDur);
      camera.viewport.position = Vector2(
        (_rnd.nextDouble() * 2 - 1) * a,
        (_rnd.nextDouble() * 2 - 1) * a,
      );
    } else if (!camera.viewport.position.isZero()) {
      camera.viewport.position = Vector2.zero();
    }
  }

  @override
  void onRemove() {
    hudTick.dispose();
    super.onRemove();
  }
}

/// Where the camera looks: a smoothed point that leads the player in the
/// direction they run (so you see what's coming) and dips when falling.
class _CameraTarget extends PositionComponent {
  _CameraTarget(this.player);

  final Player player;
  double _ahead = 20;
  bool _placed = false;

  @override
  void update(double dt) {
    final p = player.position;
    final speed = player.velocity.x;
    final wantAhead = speed.abs() > 40
        ? speed.sign * 70
        : (player.facingRight ? 30.0 : -30.0);
    _ahead += (wantAhead - _ahead) * min(1.0, dt * 2.2);
    final fall = player.velocity.y > 300 ? 36.0 : 0.0;
    final wantX = p.x + _ahead;
    final wantY = p.y + 12 + fall;
    if (!_placed ||
        (position.x - wantX).abs() > 400 ||
        (position.y - wantY).abs() > 300) {
      // First frame or respawn: jump straight there.
      _placed = true;
      position.setValues(wantX, wantY);
      return;
    }
    position.x += (wantX - position.x) * min(1.0, dt * 9);
    // Vertical: a touch lazier going up (no jitter on small hops), quick
    // when falling; far away (big jumps, springs) it catches up fast.
    final gap = (wantY - position.y).abs();
    final ky = (wantY > position.y ? 9.0 : 6.0) + (gap > 90 ? 6 : 0);
    position.y += (wantY - position.y) * min(1.0, dt * ky);
  }
}
