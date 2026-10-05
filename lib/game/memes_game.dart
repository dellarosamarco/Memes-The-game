import 'dart:math' hide Rectangle;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/meme_character.dart';
import 'components/arena.dart';
import 'components/effects.dart';
import 'components/enemy.dart';
import 'components/player.dart';
import 'components/xp_gem.dart';
import 'upgrades.dart';

/// "Memes: the game" — a top-down arena survivor. Pick a meme, survive the
/// endless horde of Normies, Cringe, Haters and Boomers, collect likes,
/// level up, and beat L'Algoritmo.
class MemesGame extends FlameGame with KeyboardEvents {
  MemesGame({required this.character});

  static const overlayHud = 'hud';
  static const overlayLevelUp = 'levelUp';
  static const overlayPause = 'pause';
  static const overlayGameOver = 'gameOver';

  final MemeCharacter character;
  final Vector2 arenaSize = Vector2.all(2600);
  final rnd = Random();

  late final Player player;
  late final JoystickComponent joystick;

  final List<Enemy> enemies = [];
  final List<XpGem> gems = [];

  // Run state.
  double elapsed = 0;
  int kills = 0;
  int killScore = 0;
  int level = 1;
  int xp = 0;
  int pendingLevelUps = 0;
  bool isGameOver = false;
  List<Upgrade> upgradeChoices = const [];

  int get xpToNext => 4 + level * 4 + (level * level) ~/ 3;
  int get score => killScore + elapsed.floor() * 2 + (level - 1) * 50;

  /// Bumped ~10 times a second so Flutter overlays can rebuild.
  final hudTick = ValueNotifier<int>(0);
  double _hudAcc = 0;

  double _spawnAcc = 0;
  double _nextBossAt = 120;
  double _shake = 0;
  final Set<LogicalKeyboardKey> _keys = {};

  @override
  Color backgroundColor() => const Color(0xFF14121F);

  @override
  Future<void> onLoad() async {
    await images.loadAll([character.spritePath]);
    Enemy.warmUp();

    world.add(Arena(size: arenaSize));
    player = Player(character: character, position: arenaSize / 2);
    world.add(player);
    camera.follow(player);
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, arenaSize.x, arenaSize.y),
      considerViewport: true,
    );

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 26,
        paint: Paint()..color = const Color(0xCCFFFFFF),
      ),
      background: CircleComponent(
        radius: 64,
        paint: Paint()..color = const Color(0x33FFFFFF),
      ),
      margin: const EdgeInsets.only(left: 36, bottom: 36),
    );
    camera.viewport.add(joystick);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Show roughly the same amount of world on phones and desktops.
    camera.viewfinder.zoom = (min(size.x, size.y) / 520).clamp(0.6, 1.6);
  }

  @override
  void update(double dt) {
    // Big frame hitches (tab switch) shouldn't teleport everything.
    dt = min(dt, 1 / 20);
    if (!isGameOver) {
      elapsed += dt;
      _readInput();
      _spawn(dt);
    }
    super.update(dt);
    _updateShake(dt);

    _hudAcc += dt;
    if (_hudAcc > 0.1) {
      _hudAcc = 0;
      hudTick.value++;
    }
  }

  void _readInput() {
    final kb = Vector2.zero();
    if (_keys.contains(LogicalKeyboardKey.keyA) ||
        _keys.contains(LogicalKeyboardKey.arrowLeft)) {
      kb.x -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyD) ||
        _keys.contains(LogicalKeyboardKey.arrowRight)) {
      kb.x += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyW) ||
        _keys.contains(LogicalKeyboardKey.arrowUp)) {
      kb.y -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyS) ||
        _keys.contains(LogicalKeyboardKey.arrowDown)) {
      kb.y += 1;
    }
    if (kb.length2 > 0) {
      player.input.setFrom(kb.normalized());
    } else if (joystick.direction != JoystickDirection.idle) {
      player.input.setFrom(joystick.relativeDelta);
    } else {
      player.input.setZero();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keys
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        player.useSpecial();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        togglePause();
      }
    }
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------- spawning

  EnemyKind _pickKind() {
    final r = rnd.nextDouble();
    if (elapsed < 30) return r < .75 ? EnemyKind.normie : EnemyKind.cringe;
    if (elapsed < 70) {
      if (r < .5) return EnemyKind.normie;
      if (r < .8) return EnemyKind.cringe;
      return EnemyKind.hater;
    }
    if (r < .35) return EnemyKind.normie;
    if (r < .6) return EnemyKind.cringe;
    if (r < .85) return EnemyKind.hater;
    return EnemyKind.boomer;
  }

  Vector2 _spawnPoint() {
    final view = size / camera.viewfinder.zoom;
    final dist = view.length / 2 + 60;
    final a = rnd.nextDouble() * pi * 2;
    final p = player.position + Vector2(cos(a), sin(a)) * dist;
    return p..clamp(Vector2.all(20), arenaSize - Vector2.all(20));
  }

  void _spawn(double dt) {
    final interval = max(0.16, 1.0 - elapsed / 150);
    _spawnAcc += dt;
    if (_spawnAcc < interval) return;
    _spawnAcc = 0;
    if (enemies.length > 260) return;
    final hpScale = 1 + elapsed / 75;
    final batch = 1 + elapsed ~/ 40;
    for (var i = 0; i < batch; i++) {
      world.add(
        Enemy(kind: _pickKind(), position: _spawnPoint(), hpScale: hpScale),
      );
    }
    if (elapsed >= _nextBossAt) {
      _nextBossAt += 120;
      world.add(
        Enemy(
          kind: EnemyKind.algorithm,
          position: _spawnPoint(),
          hpScale: hpScale,
        ),
      );
      camera.viewport.add(ScreenFlash(color: const Color(0x662ECC71)));
      world.add(
        FloatingText(
          position: player.position - Vector2(0, 110),
          text: 'ARRIVA L\'ALGORITMO! 🤖',
          fontSize: 28,
          color: const Color(0xFF2ECC71),
          duration: 2.2,
        ),
      );
    }
  }

  // ------------------------------------------------------------- run events

  void onEnemyKilled(Enemy e) {
    kills++;
    killScore += e.kind.xp * 10;
    if (e.kind.isBoss) {
      shake(0.5);
      world.add(
        FloatingText(
          position: e.position.clone(),
          text: 'ALGORITMO SCONFITTO!',
          fontSize: 26,
          color: const Color(0xFFFFD54F),
          duration: 1.8,
        ),
      );
    }
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpToNext) {
      xp -= xpToNext;
      level++;
      pendingLevelUps++;
    }
    if (pendingLevelUps > 0 && !overlays.isActive(overlayLevelUp)) {
      _openLevelUp();
    }
  }

  void _openLevelUp() {
    upgradeChoices = Upgrade.roll(character, rnd);
    pauseEngine();
    overlays.add(overlayLevelUp);
  }

  void chooseUpgrade(Upgrade u) {
    u.apply(player.stats, player.heal);
    pendingLevelUps--;
    overlays.remove(overlayLevelUp);
    world.add(
      FloatingText(
        position: player.position - Vector2(0, 60),
        text: '${u.emoji} ${u.title}!',
        fontSize: 20,
      ),
    );
    if (pendingLevelUps > 0) {
      _openLevelUp();
    } else {
      resumeEngine();
    }
  }

  void togglePause() {
    if (isGameOver || overlays.isActive(overlayLevelUp)) return;
    if (overlays.isActive(overlayPause)) {
      overlays.remove(overlayPause);
      resumeEngine();
    } else {
      overlays.add(overlayPause);
      pauseEngine();
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    hudTick.value++;
    _keys.clear();
    overlays.remove(overlayHud);
    overlays.add(overlayGameOver);
    pauseEngine();
  }

  // ------------------------------------------------------------- camera shake

  void shake(double seconds) => _shake = max(_shake, seconds);

  void _updateShake(double dt) {
    if (_shake > 0) {
      _shake -= dt;
      camera.viewport.position = Vector2(
        (rnd.nextDouble() - .5) * 14,
        (rnd.nextDouble() - .5) * 14,
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
