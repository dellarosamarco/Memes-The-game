import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level.dart';
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
      if (_vy > 120) {
        game.collectLike(this);
        removeFromParent();
      }
      return;
    }
    final p = game.player;
    if ((p.position.x - position.x).abs() < p.bodyWidth / 2 + 6 &&
        position.y > p.top - 6 &&
        position.y < p.bottom + 6) {
      game.collectLike(this);
      removeFromParent();
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
    for (var r = 0; r < level.rows; r++) {
      for (var c = c0; c <= c1; c++) {
        final t = level.tileAt(c, r);
        final idx = switch (t) {
          '#' => level.tileAt(c, r - 1) == '#' ? _ground : _groundTop,
          'B' => _brick,
          '=' => _platform,
          '^' => _spikes,
          '?' => _block,
          'U' => _blockUsed,
          'G' => _gate,
          _ => -1,
        };
        if (idx < 0) continue;
        _tiles.draw(canvas, idx, Offset(c * kTile, r * kTile));
      }
    }
  }
}
