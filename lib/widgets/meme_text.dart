import 'package:flutter/material.dart';

/// Classic meme caption: heavy white uppercase text with a black outline.
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
  Widget build(BuildContext context) {
    final t = upper ? text.toUpperCase() : text;
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: fontSize * 0.04,
      height: 1.05,
    );
    return Stack(
      children: [
        Text(
          t,
          textAlign: textAlign,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = (fontSize / 7).clamp(2, 8)
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.black,
          ),
        ),
        Text(
          t,
          textAlign: textAlign,
          style: base.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Chunky arcade button used across menus.
class MemeButton extends StatelessWidget {
  const MemeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFFFF4FA3),
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.black, width: 3),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: MemeText(label, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
