import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
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
class FloatingText extends PositionComponent with HasGameReference<FlameGame> {
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
      fontFamily: 'Pixelify',
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
            ..color = const Color(0xFF3A2440),
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
    // Keep long shouts inside the screen (e.g. near the level's left edge).
    final view = game.camera.visibleWorldRect;
    final half = _stroke.width / 2 + 4;
    if (view.width > half * 2) {
      position.x = position.x.clamp(view.left + half, view.right - half);
    }
    final top = view.top + _stroke.height / 2 + 44; // below the HUD bar
    if (position.y < top) position.y = top;
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

/// A soft pixel dust puff (landing, running).
class Dust extends PositionComponent with HasGameReference<FlameGame> {
  Dust({required super.position, this.dx = 0}) : super(priority: 19);

  final double dx;
  double _t = 0;
  static const _d = 0.3;
  ui.Image? _img;

  @override
  Future<void> onLoad() async {
    _img = game.images.fromCache('sprites/dust.png');
  }

  @override
  void update(double dt) {
    _t += dt;
    position.x += dx * dt;
    position.y -= 10 * dt;
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final img = _img;
    if (img == null) return;
    final f = (_t / _d * 3).floor().clamp(0, 2);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(f * 8.0, 0, 8, 8),
      const Rect.fromLTWH(-4, -6, 8, 8),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}

/// Colorful pixel confetti (checkpoints, finish line).
class Confetti extends PositionComponent {
  Confetti({required super.position, this.count = 40, this.splash = false})
    : super(priority: 45);

  final int count;

  /// White droplets instead of colored paper (falling into a pit).
  final bool splash;
  final List<List<double>> _bits = [];
  double _t = 0;
  static const _colors = [
    Color(0xFFFF82B4),
    Color(0xFFFFD86A),
    Color(0xFF8CE6B4),
    Color(0xFF8CC8FF),
    Color(0xFFC8A0FF),
  ];

  @override
  Future<void> onLoad() async {
    final rnd = Random();
    for (var i = 0; i < count; i++) {
      final a = -pi / 2 + (rnd.nextDouble() - .5) * 2.2;
      final v = 120 + rnd.nextDouble() * 160;
      _bits.add([0, 0, cos(a) * v, sin(a) * v, rnd.nextInt(5).toDouble()]);
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    for (final b in _bits) {
      b[2] *= 0.985;
      b[3] += 260 * dt;
      b[0] += b[2] * dt;
      b[1] += b[3] * dt;
    }
    if (_t > 1.6) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final b in _bits) {
      paint.color = splash ? const Color(0xDDFFFFFF) : _colors[b[4].toInt()];
      final flip = ((_t * 10 + b[4]) % 2) < 1;
      canvas.drawRect(
        Rect.fromLTWH(b[0], b[1], flip ? 3 : 2, flip ? 2 : 3),
        paint,
      );
    }
  }
}

/// A little pixel music note that floats up and fades (AirPods on).
class MusicNote extends PositionComponent {
  MusicNote({required super.position}) : super(priority: 40);

  double _t = 0;
  static const _d = 0.9;
  static final _paint = Paint();

  @override
  void update(double dt) {
    _t += dt;
    position
      ..y -= 28 * dt
      ..x += sin(_t * 9) * 12 * dt;
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / _d).clamp(0.0, 1.0);
    void px(double x, double y, double w, double h, int c) => canvas.drawRect(
      Rect.fromLTWH(x, y, w, h),
      _paint..color = Color(c).withValues(alpha: a),
    );
    // Outline, then the yellow eighth note.
    px(-4, 0, 6, 5, 0xFF3A2440);
    px(1, -9, 3, 11, 0xFF3A2440);
    px(1, -10, 7, 4, 0xFF3A2440);
    px(-3, 1, 4, 3, 0xFFFFD86A);
    px(2, -8, 1, 9, 0xFFFFD86A);
    px(2, -9, 5, 2, 0xFFFFD86A);
  }
}

/// The star-shaped flash where a hit lands.
class HitSpark extends PositionComponent {
  HitSpark({required super.position, this.big = false}) : super(priority: 45);

  final bool big;
  double _t = 0;
  static const _d = .18;
  final double _rot = Random().nextDouble() * pi;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = _t / _d;
    final r = (big ? 26.0 : 16.0) * (0.6 + p * .6);
    final paint = Paint()
      ..color = (big ? const Color(0xFFFFE07A) : Colors.white).withValues(
        alpha: 1 - p,
      );
    final ink = Paint()
      ..color = const Color(0xFF3A2440).withValues(alpha: 1 - p);
    canvas.save();
    canvas.rotate(_rot);
    for (final (pp, k) in [(ink, 1.25), (paint, 1.0)]) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final a = i * pi / 5;
        final rr = (i.isEven ? r : r * .42) * k;
        final o = Offset(cos(a) * rr, sin(a) * rr);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      path.close();
      canvas.drawPath(path, pp);
    }
    canvas.restore();
  }
}

/// KO! A colourful blast shooting in from the edge where a fighter flew out.
class KoBlast extends PositionComponent {
  KoBlast({
    required super.position,
    required this.direction,
    required this.color,
  }) : super(priority: 50);

  /// Points back into the arena.
  final Offset direction;
  final Color color;
  double _t = 0;
  static const _d = .9;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = _t / _d;
    final len = 420.0 * min(1.0, p * 3);
    final w = 70 * (1 - p);
    final a = atan2(direction.dy, direction.dx);
    canvas.save();
    canvas.rotate(a);
    final rect = Rect.fromLTWH(0, -w / 2, len, w);
    canvas.drawRect(
      rect,
      Paint()..color = color.withValues(alpha: (1 - p) * .9),
    );
    canvas.drawRect(
      rect.deflate(w * .3),
      Paint()..color = Colors.white.withValues(alpha: (1 - p)),
    );
    canvas.restore();
  }
}
