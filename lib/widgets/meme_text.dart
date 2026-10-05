import 'package:flutter/material.dart';

import 'pixel_ui.dart';

/// Meme caption, now in the cute pixel style.
class MemeText extends StatelessWidget {
  const MemeText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.color = Colors.white,
    this.textAlign = TextAlign.center,
    this.upper = true,
  });

  final String text;
  final double fontSize;
  final Color color;
  final TextAlign textAlign;
  final bool upper;

  @override
  Widget build(BuildContext context) => PixelText(
    upper ? text.toUpperCase() : text,
    size: fontSize,
    color: color,
    align: textAlign,
  );
}
