import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../level.dart';
import '../memes_game.dart';
import '../pixel.dart';
import '../theme_colors.dart';

/// Sky gradient, a smiling sun (or moon), three pixel-art parallax layers
/// and ambient particles (petals, snow, embers...), drawn in screen space.
class Backdrop extends Component with HasGameReference<MemesGame> {
  late final ui.Image _far;
  late final ui.Image _mid;
  late final ui.Image _clouds;
  double _t = 0;
  final List<_Particle> _particles = [];

  static const _night = {
    LevelTheme.comments,
    LevelTheme.server,
    LevelTheme.volcano,
  };

  @override
  Future<void> onLoad() async {
    final theme = game.level.theme.name;
    _far = game.images.fromCache('sprites/bg_${theme}_far.png');
    _mid = game.images.fromCache('sprites/bg_${theme}_mid.png');
    _clouds = game.images.fromCache('sprites/bg_${theme}_clouds.png');
    final rnd = Random(game.level.index);
    for (var i = 0; i < 36; i++) {
      _particles.add(
        _Particle(
          rnd.nextDouble(),
          rnd.nextDouble(),
          0.5 + rnd.nextDouble(),
          rnd.nextDouble() * 6.28,
          rnd.nextInt(3),
        ),
      );
    }
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final th = ThemeColors.of(game.level.theme);
    canvas.drawRect(
      Offset.zero & size.toSize(),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.y), [
          th.skyTop,
          th.skyBottom,
        ]),
    );
    final zoom = game.camera.viewfinder.zoom;
    final camX = game.camera.viewfinder.position.x;
    _sun(canvas, size, zoom);
    _layer(canvas, _clouds, -(camX * 0.1 + _t * 5) * zoom, size.y * 0.08, zoom);
    _layer(
      canvas,
      _far,
      -camX * 0.25 * zoom,
      size.y - _far.height * zoom * 1.15,
      zoom,
    );
    _layer(
      canvas,
      _mid,
      -camX * 0.5 * zoom,
      size.y - _mid.height * zoom * 0.95,
      zoom,
    );
    _ambient(canvas, size, zoom, camX);
  }

  /// A round pixel sun/moon with a sleepy smile.
  void _sun(Canvas canvas, Vector2 size, double z) {
    final night = _night.contains(game.level.theme);
    final cx = size.x * 0.82;
    final cy = size.y * 0.2 + sin(_t * .8) * 2 * z;
    final r = 16 * z;
    final body = Paint()
      ..color = night ? const Color(0xFFFFF4C8) : const Color(0xFFFFD86A);
    if (!night) {
      final rays = Paint()..color = const Color(0x55FFE9A0);
      canvas.drawCircle(Offset(cx, cy), r * 1.45 + sin(_t * 2) * z, rays);
    }
    canvas.drawCircle(Offset(cx, cy), r, body);
    final plum = Paint()..color = const Color(0xFF3A2440);
    final px = 2 * z;
    // Closed happy eyes ^ ^ and a smile, in chunky pixels.
    for (final ex in [-6.0, 4.0]) {
      canvas.drawRect(Rect.fromLTWH(cx + ex * z, cy - 3 * z, px, px), plum);
      canvas.drawRect(
        Rect.fromLTWH(cx + (ex + 2) * z, cy - 3 * z, px, px),
        plum,
      );
    }
    canvas.drawRect(Rect.fromLTWH(cx - 2 * z, cy + 3 * z, 4 * z, px), plum);
    final blush = Paint()..color = const Color(0xFFFF96B0);
    canvas.drawRect(Rect.fromLTWH(cx - 11 * z, cy + 1 * z, 4 * z, px), blush);
    canvas.drawRect(Rect.fromLTWH(cx + 7 * z, cy + 1 * z, 4 * z, px), blush);
  }

  void _ambient(Canvas canvas, Vector2 size, double z, double camX) {
    final theme = game.level.theme;
    final paint = Paint();
    for (final p in _particles) {
      final s = 2 * z;
      double x, y;
      Color c;
      final drift = -camX * 0.6 * z;
      switch (theme) {
        case LevelTheme.ice ||
            LevelTheme.candy ||
            LevelTheme.feed ||
            LevelTheme.forest ||
            LevelTheme.server:
          // Falling things.
          y = ((p.y * size.y + _t * 22 * p.speed * z) % (size.y + 20)) - 10;
          x = (p.x * size.x + sin(_t + p.phase) * 10 * z + drift) % size.x;
          c = switch (theme) {
            LevelTheme.ice => const Color(0xEEFFFFFF),
            LevelTheme.candy => const [
              Color(0xFFFF8CC8),
              Color(0xFF8CC8FF),
              Color(0xFFFFE08C),
            ][p.kind],
            LevelTheme.feed => const Color(0xDDFFB4CD),
            LevelTheme.forest => const [
              Color(0xFFF2A65A),
              Color(0xFF9CD27A),
              Color(0xFFE8C26A),
            ][p.kind],
            _ => const Color(0xAA7CFFC4),
          };
        case LevelTheme.volcano || LevelTheme.comments:
          // Rising things.
          y = size.y - ((p.y * size.y + _t * 20 * p.speed * z) % (size.y + 20));
          x = (p.x * size.x + sin(_t * 1.5 + p.phase) * 8 * z + drift) % size.x;
          c = theme == LevelTheme.volcano
              ? const Color(0xFFFFB45A)
              : const Color(0x99FFB4DC);
        default:
          // Twinkling stars / sparkles / dust.
          x = (p.x * size.x + drift * 0.3) % size.x;
          y = p.y * size.y * 0.7;
          final a = (sin(_t * 2 * p.speed + p.phase) + 1) / 2;
          c =
              (theme == LevelTheme.desert
                      ? const Color(0xFFFFF0C8)
                      : const Color(0xFFFFFFFF))
                  .withValues(alpha: a * 0.9);
      }
      paint.color = c;
      if (x < 0) x += size.x;
      if (theme == LevelTheme.comments && p.kind == 0) {
        // Tiny pixel heart.
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
        canvas.drawRect(Rect.fromLTWH(x + s * 1.5, y, s, s), paint);
        canvas.drawRect(Rect.fromLTWH(x + s * .75, y + s * .75, s, s), paint);
      } else if (theme == LevelTheme.clouds || theme == LevelTheme.beach) {
        canvas.drawRect(Rect.fromLTWH(x - s, y, s * 3, s), paint);
        canvas.drawRect(Rect.fromLTWH(x, y - s, s, s * 3), paint);
      } else {
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
      }
    }
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

class _Particle {
  _Particle(this.x, this.y, this.speed, this.phase, this.kind);

  final double x;
  final double y;
  final double speed;
  final double phase;
  final int kind;
}
