import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../fighter/fighter.dart';
import '../memes_game.dart';
import '../pixel.dart';

/// Smash-style bubbles at the screen edge for fighters outside the view:
/// a little portrait pointing where they are.
class OffscreenMarkers extends Component with HasGameReference<MemesGame> {
  OffscreenMarkers() : super(priority: 90);

  final Map<Fighter, Strip> _sheets = {};

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final size = game.size;
    for (final f in game.fighters) {
      if (!f.alive) continue;
      final p = f.mid;
      if (view.inflate(-6).contains(p.toOffset())) continue;
      // Screen position of the fighter, clamped inside the margins.
      final sx = (p.x - view.left) / view.width * size.x;
      final sy = (p.y - view.top) / view.height * size.y;
      const m = 34.0;
      final cx = sx.clamp(m, size.x - m);
      // (Kept above the touch controls at the bottom.)
      final cy = sy.clamp(m + 40, size.y * .72);
      final color = f.slot == 0
          ? const Color(0xFFFF4F8E)
          : const Color(0xFF4FA8FF);
      // Pointer toward the fighter.
      final a = atan2(sy - cy, sx - cx);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(a);
      canvas.drawPath(
        Path()
          ..moveTo(30, 0)
          ..lineTo(18, -8)
          ..lineTo(18, 8)
          ..close(),
        Paint()..color = color,
      );
      canvas.restore();
      canvas.drawCircle(Offset(cx, cy), 22, Paint()..color = color);
      canvas.drawCircle(
        Offset(cx, cy),
        19,
        Paint()..color = const Color(0xFFFFF8EE),
      );
      final sheet = _sheets[f] ??= Strip(
        game.images.fromCache(f.character.spriteSheet),
        60,
        60,
      );
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: 19)),
      );
      sheet.draw(canvas, 0, Offset(cx - 21, cy - 23), scale: .7);
      canvas.restore();
    }
  }
}
