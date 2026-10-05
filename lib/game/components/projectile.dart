import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/meme_character.dart';
import '../level.dart';
import '../memes_game.dart';
import '../pixel.dart';
import 'effects.dart';

/// A "RATIO -1" comment thrown by Haters.
class RatioProjectile extends PositionComponent
    with HasGameReference<MemesGame> {
  RatioProjectile({required super.position, required this.direction})
    : super(priority: 25);

  final int direction;
  double _life = 3;
  late final ui.Image _img;

  @override
  Future<void> onLoad() async {
    _img = game.images.fromCache('sprites/ratio.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.x += direction * 170 * dt;
    final c = (position.x / kTile).floor();
    final r = (position.y / kTile).floor();
    if (_life <= 0 || game.level.isSolid(c, r)) {
      removeFromParent();
      return;
    }
    final p = game.player;
    if (position.x > p.left - 8 &&
        position.x < p.right + 8 &&
        position.y > p.top &&
        position.y < p.bottom) {
      if (p.dashing) {
        removeFromParent();
        return;
      }
      if (p.character.passive == Passive.helmet) {
        // Bounces off the pigeon's helmet.
        game.world.add(
          FloatingText(
            position: position - Vector2(0, 10),
            text: 'TOC!',
            fontSize: 9,
            duration: .5,
          ),
        );
        removeFromParent();
        return;
      }
      p.takeDamage(fromX: position.x - direction * 10);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImage(_img, const Offset(-11, -6), pixelPaint);
  }
}

/// The pink monkey's plush toy: flies forward, knocks out the first enemy it
/// hits and boomerangs back.
class PlushProjectile extends PositionComponent
    with HasGameReference<MemesGame> {
  PlushProjectile({required super.position, required this.direction})
    : super(priority: 25);

  final int direction;
  double _t = 0;
  bool _returning = false;

  static final _white = Paint()..color = const Color(0xFFF4F0F8);
  static final _shade = Paint()..color = const Color(0xFFC8BED8);
  static final _ink = Paint()..color = const Color(0xFF3A2440);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.45) _returning = true;
    final p = game.player;
    if (_returning) {
      final to = p.position - Vector2(0, 22) - position;
      if (to.length < 16 || _t > 2.5) {
        removeFromParent();
        return;
      }
      position += to.normalized() * 360 * dt;
    } else {
      position.x += direction * 330 * dt;
      final c = (position.x / kTile).floor();
      final r = (position.y / kTile).floor();
      if (game.level.isSolid(c, r)) _returning = true;
    }
    for (final e in game.enemies.toList()) {
      if (e.dead || e.mid.distanceTo(position) > 18) continue;
      e.hit(heavy: true);
      _returning = true;
      break;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(_t * 14 * direction);
    // A tiny white plush (pixel blob with two dot eyes).
    canvas.drawRect(const Rect.fromLTWH(-5, -6, 10, 12), _white);
    canvas.drawRect(const Rect.fromLTWH(-6, -4, 12, 8), _white);
    canvas.drawRect(const Rect.fromLTWH(-6, 2, 12, 2), _shade);
    canvas.drawRect(const Rect.fromLTWH(-3, -3, 2, 2), _ink);
    canvas.drawRect(const Rect.fromLTWH(1, -3, 2, 2), _ink);
    canvas.restore();
  }
}
