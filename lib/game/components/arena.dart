import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The arena floor: a checkered "comment section" with a few scattered
/// classic meme captions painted on the ground.
class Arena extends PositionComponent {
  Arena({required Vector2 size}) : super(size: size, priority: 0);

  static const _tile = 130.0;
  static const _captions = [
    'MUCH WOW',
    'STONKS',
    'F',
    'NO U',
    'OK BOOMER',
    'BRUH',
    'SUS',
    'GG EZ',
    'LOL',
    'IT\'S OVER 9000',
  ];

  late final ui.Picture _picture;
  final _a = Paint()..color = const Color(0xFF1E1A2E);
  final _b = Paint()..color = const Color(0xFF231E36);
  final _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 18
    ..color = const Color(0xFFFF4FA3);

  @override
  Future<void> onLoad() async {
    // The floor never changes: record it once, replay it every frame.
    final recorder = ui.PictureRecorder();
    _paint(Canvas(recorder));
    _picture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) => canvas.drawPicture(_picture);

  void _paint(Canvas canvas) {
    final rnd = Random(42);
    final cols = (size.x / _tile).ceil();
    final rows = (size.y / _tile).ceil();
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        canvas.drawRect(
          Rect.fromLTWH(x * _tile, y * _tile, _tile, _tile),
          (x + y).isEven ? _a : _b,
        );
      }
    }
    for (var i = 0; i < 40; i++) {
      final text = _captions[rnd.nextInt(_captions.length)];
      canvas.save();
      canvas.translate(rnd.nextDouble() * size.x, rnd.nextDouble() * size.y);
      canvas.rotate((rnd.nextDouble() - .5) * .8);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Color(0x14FFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawRect(Offset.zero & size.toSize(), _border);
  }
}
