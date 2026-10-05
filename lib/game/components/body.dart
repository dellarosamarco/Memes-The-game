import 'package:flame/components.dart';

import '../level.dart';
import '../memes_game.dart';

/// Axis-aligned tile physics shared by the player and the enemies.
///
/// [position] is the bottom-center of the hitbox (the feet).
mixin TileBody on PositionComponent, HasGameReference<MemesGame> {
  final Vector2 velocity = Vector2.zero();
  double bodyWidth = 20;
  double bodyHeight = 20;
  bool onGround = false;
  bool hitWall = false;

  double gravity = 1400;
  double maxFall = 620;

  double get left => position.x - bodyWidth / 2;
  double get right => position.x + bodyWidth / 2;
  double get top => position.y - bodyHeight;
  double get bottom => position.y;

  bool overlaps(TileBody o) =>
      left < o.right && right > o.left && top < o.bottom && bottom > o.top;

  /// Extra one-way surfaces (e.g. frozen enemies for the player).
  Iterable<TileBody> get extraPlatforms => const [];

  /// Called when the head bumps a solid tile while moving up.
  void onCeiling(int col, int row) {}

  void applyGravity(double dt) {
    velocity.y = (velocity.y + gravity * dt).clamp(-2000, maxFall);
  }

  void moveAndCollide(double dt) {
    final level = game.level;
    hitWall = false;

    // ---- X
    position.x += velocity.x * dt;
    final r0 = (top / kTile).floor();
    final r1 = ((bottom - 0.01) / kTile).floor();
    if (velocity.x > 0) {
      final c = ((right - 0.01) / kTile).floor();
      for (var r = r0; r <= r1; r++) {
        if (level.isSolid(c, r)) {
          position.x = c * kTile - bodyWidth / 2;
          velocity.x = 0;
          hitWall = true;
          break;
        }
      }
    } else if (velocity.x < 0) {
      final c = (left / kTile).floor();
      for (var r = r0; r <= r1; r++) {
        if (level.isSolid(c, r)) {
          position.x = (c + 1) * kTile + bodyWidth / 2;
          velocity.x = 0;
          hitWall = true;
          break;
        }
      }
    }

    // ---- Y
    final prevBottom = bottom;
    position.y += velocity.y * dt;
    onGround = false;
    final c0 = (left / kTile).floor();
    final c1 = ((right - 0.01) / kTile).floor();
    if (velocity.y > 0) {
      final r = ((bottom - 0.01) / kTile).floor();
      final rowTop = r * kTile;
      for (var c = c0; c <= c1; c++) {
        final solid = level.isSolid(c, r);
        final oneWay = level.isOneWay(c, r) && prevBottom <= rowTop + 0.5;
        if (solid || oneWay) {
          position.y = rowTop;
          velocity.y = 0;
          onGround = true;
          break;
        }
      }
      if (!onGround) {
        for (final p in extraPlatforms) {
          if (right > p.left &&
              left < p.right &&
              prevBottom <= p.top + 0.5 &&
              bottom >= p.top) {
            position.y = p.top;
            velocity.y = 0;
            onGround = true;
            break;
          }
        }
      }
    } else if (velocity.y < 0) {
      final r = (top / kTile).floor();
      var bumped = false;
      for (var c = c0; c <= c1; c++) {
        if (level.isSolid(c, r)) {
          bumped = true;
          onCeiling(c, r);
        }
      }
      if (bumped) {
        position.y = (r + 1) * kTile + bodyHeight;
        velocity.y = 0;
      }
    }
  }

  /// True when the tile right below and ahead of the feet is empty.
  bool ledgeAhead(int dir) {
    final x = dir > 0 ? right + 1 : left - 1;
    final c = (x / kTile).floor();
    final r = ((bottom + 1) / kTile).floor();
    return !game.level.isStandable(c, r);
  }
}
