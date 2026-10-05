import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Expanding ring used by the "Voglio il Manager!" shockwave and other blasts.
class ShockwaveEffect extends PositionComponent {
  ShockwaveEffect({
    required super.position,
    required this.maxRadius,
    required this.color,
    this.duration = 0.45,
  }) : super(anchor: Anchor.center, priority: 9);

  final double maxRadius;
  final Color color;
  final double duration;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    final r = maxRadius * Curves.easeOut.transform(p);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * (1 - p) + 2
        ..color = color.withValues(alpha: 1 - p),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = color.withValues(alpha: 0.15 * (1 - p)),
    );
  }
}

/// A quick knife slash arc.
class SlashEffect extends PositionComponent {
  SlashEffect({
    required super.position,
    required this.radius,
    required double direction,
  }) : super(anchor: Anchor.center, angle: direction, priority: 9);

  final double radius;
  double _t = 0;
  static const _duration = 0.18;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _duration).clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final sweep = pi * 1.6;
    final start = -sweep / 2 + (p - .5) * .8;
    canvas.drawArc(
      rect,
      start,
      sweep * (0.4 + p * .6),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - p) + 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 1 - p),
    );
    canvas.drawArc(
      rect.deflate(8),
      start,
      sweep * (0.4 + p * .6),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFB0BEC5).withValues(alpha: 1 - p),
    );
  }
}

/// Meme-style caption (white Impact-like text with black outline) that floats
/// up and fades.
class FloatingText extends PositionComponent {
  FloatingText({
    required super.position,
    required this.text,
    this.fontSize = 22,
    this.color = Colors.white,
    this.duration = 1.1,
  }) : super(anchor: Anchor.center, priority: 20);

  final String text;
  final double fontSize;
  final Color color;
  final double duration;
  double _t = 0;
  late final TextPainter _fill;
  late final TextPainter _stroke;

  @override
  Future<void> onLoad() async {
    TextStyle style(Paint? fg) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
      foreground: fg,
      color: fg == null ? color : null,
    );
    _stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: style(
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = fontSize / 6
            ..color = Colors.black,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 420);
    _fill = TextPainter(
      text: TextSpan(text: text, style: style(null)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 420);
  }

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 40 * dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = _t / duration;
    final scale = p < .15 ? 0.6 + p / .15 * .4 : 1.0;
    final alpha = p > .7 ? 1 - (p - .7) / .3 : 1.0;
    canvas.save();
    canvas.scale(scale);
    final off = Offset(-_fill.width / 2, -_fill.height / 2);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0, 1)),
    );
    _stroke.paint(canvas, off);
    _fill.paint(canvas, off);
    canvas.restore();
    canvas.restore();
  }
}

/// Full-screen color flash; add it to the camera viewport.
class ScreenFlash extends PositionComponent with HasGameReference {
  ScreenFlash({required this.color, this.duration = 0.5})
    : super(priority: 100);

  final Color color;
  final double duration;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    canvas.drawRect(
      Offset.zero & game.size.toSize(),
      Paint()..color = color.withValues(alpha: color.a * (1 - p)),
    );
  }
}
