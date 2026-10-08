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
import 'components/stage_render.dart';
import 'cpu.dart';
import 'fighter/fighter.dart';
import 'level.dart';
import 'stages.dart';

enum Difficulty {
  easy('Facile'),
  normal('Normale'),
  hard('Difficile');

  const Difficulty(this.label);
  final String label;
}

/// Everything that defines a match.
class MatchConfig {
  const MatchConfig({
    required this.player,
    required this.cpu,
    required this.stage,
    this.difficulty = Difficulty.normal,
    this.stocks = 3,
    this.arcadeRound,
  });

  final MemeCharacter player;
  final MemeCharacter cpu;
  final int stage;
  final Difficulty difficulty;
  final int stocks;

  /// 1-based round when playing Arcade, null in free fights.
  final int? arcadeRound;

  MatchConfig copyWith({
    MemeCharacter? cpu,
    int? stage,
    Difficulty? difficulty,
    int? arcadeRound,
  }) => MatchConfig(
    player: player,
    cpu: cpu ?? this.cpu,
    stage: stage ?? this.stage,
    difficulty: difficulty ?? this.difficulty,
    stocks: stocks,
    arcadeRound: arcadeRound ?? this.arcadeRound,
  );
}

/// "Memes: the game" — a Smash-style brawl between memes.
class MemesGame extends FlameGame with KeyboardEvents {
  MemesGame({required this.config})
    : stage = Stage.all[config.stage],
      level = Stage.all[config.stage].build(config.stage);

  static const overlayHud = 'hud';
  static const overlayPause = 'pause';
  static const overlayResults = 'results';
  static const overlayCountdown = 'countdown';

  final MatchConfig config;
  final Stage stage;
  final LevelData level;

  late final Fighter player;
  late final Fighter cpu;
  late final CpuBrain brain;
  final List<Fighter> fighters = [];
  final List<MovingPlatform> platforms = [];

  /// Hat equipped in the shop (worn by the player).
  final Hat? hat = LocalStore.ready
      ? Hat.byId(LocalStore.instance.equippedHat)
      : null;

  double elapsed = 0;

  /// Seconds left in the 3-2-1 countdown (fighters can't act meanwhile).
  double countdown = 3.2;
  bool matchOver = false;
  Fighter? winner;
  double _resultsIn = 0;
  double _slowMo = 0;
  int likesEarned = 0;

  /// Called once when the match is decided (true = the player won).
  void Function(bool won)? onMatchEnd;
  final hudTick = ValueNotifier<int>(0);
  double _hudAcc = 0;

  double _shake = 0;
  double _shakeDur = 1;
  double _shakeAmp = 0;
  double _hitStop = 0;
  final _rnd = Random();

  bool get frozenFighters => countdown > 0 || matchOver;
  bool get isPaused => overlays.isActive(overlayPause);

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    final theme = level.theme.name;
    await images.loadAll([
      config.player.spriteSheet,
      config.cpu.spriteSheet,
      ?config.player.afterSpecialSheet,
      ?config.cpu.afterSpecialSheet,
      'sprites/tiles_$theme.png',
      'sprites/moving_$theme.png',
      'sprites/props_$theme.png',
      'sprites/bg_${theme}_far.png',
      'sprites/bg_${theme}_mid.png',
      'sprites/bg_${theme}_clouds.png',
      'sprites/dust.png',
      'sprites/sparkle.png',
      Hat.sheet,
    ]);
    camera.viewfinder.anchor = Anchor.center;
    camera.backdrop.add(Backdrop());
    world.add(LevelMap());
    world.add(Props());
    for (final s in level.spawns.where((s) => s.code == 'M')) {
      world.add(MovingPlatform(spawn: s));
    }

    final top = stage.mainTop * kTile;
    final l = stage.left * kTile, r = (stage.right + 1) * kTile;
    final w = r - l;
    player = Fighter(
      character: config.player,
      slot: 0,
      isCpu: false,
      stocks: config.stocks,
      position: Vector2(l + w * .27, top),
    );
    cpu = Fighter(
      character: config.cpu,
      slot: 1,
      isCpu: true,
      stocks: config.stocks,
      position: Vector2(l + w * .73, top),
    );
    fighters.addAll([player, cpu]);
    world.addAll(fighters);
    brain = CpuBrain(cpu, player, config.difficulty);
    for (final f in fighters) {
      f.respawnAt = Vector2((l + r) / 2, top - kTile * 4);
    }
    camera.viewfinder.position = Vector2((l + r) / 2, top - kTile * 2);
    camera.viewfinder.zoom = _closeZoom;
    overlays.add(overlayCountdown);
    Sound.music(stage.music);
    if (LocalStore.ready) {
      LocalStore.instance.markPlayedWith(config.player.id);
      Achievements.checkStats();
    }
  }

  // ----------------------------------------------------------------- update

  @override
  void update(double dt) {
    dt = min(dt, 1 / 30);
    if (_hitStop > 0) {
      _hitStop -= dt;
      _updateShake(dt);
      return;
    }
    if (_slowMo > 0) {
      _slowMo -= dt;
      dt *= .3;
    }
    elapsed += dt;
    if (countdown > -1) {
      final before = countdown.ceil();
      countdown -= dt;
      if (countdown.ceil() != before && countdown > 0) {
        Sound.play('click', volume: .8);
      }
      if (before > 0 && countdown <= 0) Sound.play('checkpoint');
      // "VIA!" stays on screen for a moment.
      if (countdown <= -.7) overlays.remove(overlayCountdown);
    }
    if (!frozenFighters) brain.think(dt);
    super.update(dt);
    if (isLoaded) {
      _resolveHits();
      _checkBlastZones();
      for (final f in fighters) {
        f.input.endFrame();
      }
      _updateCamera(dt);
    }
    if (matchOver && _resultsIn > 0) {
      _resultsIn -= dt;
      if (_resultsIn <= 0) {
        overlays.remove(overlayHud);
        overlays.add(overlayResults);
      }
    }
    _updateShake(dt);
    _hudAcc += dt;
    if (_hudAcc > .08) {
      _hudAcc = 0;
      hudTick.value++;
    }
  }

  void _resolveHits() {
    for (final a in fighters) {
      final box = a.hitbox;
      if (box == null || !a.alive) continue;
      for (final b in fighters) {
        if (b == a || !b.alive || b.intangible) continue;
        if (box.overlaps(b.hurtbox)) a.tryHit(b);
      }
    }
  }

  Rect get blastZone => Rect.fromLTRB(
    -Stage.blastSide * kTile,
    -Stage.blastTop * kTile,
    (Stage.cols + Stage.blastSide) * kTile,
    (Stage.rows + Stage.blastBottom) * kTile,
  );

  void _checkBlastZones() {
    final zone = blastZone;
    for (final f in fighters) {
      if (!f.alive) continue;
      final p = f.mid;
      if (zone.contains(p.toOffset())) continue;
      _ko(f, p, zone);
    }
  }

  void _ko(Fighter f, Vector2 at, Rect zone) {
    final view = camera.visibleWorldRect;
    final edge = Vector2(
      at.x.clamp(view.left + 10, view.right - 10),
      at.y.clamp(view.top + 10, view.bottom - 10),
    );
    final inward = (Vector2(view.center.dx, view.center.dy) - edge)..normalize();
    world.add(
      KoBlast(
        position: edge,
        direction: Offset(inward.x, inward.y),
        color: f.slot == 0 ? const Color(0xFFFF82B4) : const Color(0xFF7CC8FF),
      ),
    );
    world.add(Confetti(position: edge.clone(), count: 40));
    shake(.5, intensity: 8);
    hitStop(.08);
    Sound.play('boss_roar', volume: .7);
    Sound.haptic(strong: true);
    f.blastOff();
    if (f.stocks <= 0) {
      _endMatch(winner: fighters.firstWhere((o) => o != f));
    }
  }

  void _endMatch({required Fighter winner}) {
    if (matchOver) return;
    matchOver = true;
    this.winner = winner;
    _slowMo = 1.2;
    _resultsIn = 2.2;
    for (final f in fighters) {
      f.input.clear();
    }
    Sound.stopMusic();
    Sound.play(winner == player ? 'finish' : 'gameover');
    _recordResult();
    onMatchEnd?.call(winner == player);
  }

  /// Likes for the shop + stats + trophies.
  void _recordResult() {
    final won = winner == player;
    var likes = won
        ? 40 + player.kos * 10 + switch (config.difficulty) {
            Difficulty.easy => 0,
            Difficulty.normal => 20,
            Difficulty.hard => 50,
          }
        : 10 + player.kos * 5;
    var mult = 1.0;
    if (config.player.passive == Passive.jewels) mult *= 2;
    if (config.player.passive == Passive.hustle) mult *= 1.5;
    if (config.player.isOfTheDay) mult *= 2;
    likes = (likes * mult).round();
    likesEarned = likes;
    if (!LocalStore.ready) return;
    final s = LocalStore.instance;
    s.addToWallet(likes);
    s.addStat('matches', 1);
    s.addStat('kos', player.kos);
    s.addStat('specials', player.specialsUsed);
    s.addStat('damage', player.damageDealt.round());
    if (won) {
      s.addStat('wins', 1);
      if (config.difficulty == Difficulty.hard) s.addStat('hard_wins', 1);
      if (player.falls == 0) Achievements.unlock('perfect');
      if (player.percent >= 150) Achievements.unlock('survivor');
      s.markWonWith(config.player.id);
    }
    if (player.smashKos > 0) Achievements.unlock('smash_ko');
    Achievements.checkStats();
  }

  // ----------------------------------------------------------------- camera

  double get _closeZoom => size.y / (kTile * 9.5);
  double get _wideZoom => size.y / (kTile * 17);

  void _updateCamera(double dt) {
    final pts = [
      for (final f in fighters)
        if (f.alive) f.mid,
    ];
    if (pts.isEmpty) return;
    var minX = pts.map((p) => p.x).reduce(min) - 110;
    var maxX = pts.map((p) => p.x).reduce(max) + 110;
    var minY = pts.map((p) => p.y).reduce(min) - 90;
    var maxY = pts.map((p) => p.y).reduce(max) + 80;
    // Always keep a bit of the main island in view.
    final top = stage.mainTop * kTile;
    maxY = max(maxY, top + kTile * 2);
    // Don't chase fighters deep into the blast zone.
    final zone = blastZone.deflate(kTile * 2);
    minX = max(minX, zone.left);
    maxX = min(maxX, zone.right);
    minY = max(minY, zone.top);
    maxY = min(maxY, zone.bottom);
    final fit = min(size.x / (maxX - minX), size.y / (maxY - minY));
    final zoom = fit.clamp(_wideZoom, _closeZoom);
    final vf = camera.viewfinder;
    final k = min(1.0, dt * 4);
    vf.zoom += (zoom - vf.zoom) * k;
    final target = Vector2((minX + maxX) / 2, (minY + maxY) / 2);
    vf.position = vf.position + (target - vf.position) * min(1.0, dt * 5);
  }

  // ------------------------------------------------------------------ input

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    bool any(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);
    final i = player.input;
    final left = any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA]);
    final right = any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]);
    i.x = (right ? 1.0 : 0) - (left ? 1.0 : 0);
    i.up = any([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW]);
    i.down = any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS]);
    const jumpKeys = [LogicalKeyboardKey.space, LogicalKeyboardKey.keyZ];
    const attackKeys = [LogicalKeyboardKey.keyX, LogicalKeyboardKey.keyJ];
    const specialKeys = [LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyK];
    const shieldKeys = [
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ];
    i.jump = any(jumpKeys);
    i.attack = any(attackKeys);
    i.special = any(specialKeys);
    i.shield = any(shieldKeys);
    if (event is KeyDownEvent) {
      final k = event.logicalKey;
      if (jumpKeys.contains(k)) i.jumpPressed = true;
      if (attackKeys.contains(k)) i.attackPressed = true;
      if (specialKeys.contains(k)) i.specialPressed = true;
      if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.keyP) {
        togglePause();
      }
    }
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------------ pause

  /// Pauses (never resumes): used when the app goes to the background.
  void pauseIfPlaying() {
    if (!isPaused && !matchOver && isLoaded) togglePause();
  }

  void togglePause() {
    if (matchOver) return;
    if (isPaused) {
      overlays.remove(overlayPause);
      resumeEngine();
      Sound.held = false;
      Sound.resumeMusic();
    } else {
      player.input.clear();
      overlays.add(overlayPause);
      pauseEngine();
      Sound.pauseMusic();
      Sound.held = true;
    }
  }

  // ------------------------------------------------------------------ juice

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
    Sound.held = false;
    hudTick.dispose();
    super.onRemove();
  }
}
