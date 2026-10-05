import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level.dart';
import '../memes_game.dart';
import '../pixel.dart';

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
      p.takeDamage(fromX: position.x - direction * 10);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImage(_img, const Offset(-11, -6), pixelPaint);
  }
}
