import 'dart:math';

import 'package:flame/components.dart';

import '../level.dart';
import '../memes_game.dart';
import '../physics.dart';

/// Tile physics for Flame components, backed by [stepBox].
///
/// [position] is the bottom-center of the hitbox (the feet).
mixin TileBody on PositionComponent, HasGameReference<MemesGame>
    implements Surface {
  final Vector2 velocity = Vector2.zero();
  double bodyWidth = 20;
  double bodyHeight = 20;
  bool onGround = false;
  bool hitWall = false;

  /// While true, one-way platforms are ignored (dropping through them).
  bool dropThrough = false;

  /// Moving platform / frozen enemy we are standing on, if any.
  Surface? standingOn;

  double gravity = Phys.gravity;
  double maxFall = Phys.maxFall;

  late final Box _box = Box(x: 0, y: 0, w: bodyWidth, h: bodyHeight);

  @override
  double get left => position.x - bodyWidth / 2;
  @override
  double get right => position.x + bodyWidth / 2;
  @override
  double get top => position.y - bodyHeight;
  double get bottom => position.y;

  bool overlaps(TileBody o) =>
      left < o.right && right > o.left && top < o.bottom && bottom > o.top;

  /// Extra one-way surfaces (moving platforms, frozen enemies...).
  Iterable<Surface> get extraPlatforms => const [];

  /// Called when the head bumps a solid tile while moving up.
  void onCeiling(int col, int row) {}

  /// Called when landing on a tile.
  void onLandTile(int col, int row) {}

  void applyGravity(double dt) {
    velocity.y = (velocity.y + gravity * dt).clamp(-2000, maxFall);
  }

  void moveAndCollide(double dt) {
    final b = _box
      ..x = position.x
      ..y = position.y
      ..vx = velocity.x
      ..vy = velocity.y;
    // Fast bodies (strong launches) move in small steps, so they can't
    // skip over a whole tile and end up inside the ground.
    final dist = max(b.vx.abs(), b.vy.abs()) * dt;
    final steps = dist > 10 ? min(8, (dist / 10).ceil()) : 1;
    var wall = false;
    for (var i = 0; i < steps; i++) {
      stepBox(
        game.level,
        b,
        dt / steps,
        extra: extraPlatforms,
        onCeiling: onCeiling,
        ignoreOneWay: dropThrough,
      );
      wall |= b.hitWall;
      if (b.onGround) break;
    }
    position.setValues(b.x, b.y);
    velocity.setValues(b.vx, b.vy);
    onGround = b.onGround;
    hitWall = wall;
    standingOn = b.landSurface;
    if (b.landCol != null) onLandTile(b.landCol!, b.landRow!);
  }

  /// True when the tile right below and ahead of the feet is empty.
  bool ledgeAhead(int dir) {
    final x = dir > 0 ? right + 1 : left - 1;
    final c = (x / kTile).floor();
    final r = ((bottom + 1) / kTile).floor();
    return !game.level.isStandable(c, r);
  }
}
