import 'level.dart';

/// Physics constants shared by the game and the level solver.
class Phys {
  static const gravity = 1400.0;
  static const maxFall = 620.0;
  static const springSpeed = 780.0;

  /// Upward speed kept when the jump button is released early.
  static const jumpCut = 220.0;

  static const playerWidth = 24.0;
  static const playerHeight = 44.0;
}

/// Anything you can stand on besides tiles (moving platforms, frozen
/// enemies). One-way: solid only from above.
abstract interface class Surface {
  double get left;
  double get right;
  double get top;
}

/// A moving axis-aligned box; `x, y` is the bottom-center (the feet).
class Box {
  Box({required this.x, required this.y, required this.w, required this.h});

  double x;
  double y;
  final double w;
  final double h;
  double vx = 0;
  double vy = 0;
  bool onGround = false;
  bool hitWall = false;

  /// Tile landed on during the last step (if any).
  int? landCol;
  int? landRow;

  /// Surface landed on during the last step (if any).
  Surface? landSurface;

  double get left => x - w / 2;
  double get right => x + w / 2;
  double get top => y - h;
  double get bottom => y;
}

/// Moves [b] by its velocity for [dt] seconds, resolving collisions with the
/// level tiles (solid + one-way) and the [extra] one-way surfaces.
void stepBox(
  LevelData level,
  Box b,
  double dt, {
  Iterable<Surface> extra = const [],
  void Function(int col, int row)? onCeiling,
  bool ignoreOneWay = false,
}) {
  b.hitWall = false;
  b.landCol = null;
  b.landRow = null;
  b.landSurface = null;

  // ---- X
  b.x += b.vx * dt;
  final r0 = (b.top / kTile).floor();
  final r1 = ((b.bottom - 0.01) / kTile).floor();
  if (b.vx > 0) {
    final c = ((b.right - 0.01) / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      if (level.isSolid(c, r)) {
        b.x = c * kTile - b.w / 2;
        b.vx = 0;
        b.hitWall = true;
        break;
      }
    }
  } else if (b.vx < 0) {
    final c = (b.left / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      if (level.isSolid(c, r)) {
        b.x = (c + 1) * kTile + b.w / 2;
        b.vx = 0;
        b.hitWall = true;
        break;
      }
    }
  }

  // ---- Y
  final prevBottom = b.bottom;
  b.y += b.vy * dt;
  b.onGround = false;
  final c0 = (b.left / kTile).floor();
  final c1 = ((b.right - 0.01) / kTile).floor();
  if (b.vy > 0) {
    final r = ((b.bottom - 0.01) / kTile).floor();
    final rowTop = r * kTile;
    for (var c = c0; c <= c1; c++) {
      final solid = level.isSolid(c, r);
      final oneWay =
          !ignoreOneWay && level.isOneWay(c, r) && prevBottom <= rowTop + 0.5;
      if (solid || oneWay) {
        b.y = rowTop;
        b.vy = 0;
        b.onGround = true;
        b.landCol = c;
        b.landRow = r;
        // Prefer reporting a spring if any foot is on one.
        if (level.tileAt(c, r) == 'S') break;
      }
    }
    if (!b.onGround && !ignoreOneWay) {
      for (final p in extra) {
        if (b.right > p.left &&
            b.left < p.right &&
            prevBottom <= p.top + 0.5 &&
            b.bottom >= p.top) {
          b.y = p.top;
          b.vy = 0;
          b.onGround = true;
          b.landSurface = p;
          break;
        }
      }
    }
  } else if (b.vy < 0) {
    final r = (b.top / kTile).floor();
    var bumped = false;
    for (var c = c0; c <= c1; c++) {
      if (level.isSolid(c, r)) {
        bumped = true;
        onCeiling?.call(c, r);
      }
    }
    if (bumped) {
      b.y = (r + 1) * kTile + b.h;
      b.vy = 0;
    }
  }
}

/// True when a spike tile hurts a box with this footprint.
bool touchesSpikes(LevelData level, Box b) {
  final c0 = (b.left / kTile).floor();
  final c1 = ((b.right - .01) / kTile).floor();
  final r = ((b.bottom - 1) / kTile).floor();
  for (var c = c0; c <= c1; c++) {
    if (level.tileAt(c, r) == '^' && b.bottom > r * kTile + 12) return true;
  }
  return false;
}
