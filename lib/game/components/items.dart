import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level.dart';
import '../level_solver.dart';
import '../physics.dart';
import '../memes_game.dart';
import '../pixel.dart';

/// A "like": the collectible of the game.
class Like extends PositionComponent with HasGameReference<MemesGame> {
  Like({required super.position, this.popped = false}) : super(priority: 10);

  /// A like that just jumped out of a block: flies up and is auto-collected.
  final bool popped;
  late final Strip _strip;
  double _t = Random().nextDouble();
  double _vy = -260;
  bool _collected = false;

  void _collect() {
    if (_collected) return;
    _collected = true;
    game.collectLike(this);
    removeFromParent();
  }

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache('sprites/like.png'), 16, 16);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (popped) {
      position.y += _vy * dt;
      _vy += 900 * dt;
      if (_vy > 120) _collect();
      return;
    }
    final p = game.player;
    if ((p.position.x - position.x).abs() < p.bodyWidth / 2 + 6 &&
        position.y > p.top - 6 &&
        position.y < p.bottom + 6) {
      _collect();
    }
  }

  @override
  void render(Canvas canvas) {
    _strip.draw(
      canvas,
      (_t * 8).floor() % 4,
      Offset(-8, -8 + sin(_t * 4) * 1.5),
    );
  }
}

class Checkpoint extends PositionComponent with HasGameReference<MemesGame> {
  Checkpoint({required super.position}) : super(priority: 5);

  bool active = false;
  late final Strip _strip;

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache('sprites/checkpoint.png'), 24, 40);
  }

  @override
  void update(double dt) {
    if (active) return;
    if ((game.player.position.x - position.x).abs() < 16 &&
        (game.player.position.y - position.y).abs() < 30) {
      active = true;
      game.reachCheckpoint(this);
    }
  }

  @override
  void render(Canvas canvas) {
    _strip.draw(canvas, active ? 1 : 0, const Offset(-4, -40));
  }
}

/// The finish flag: "VIRALE!".
class FinishFlag extends PositionComponent with HasGameReference<MemesGame> {
  FinishFlag({required super.position}) : super(priority: 5);

  late final Strip _strip;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache('sprites/flag.png'), 24, 72);
  }

  @override
  void update(double dt) {
    _t += dt;
    if (!game.finished && game.player.position.x >= position.x - 6) {
      game.finish();
    }
  }

  @override
  void render(Canvas canvas) {
    _strip.draw(canvas, (_t * 3).floor() % 2, const Offset(-4, -72));
  }
}

/// Draws the tiles that are on screen.
class LevelMap extends Component with HasGameReference<MemesGame> {
  LevelMap() : super(priority: 1);

  late final Strip _tiles;

  // Tile order in the tileset (see tool/generate_sprites.py).
  static const _groundTop = 0;
  static const _ground = 1;
  static const _brick = 2;
  static const _platform = 3;
  static const _spikes = 4;
  static const _block = 5;
  static const _blockUsed = 6;
  static const _gate = 7;
  static const _spring = 8;
  static const _springUp = 9;

  @override
  Future<void> onLoad() async {
    _tiles = Strip(
      game.images.fromCache('sprites/tiles_${game.level.theme.name}.png'),
      kTile,
      kTile,
    );
  }

  @override
  void render(Canvas canvas) {
    final level = game.level;
    final cam = game.camera.visibleWorldRect;
    final c0 = max(0, (cam.left / kTile).floor() - 1);
    final c1 = min(level.cols - 1, (cam.right / kTile).ceil() + 1);
    final extraRows = (kGroundBelow / kTile).ceil();
    for (var r = 0; r < level.rows + extraRows; r++) {
      for (var c = c0; c <= c1; c++) {
        final t = r < level.rows
            ? level.tileAt(c, r)
            : level.tileAt(c, level.rows - 1);
        final idx = switch (t) {
          '#' =>
            r >= level.rows || level.tileAt(c, r - 1) == '#'
                ? _ground
                : _groundTop,
          'B' => _brick,
          '=' => _platform,
          '^' => _spikes,
          '?' => _block,
          'U' => _blockUsed,
          'G' => _gate,
          'S' =>
            game.elapsed - (game.springTimes[r * 10000 + c] ?? -9) < 0.25
                ? _springUp
                : _spring,
          _ => -1,
        };
        if (idx < 0) continue;
        _tiles.draw(canvas, idx, Offset(c * kTile, r * kTile));
      }
    }
  }
}

/// A platform that glides left and right over a pit.
class MovingPlatform extends PositionComponent
    with HasGameReference<MemesGame>
    implements Surface {
  MovingPlatform({required Spawn spawn})
    : _centerX = (spawn.col + .5) * kTile,
      _top = spawn.row * kTile,
      super(priority: 3);

  final double _centerX;
  final double _top;
  double _t = 0;
  double _x = 0;

  /// Horizontal movement during the last update (riders follow it).
  double lastDx = 0;
  late final Strip _img;

  @override
  double get left => _x - MovingPlatformSpec.width / 2;
  @override
  double get right => _x + MovingPlatformSpec.width / 2;
  @override
  double get top => _top;

  @override
  Future<void> onLoad() async {
    _img = Strip(
      game.images.fromCache('sprites/moving_${game.level.theme.name}.png'),
      MovingPlatformSpec.width,
      12,
    );
    _x = _centerX;
  }

  @override
  void onMount() {
    super.onMount();
    game.platforms.add(this);
  }

  @override
  void onRemove() {
    game.platforms.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _t += dt;
    final nx =
        _centerX +
        sin(_t * 2 * pi / MovingPlatformSpec.period) * MovingPlatformSpec.range;
    lastDx = nx - _x;
    _x = nx;
  }

  @override
  void render(Canvas canvas) {
    _img.draw(canvas, 0, Offset(left, _top));
  }
}

/// A little burst of sparkles (likes, stomps...).
class Sparkles extends PositionComponent with HasGameReference<MemesGame> {
  Sparkles({required super.position}) : super(priority: 35);

  late final Strip _strip;
  double _t = 0;
  static const _d = 0.35;
  static const _dirs = [
    Offset(-1, -1),
    Offset(1, -1),
    Offset(-1, 1),
    Offset(1, 1),
    Offset(0, -1.4),
  ];

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache('sprites/sparkle.png'), 8, 8);
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = _t / _d;
    final frame = (p * 3).floor().clamp(0, 2);
    for (final d in _dirs) {
      final o = d * (4 + p * 12);
      _strip.draw(canvas, frame, o.translate(-4, -4));
    }
  }
}
