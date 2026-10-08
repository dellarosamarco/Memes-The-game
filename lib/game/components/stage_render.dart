import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level.dart';
import '../memes_game.dart';
import '../physics.dart';
import '../pixel.dart';

// Moving platforms: 3 tiles wide, glide ±2.5 tiles every 4 seconds.
const double _platformWidth = kTile * 3;
const double _platformPeriod = 4;
const double _platformRange = kTile * 2.5;

class LevelMap extends Component with HasGameReference<MemesGame> {
  LevelMap() : super(priority: 1);

  late final Strip _tiles;

  /// The whole arena pre-rendered once: it never changes during a fight,
  /// so each frame is a single image draw instead of hundreds of tiles.
  ui.Image? _baked;

  // Tile order in the tileset (see tool/pixel_world.py + pixel_details.py).
  static const _groundTop = 0;
  static const _ground = 1;
  static const _brick = 2;
  static const _platform = 3;
  static const _spikes = 4;
  static const _block = 5;
  static const _blockUsed = 6;
  static const _spring = 8;
  static const _topL = 10;
  static const _topR = 11;
  static const _topLR = 12;
  static const _sideL = 13;
  static const _sideR = 14;
  static const _sideLR = 15;
  static const _topV2 = 16;
  static const _topV3 = 17;
  static const _dirtV2 = 18;
  static const _powerBlock = 22;

  @override
  Future<void> onLoad() async {
    _tiles = Strip(
      game.images.fromCache('sprites/tiles_${game.level.theme.name}.png'),
      kTile,
      kTile,
    );
    final level = game.level;
    final recorder = ui.PictureRecorder();
    _paintTiles(Canvas(recorder));
    final picture = recorder.endRecording();
    _baked = await picture.toImage(
      (level.cols * kTile).ceil(),
      (level.rows * kTile).ceil(),
    );
    picture.dispose();
  }

  @override
  void onRemove() {
    _baked?.dispose();
    super.onRemove();
  }

  static int _hash(int c, int r) => ((c * 73856093) ^ (r * 19349663)) & 0xffff;

  bool _isGround(int c, int r) => game.level.tileAt(c, r) == '#';

  int _groundTile(int c, int r) {
    final open = !_isGround(c, r - 1) || r == 0;
    final l = !_isGround(c - 1, r);
    final rr = !_isGround(c + 1, r);
    final h = _hash(c, r);
    if (open) {
      if (l && rr) return _topLR;
      if (l) return _topL;
      if (rr) return _topR;
      return h % 7 == 0 ? _topV2 : (h % 11 == 0 ? _topV3 : _groundTop);
    }
    if (l && rr) return _sideLR;
    if (l) return _sideL;
    if (rr) return _sideR;
    return h % 31 == 0 ? _dirtV2 : _ground;
  }

  @override
  void render(Canvas canvas) {
    final baked = _baked;
    if (baked != null) canvas.drawImage(baked, Offset.zero, pixelPaint);
  }

  void _paintTiles(Canvas canvas) {
    final level = game.level;
    const c0 = 0;
    final c1 = level.cols - 1;
    final under = Paint()..color = const Color(0xFF3A2440);
    final shade = Paint()..color = const Color(0x333A2440);
    for (var r = 0; r < level.rows; r++) {
      for (var c = c0; c <= c1; c++) {
        final idx = switch (level.tileAt(c, r)) {
          '#' => _groundTile(c, r),
          'B' => _brick,
          '=' => _platform,
          '^' => _spikes,
          '?' => _block,
          'U' => _blockUsed,
          '!' => _powerBlock,
          'S' => _spring,
          _ => -1,
        };
        if (idx < 0) continue;
        final at = Offset(c * kTile, r * kTile);
        _tiles.draw(canvas, idx, at);
        if (level.tileAt(c, r) != '#') continue;
        // Deeper dirt gets gradually darker, for a sense of depth.
        var depth = 0;
        while (depth < 4 && _isGround(c, r - depth - 1)) {
          depth++;
        }
        if (depth >= 2) {
          canvas.drawRect(
            Rect.fromLTWH(at.dx, at.dy, kTile, kTile),
            Paint()..color = Color.fromRGBO(58, 36, 64, (depth - 1) * 0.07),
          );
        }
        // Floating island: outlined underside with a soft shadow band.
        if (!_isGround(c, r + 1)) {
          canvas.drawRect(
            Rect.fromLTWH(at.dx, at.dy + kTile - 6, kTile, 4),
            shade,
          );
          canvas.drawRect(
            Rect.fromLTWH(at.dx, at.dy + kTile - 2, kTile, 2),
            under,
          );
        }
      }
    }
  }
}

/// Cute non-solid decorations (flowers, mushrooms, penguins...) sprinkled
/// on the grass. They sway a little.
class Props extends Component with HasGameReference<MemesGame> {
  Props() : super(priority: 2);

  late final Strip _sheet;
  late final int _kinds;
  final List<(double, double, int, double)> _items = [];
  double _t = 0;

  @override
  Future<void> onLoad() async {
    final level = game.level;
    _sheet = Strip(
      game.images.fromCache('sprites/props_${level.theme.name}.png'),
      kTile,
      kTile,
    );
    _kinds = _sheet.length ~/ 2;
    final busy = <int>{};
    for (var c = 1; c < level.cols - 1; c++) {
      for (var r = 1; r < level.rows; r++) {
        final t = level.tileAt(c, r);
        if (t != '#' && t != 'B') continue;
        if (level.tileAt(c, r - 1) != ' ' ||
            busy.contains((r - 1) * 10000 + c)) {
          continue;
        }
        final h = LevelMap._hash(c * 7, r * 3);
        if (h % 100 >= 34) continue;
        _items.add((
          c * kTile,
          (r - 1) * kTile,
          (h ~/ 100) % _kinds,
          (h % 17) / 3,
        ));
      }
    }
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final cam = game.camera.visibleWorldRect;
    for (final (x, y, idx, phase) in _items) {
      if (x < cam.left - kTile || x > cam.right) continue;
      final frame = ((_t + phase) * 1.5).floor() % 2;
      _sheet.draw(canvas, idx * 2 + frame, Offset(x, y));
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
  double get left => _x - _platformWidth / 2;
  @override
  double get right => _x + _platformWidth / 2;
  @override
  double get top => _top;

  @override
  Future<void> onLoad() async {
    _img = Strip(
      game.images.fromCache('sprites/moving_${game.level.theme.name}.png'),
      _platformWidth,
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
    final nx = _centerX + sin(_t * 2 * pi / _platformPeriod) * _platformRange;
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
