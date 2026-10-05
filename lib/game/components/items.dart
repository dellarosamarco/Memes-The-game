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

/// Draws the tiles that are on screen, with auto-tiled edges, a bit of
/// random variety and animated liquid at the bottom of the pits.
class LevelMap extends Component with HasGameReference<MemesGame> {
  LevelMap() : super(priority: 1);

  late final Strip _tiles;
  double _t = 0;

  // Tile order in the tileset (see tool/pixel_world.py + pixel_details.py).
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
  static const _topL = 10;
  static const _topR = 11;
  static const _topLR = 12;
  static const _sideL = 13;
  static const _sideR = 14;
  static const _sideLR = 15;
  static const _topV2 = 16;
  static const _topV3 = 17;
  static const _dirtV2 = 18;
  static const _liquid0 = 19;
  static const _liquid1 = 20;
  static const _liquidDeep = 21;
  static const _powerBlock = 22;

  @override
  Future<void> onLoad() async {
    _tiles = Strip(
      game.images.fromCache('sprites/tiles_${game.level.theme.name}.png'),
      kTile,
      kTile,
    );
  }

  @override
  void update(double dt) => _t += dt;

  static int _hash(int c, int r) => ((c * 73856093) ^ (r * 19349663)) & 0xffff;

  bool _isGround(int c, int r) {
    final level = game.level;
    if (c < 0 || c >= level.cols) return true;
    if (r >= level.rows) return level.tileAt(c, level.rows - 1) == '#';
    return level.tileAt(c, r) == '#';
  }

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
    final level = game.level;
    final cam = game.camera.visibleWorldRect;
    final c0 = max(0, (cam.left / kTile).floor() - 1);
    final c1 = min(level.cols - 1, (cam.right / kTile).ceil() + 1);
    final extraRows = (kGroundBelow / kTile).ceil();
    final wave = (_t * 2).floor().isEven ? _liquid0 : _liquid1;
    for (var r = 0; r < level.rows + extraRows; r++) {
      for (var c = c0; c <= c1; c++) {
        int idx;
        if (r >= level.rows) {
          if (_isGround(c, r)) {
            idx = _groundTile(c, r);
          } else {
            // Pit bottom: water, lava, syrup... depending on the world.
            idx = r == level.rows ? wave : _liquidDeep;
          }
        } else {
          idx = switch (level.tileAt(c, r)) {
            '#' => _groundTile(c, r),
            'B' => _brick,
            '=' => _platform,
            '^' => _spikes,
            '?' => _block,
            'U' => _blockUsed,
            'G' => _gate,
            '!' => _powerBlock,
            'S' =>
              game.elapsed - (game.springTimes[r * 10000 + c] ?? -9) < 0.25
                  ? _springUp
                  : _spring,
            _ => -1,
          };
        }
        if (idx < 0) continue;
        final at = Offset(c * kTile, r * kTile);
        _tiles.draw(canvas, idx, at, bleed: 0.6);
        // Deeper dirt gets gradually darker, for a sense of depth.
        if (idx == _ground ||
            idx == _dirtV2 ||
            idx == _sideL ||
            idx == _sideR ||
            idx == _sideLR) {
          var depth = 0;
          while (depth < 4 && _isGround(c, r - depth - 1)) {
            depth++;
          }
          if (depth >= 2) {
            canvas.drawRect(
              Rect.fromLTWH(at.dx, at.dy, kTile + 0.6, kTile + 0.6),
              Paint()..color = Color.fromRGBO(58, 36, 64, (depth - 1) * 0.07),
            );
          }
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
    final busy = <int>{
      for (final s in level.spawns)
        for (var dc = -1; dc <= 1; dc++) s.row * 10000 + s.col + dc,
    };
    for (var c = 1; c < level.cols - 1; c++) {
      for (var r = 1; r < level.rows; r++) {
        final t = level.tileAt(c, r);
        if (t != '#' && t != 'B') continue;
        if (level.tileAt(c, r - 1) != ' ' ||
            busy.contains((r - 1) * 10000 + c)) {
          continue;
        }
        final h = LevelMap._hash(c * 7, r * 3);
        if (h % 100 >= 28) continue;
        _items.add((c * kTile, (r - 1) * kTile, (h ~/ 100) % 8, (h % 17) / 3));
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

enum PowerUpKind {
  sunglasses('DEAL WITH IT', 8),
  stonks('STONKS', 12),
  pizza('GNAM!', 0),
  coffee('CAFFEINA!', 8);

  const PowerUpKind(this.shout, this.seconds);
  final String shout;
  final double seconds;
}

/// A power-up that pops out of a '!' block and floats there, waiting.
class PowerUpItem extends PositionComponent with HasGameReference<MemesGame> {
  PowerUpItem({required super.position, required this.kind})
    : super(priority: 12);

  final PowerUpKind kind;
  late final Strip _strip;
  double _t = 0;
  late final double _restY = position.y - kTile;
  double _vx = 0;
  double _vy = 0;
  bool _taken = false;

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache('sprites/powerups.png'), 16, 16);
  }

  @override
  void update(double dt) {
    _t += dt;
    final level = game.level;
    if (_t < 0.4) {
      // Rise out of the block, then head towards the player.
      position.y = max(_restY, position.y - 70 * dt);
      _vx = (game.player.position.x < position.x ? -1 : 1) * 32;
    } else {
      // Then fall and slide along the ground, bouncing off walls.
      _vy = min(_vy + 600 * dt, 260);
      final nx = position.x + _vx * dt;
      final row = ((position.y - 4) / kTile).floor();
      if (level.isSolid((nx / kTile + (_vx > 0 ? .3 : -.3)).floor(), row)) {
        _vx = -_vx;
      } else {
        position.x = nx;
      }
      final ny = position.y + _vy * dt;
      final c = (position.x / kTile).floor();
      final r = ((ny + 8) / kTile).floor();
      if (_vy > 0 && level.isStandable(c, r)) {
        position.y = r * kTile - 8;
        _vy = 0;
        // Hop down from blocks, but never wander off a ledge into a pit.
        final ahead = ((position.x + (_vx > 0 ? 10 : -10)) / kTile).floor();
        var floor = false;
        for (var rr = r; rr < level.rows && !floor; rr++) {
          floor = level.isStandable(ahead, rr);
        }
        if (!floor) _vx = -_vx;
      } else {
        position.y = ny;
      }
      if (position.y > level.height + 60) removeFromParent();
    }
    final p = game.player;
    if (!_taken &&
        (p.position.x - position.x).abs() < p.bodyWidth / 2 + 8 &&
        position.y > p.top - 8 &&
        position.y < p.bottom + 8) {
      _taken = true;
      game.collectPowerUp(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Glow + gentle bob.
    final bob = sin(_t * 4) * 2;
    canvas.drawCircle(
      Offset(0, bob),
      11 + sin(_t * 6),
      Paint()..color = const Color(0x55FFFFFF),
    );
    _strip.draw(canvas, kind.index, Offset(-8, -8 + bob));
  }
}
