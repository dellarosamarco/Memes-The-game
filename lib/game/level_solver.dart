import 'dart:collection';

import 'level.dart';
import 'physics.dart';

/// Proves a level can be finished by simulating the slowest, weakest
/// character (no double jump, no glide, no specials) with the real physics.
///
/// It explores every place you can stand on, trying walks and a set of
/// jumps (short/long, with/without delayed steering) from each one. Enemies
/// are ignored (they can always be stomped) and boss gates count as open.
class LevelSolver {
  LevelSolver(LevelData source) : level = source.copy() {
    for (var r = 0; r < level.rows; r++) {
      for (var c = 0; c < level.cols; c++) {
        if (level.tileAt(c, r) == 'G') level.setTile(c, r, ' ');
      }
    }
    for (final s in level.spawns) {
      if (s.code == 'F') goalX = (s.col + .5) * kTile - 6;
      if (s.code == 'M') platforms.add(_Span.forMovingPlatform(s));
    }
  }

  static const runSpeed = 140.0;
  static const jumpSpeed = 500.0;
  static const _dt = 1 / 60;
  static const _accelGround = 1500.0;
  static const _accelAir = 1000.0;

  final LevelData level;
  final List<Surface> platforms = [];
  double goalX = double.infinity;

  /// Furthest x reached by the last [solve] (debugging aid).
  double furthestX = 0;

  /// (direction, frames the jump is held, frames before steering).
  /// direction 0 = straight up; hold 0 = walk (no jump).
  static const _actions = [
    (1, 0, 0), (-1, 0, 0), //
    (0, 999, 0),
    (1, 999, 0), (-1, 999, 0),
    (1, 8, 0), (-1, 8, 0),
    (1, 999, 14), (-1, 999, 14),
    (1, 999, 26), (-1, 999, 26),
  ];

  bool solve() {
    final start = level.spawns.firstWhere((s) => s.code == 'P');
    final queue = Queue<(double, double)>()
      ..add(((start.col + .5) * kTile, (start.row + 1) * kTile));
    final seen = <int>{};
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      final key = (x ~/ kTile) * 64 + (y / kTile).round();
      if (!seen.add(key)) continue;
      if (x > furthestX) furthestX = x;
      for (final a in _actions) {
        final runUps = a.$1 != 0 && a.$2 > 0 && _canRunUp(x, y, a.$1)
            ? const [false, true]
            : const [false];
        for (final runUp in runUps) {
          final r = _simulate(x, y, a.$1, a.$2, a.$3, runUp: runUp);
          if (r == null) continue;
          if (r.$1 >= goalX) return true;
          queue.add(r);
        }
      }
    }
    return false;
  }

  /// True when there are two tiles of floor behind (x, y) to take a run-up
  /// before jumping in direction [dir].
  bool _canRunUp(double x, double y, int dir) {
    final c = (x / kTile).floor();
    final r = (y / kTile).round();
    for (var i = 1; i <= 2; i++) {
      final cc = c - dir * i;
      if (!level.isStandable(cc, r) || level.tileAt(cc, r - 1) == '^') {
        return false;
      }
      if (level.isSolid(cc, r - 1) || level.isSolid(cc, r - 2)) return false;
    }
    return true;
  }

  /// Returns where the action lands (x, y), or null if it kills you or
  /// goes nowhere. Returns x = infinity when the goal is reached.
  (double, double)? _simulate(
    double x,
    double y,
    int dir,
    int hold,
    int delay, {
    bool runUp = false,
  }) {
    final b = Box(x: x, y: y, w: Phys.playerWidth, h: Phys.playerHeight)
      ..onGround = true
      ..vx = runUp ? dir * runSpeed : 0;
    final walking = hold == 0;
    if (!walking) b.vy = -jumpSpeed;
    var airborne = !walking;
    for (var f = 0; f < 300; f++) {
      final steer = f >= delay ? dir : 0;
      final accel = b.onGround ? _accelGround : _accelAir;
      final dv = steer * runSpeed - b.vx;
      b.vx += dv.clamp(-accel * _dt, accel * _dt);
      if (!walking && f == hold && b.vy < -Phys.jumpCut) b.vy = -Phys.jumpCut;
      b.vy = (b.vy + Phys.gravity * _dt).clamp(-2000, Phys.maxFall);
      stepBox(level, b, _dt, extra: platforms);
      if (b.x >= goalX) return (double.infinity, b.y);
      if (b.y > level.height + 40 || touchesSpikes(level, b)) return null;
      if (!b.onGround) {
        airborne = true;
        continue;
      }
      if (b.landCol != null && level.tileAt(b.landCol!, b.landRow!) == 'S') {
        b.vy = -Phys.springSpeed;
        airborne = true;
        continue;
      }
      if (walking && !airborne) {
        // Walked one tile along the ground.
        if ((b.x - x).abs() >= kTile) return (b.x, b.y);
        if (b.hitWall) return null;
        continue;
      }
      if (airborne) return (b.x, b.y);
    }
    return null;
  }
}

/// The whole range a moving platform sweeps, as a static surface.
class _Span implements Surface {
  _Span(this.left, this.right, this.top);

  factory _Span.forMovingPlatform(Spawn s) {
    const half = MovingPlatformSpec.width / 2;
    final cx = (s.col + .5) * kTile;
    return _Span(
      cx - half - MovingPlatformSpec.range,
      cx + half + MovingPlatformSpec.range,
      s.row * kTile,
    );
  }

  @override
  final double left;
  @override
  final double right;
  @override
  final double top;
}

/// Shared by the game component and the solver.
class MovingPlatformSpec {
  static const width = kTile * 3;
  static const range = kTile * 3;
  static const period = 5.0;
}
