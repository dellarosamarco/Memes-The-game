import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Expanding ring (the "Voglio il Manager!" shout, the cursed smile...).
class ShockwaveEffect extends PositionComponent {
  ShockwaveEffect({
    required super.position,
    required this.maxRadius,
    required this.color,
    this.duration = 0.4,
  }) : super(anchor: Anchor.center, priority: 30);

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
        ..strokeWidth = 6 * (1 - p) + 1
        ..color = color.withValues(alpha: 1 - p),
    );
  }
}

/// Little pixel "poof" when an enemy dies.
class PoofEffect extends PositionComponent {
  PoofEffect({required super.position})
    : super(anchor: Anchor.center, priority: 30);

  double _t = 0;
  static const _d = 0.3;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = _t / _d;
    final paint = Paint()..color = Colors.white.withValues(alpha: 1 - p);
    for (var i = 0; i < 6; i++) {
      final a = i * 1.047;
      final d = 4 + p * 14;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(d * _cos(a), d * _sin(a)),
          width: 4,
          height: 4,
        ),
        paint,
      );
    }
  }

  static double _cos(double a) => Offset.fromDirection(a).dx;
  static double _sin(double a) => Offset.fromDirection(a).dy;
}

/// Meme-style caption: white bold text with a black outline, floats up and
/// fades out.
class FloatingText extends PositionComponent {
  FloatingText({
    required super.position,
    required this.text,
    this.fontSize = 10,
    this.color = Colors.white,
    this.duration = 1.0,
  }) : super(anchor: Anchor.center, priority: 40);

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
      foreground: fg,
      color: fg == null ? color : null,
    );
    _stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: style(
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = fontSize / 4
            ..color = Colors.black,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);
    _fill = TextPainter(
      text: TextSpan(text: text, style: style(null)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);
  }

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 20 * dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = _t / duration;
    final alpha = p > .7 ? 1 - (p - .7) / .3 : 1.0;
    final off = Offset(-_fill.width / 2, -_fill.height / 2);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0, 1)),
    );
    _stroke.paint(canvas, off);
    _fill.paint(canvas, off);
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
