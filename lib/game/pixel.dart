import 'dart:ui';

import 'package:flame/components.dart';

/// Paint for crisp, unfiltered pixel art.
final Paint pixelPaint = Paint()..filterQuality = FilterQuality.none;

/// Horizontal animation strip of equally sized frames.
class Strip {
  Strip(this.image, this.frameWidth, this.frameHeight);

  final Image image;
  final double frameWidth;
  final double frameHeight;

  int get length => (image.width / frameWidth).floor();

  /// Draws [frame] with its top-left at [at]; optionally mirrored.
  void draw(
    Canvas canvas,
    int frame,
    Offset at, {
    bool flip = false,
    Paint? paint,
    double scale = 1,
    double bleed = 0,
  }) {
    final src = Rect.fromLTWH(frame * frameWidth, 0, frameWidth, frameHeight);
    // [bleed] slightly enlarges the destination to hide hairline seams
    // between adjacent tiles at fractional zoom levels.
    final w = frameWidth * scale + bleed;
    final h = frameHeight * scale + bleed;
    if (!flip) {
      canvas.drawImageRect(
        image,
        src,
        Rect.fromLTWH(at.dx, at.dy, w, h),
        paint ?? pixelPaint,
      );
      return;
    }
    canvas.save();
    canvas.translate(at.dx + w, at.dy);
    canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      src,
      Rect.fromLTWH(0, 0, w, h),
      paint ?? pixelPaint,
    );
    canvas.restore();
  }
}

Vector2 v2(double x, double y) => Vector2(x, y);
