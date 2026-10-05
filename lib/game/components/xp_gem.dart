import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memes_game.dart';

/// "Likes" dropped by defeated enemies. Collect them to level up.
class XpGem extends PositionComponent with HasGameReference<MemesGame> {
  XpGem({required super.position, required this.value})
    : super(anchor: Anchor.center, size: Vector2.all(16), priority: 2);

  final int value;
  bool magnetized = false;
  double _t = Random().nextDouble() * 6;

  @override
  void onMount() {
    super.onMount();
    game.gems.add(this);
  }

  @override
  void onRemove() {
    game.gems.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final player = game.player;
    final toPlayer = player.position - position;
    final d = toPlayer.length;
    if (!magnetized && d < player.stats.magnetRadius) magnetized = true;
    if (magnetized) {
      final speed = 520 + max(0, 900 - d);
      position.addScaled(toPlayer.normalized(), min(speed * dt, d));
      if (d < player.radius) {
        game.addXp(value);
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2 + sin(_t * 4) * 2);
    final r = value >= 3 ? 8.0 : 6.0;
    final color = value >= 3
        ? const Color(0xFFFF4FA3)
        : const Color(0xFF4FC3F7);
    // A little heart = a "like".
    final path = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(
        c.dx - r * 1.6,
        c.dy - r * .2,
        c.dx - r * .6,
        c.dy - r * 1.4,
        c.dx,
        c.dy - r * .4,
      )
      ..cubicTo(
        c.dx + r * .6,
        c.dy - r * 1.4,
        c.dx + r * 1.6,
        c.dy - r * .2,
        c.dx,
        c.dy + r,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
  }
}
