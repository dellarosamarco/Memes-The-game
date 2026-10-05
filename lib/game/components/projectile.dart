import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memes_game.dart';
import 'enemy.dart';

enum ProjectileStyle { hair, laser, knife }

class Projectile extends PositionComponent with HasGameReference<MemesGame> {
  Projectile({
    required super.position,
    required this.velocity,
    required this.damage,
    required this.style,
    this.pierce = 1,
    this.lifetime = 1.2,
    this.hitRadius = 8,
  }) : super(anchor: Anchor.center, priority: 8) {
    angle = atan2(velocity.y, velocity.x);
  }

  final Vector2 velocity;
  final double damage;
  final ProjectileStyle style;
  int pierce;
  double lifetime;
  final double hitRadius;
  final Set<Enemy> _hit = {};
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
      return;
    }
    position.addScaled(velocity, dt);
    for (final e in game.enemies.toList()) {
      if (_hit.contains(e)) continue;
      final r = e.radius + hitRadius;
      if (e.position.distanceToSquared(position) < r * r) {
        _hit.add(e);
        e.hit(damage, knockFrom: position, knockback: 120);
        pierce--;
        if (pierce <= 0) {
          removeFromParent();
          return;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    switch (style) {
      case ProjectileStyle.hair:
        // A wavy brown lock of wig hair.
        final path = Path()..moveTo(-14, 0);
        for (var x = -14.0; x <= 14; x += 2) {
          path.lineTo(x, sin(x * .5 + _t * 25) * 3);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF7B3F00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFC98A4B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      case ProjectileStyle.laser:
        final glow = Paint()
          ..color = const Color(0x88FF1744)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round;
        final core = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        for (final dy in [-5.0, 5.0]) {
          canvas.drawLine(Offset(-22, dy), Offset(22, dy), glow);
          canvas.drawLine(Offset(-22, dy), Offset(22, dy), core);
        }
      case ProjectileStyle.knife:
        canvas.save();
        canvas.rotate(_t * 20);
        canvas.drawRect(
          const Rect.fromLTWH(-12, -2.5, 16, 5),
          Paint()..color = const Color(0xFFCFD8DC),
        );
        canvas.drawRect(
          const Rect.fromLTWH(4, -3, 9, 6),
          Paint()..color = Colors.black,
        );
        canvas.restore();
    }
  }
}
