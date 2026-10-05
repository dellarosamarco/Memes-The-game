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
    camera.follow(target, maxSpeed: 900);
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
  void _clampCamera() {
    final vf = camera.viewfinder;
    final half = size / vf.zoom / 2;
    final maxY = level.height + kGroundBelow;
    vf.position = Vector2(
      half.x * 2 >= level.width
          ? level.width / 2
          : vf.position.x.clamp(half.x, level.width - half.x),
      half.y * 2 >= maxY
          ? maxY / 2
          : vf.position.y.clamp(half.y, maxY - half.y),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Show ~11 tiles vertically, whatever the screen.
    camera.viewfinder.zoom = size.y / (kTile * 11);
  }

  @override
  void update(double dt) {
    dt = min(dt, 1 / 30);
    if (!finished && !isOver) elapsed += dt;
    if (input.jumpBuffer > 0) input.jumpBuffer -= dt;
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

  void collectLike(Like like) {
    likes++;
    final value =
        10 * multiplier * (character.passive == Passive.jewels ? 2 : 1);
    likeScore += value;
    Sound.play('like', volume: .45);
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
    enemyScore += e.kind.score * multiplier;
    world.add(
      FloatingText(
        position: e.position - Vector2(0, 34),
        text: '+${e.kind.score * multiplier}',
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
    hudTick.value++;
    overlays.remove(overlayHud);
    overlays.add(overlayGameOver);
    pauseEngine();
  }

  /// Saves likes (to the shop wallet) and stomps from this run.
  void recordRunStats() {
    if (!LocalStore.ready || _statsRecorded) return;
    _statsRecorded = true;
    final s = LocalStore.instance;
    s.addToWallet(likes);
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

  void shake(double seconds) => _shake = max(_shake, seconds);

  void _updateShake(double dt) {
    if (_shake > 0) {
      _shake -= dt;
      camera.viewport.position = Vector2(
        (_rnd.nextDouble() - .5) * 8,
        (_rnd.nextDouble() - .5) * 8,
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

class _CameraTarget extends PositionComponent {
  _CameraTarget(this.player);

  final Player player;

  @override
  void update(double dt) {
    position.setValues(player.position.x + 20, player.position.y + 12);
  }
}
