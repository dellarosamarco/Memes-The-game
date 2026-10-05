import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level.dart';
import '../memes_game.dart';
import '../pixel.dart';

/// Sky gradient + two pixel-art parallax layers, drawn in screen space.
class Backdrop extends Component with HasGameReference<MemesGame> {
  late final ui.Image _far;
  late final ui.Image _clouds;
  double _t = 0;

  static const _skies = {
    LevelTheme.feed: [Color(0xFF7FD3FF), Color(0xFFD6F2FF)],
    LevelTheme.comments: [Color(0xFF2B1B4A), Color(0xFF7A4FB0)],
    LevelTheme.server: [Color(0xFF05070D), Color(0xFF14273A)],
  };

  @override
  Future<void> onLoad() async {
    final theme = game.level.theme.name;
    _far = game.images.fromCache('sprites/bg_${theme}_far.png');
    _clouds = game.images.fromCache('sprites/bg_${theme}_clouds.png');
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final colors = _skies[game.level.theme]!;
    canvas.drawRect(
      Offset.zero & size.toSize(),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.y), colors),
    );
    final zoom = game.camera.viewfinder.zoom;
    final camX = game.camera.viewfinder.position.x;
    _layer(
      canvas,
      _clouds,
      -(camX * 0.15 + _t * 6) * zoom,
      size.y * 0.08,
      zoom,
    );
    _layer(
      canvas,
      _far,
      -camX * 0.35 * zoom,
      size.y - _far.height * zoom * 1.1,
      zoom,
    );
  }

  void _layer(Canvas canvas, ui.Image img, double offset, double y, double z) {
    final w = img.width * z;
    var x = offset % w;
    if (x > 0) x -= w;
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    for (; x < game.size.x; x += w) {
      canvas.drawImageRect(
        img,
        src,
        Rect.fromLTWH(x, y, w + 1, img.height * z),
        pixelPaint,
      );
    }
  }
}
