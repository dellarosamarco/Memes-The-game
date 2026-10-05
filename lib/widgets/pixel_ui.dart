import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The cute pixel-art UI kit: font, icons, 9-slice panels and buttons
/// (all drawn by tool/pixel_world.py).
const kPixelFont = 'Pixelify';
const kPlum = Color(0xFF3A2440);
const kCream = Color(0xFFFFF8EC);

/// Text with the pixel font and a plum outline.
class PixelText extends StatelessWidget {
  const PixelText(
    this.text, {
    super.key,
    this.size = 16,
    this.color = Colors.white,
    this.outline = true,
    this.align = TextAlign.center,
    this.bold = true,
    this.maxLines,
  });

  final String text;
  final double size;
  final Color color;
  final bool outline;
  final TextAlign align;
  final bool bold;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: kPixelFont,
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      height: 1.1,
      letterSpacing: size * 0.03,
    );
    if (!outline) {
      return Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        style: style.copyWith(color: color),
      );
    }
    return Stack(
      children: [
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = (size / 5).clamp(2.5, 7)
              ..strokeJoin = StrokeJoin.miter
              ..color = kPlum,
          ),
        ),
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          style: style.copyWith(color: color),
        ),
      ],
    );
  }
}

/// A pixel icon from assets/images/ui/icon_*.png, scaled by whole pixels.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.name, {super.key, this.scale = 2});

  final String name;
  final double scale;

  static const _sizes = {
    'heart': (12, 10),
    'heart_empty': (12, 10),
    'like': (12, 10),
    'star': (12, 11),
    'star_empty': (12, 11),
    'clock': (12, 11),
    'skull': (12, 9),
    'lock': (12, 10),
    'pause': (10, 8),
    'play': (8, 9),
    'left': (10, 9),
    'right': (10, 9),
    'up': (10, 9),
    'home': (12, 9),
    'replay': (12, 10),
    'trophy': (10, 9),
    'edit': (10, 8),
    'bolt': (8, 9),
  };

  @override
  Widget build(BuildContext context) {
    final (w, h) = _sizes[name] ?? (12, 12);
    return Image.asset(
      'assets/images/ui/icon_$name.png',
      width: w * scale,
      height: h * scale,
      filterQuality: FilterQuality.none,
      fit: BoxFit.fill,
    );
  }
}

/// 9-slice decoration from a 24x24 pixel frame, drawn at [px] screen
/// pixels per art pixel. Frames are preloaded by [PixelAssets.preload].
Decoration pixelFrame(String asset, {double px = 3}) =>
    _NineSliceDecoration(asset, px);

/// Preloads the UI frames so they can be painted synchronously.
class PixelAssets {
  static final Map<String, ui.Image> _images = {};

  static Future<void> preload() async {
    final names = [
      'panel', 'panel_dark', //
      for (final c in ['pink', 'purple', 'mint', 'grey', 'yellow', 'blue']) ...[
        'button_$c',
        'button_${c}_down',
      ],
    ];
    for (final n in names) {
      final path = 'assets/images/ui/$n.png';
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[path] = (await codec.getNextFrame()).image;
    }
  }
}

class _NineSliceDecoration extends Decoration {
  const _NineSliceDecoration(this.asset, this.px);

  final String asset;
  final double px;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NineSlicePainter(asset, px);

  @override
  bool operator ==(Object other) =>
      other is _NineSliceDecoration && other.asset == asset && other.px == px;

  @override
  int get hashCode => Object.hash(asset, px);
}

class _NineSlicePainter extends BoxPainter {
  _NineSlicePainter(this.asset, this.px);

  final String asset;
  final double px;

  /// Border of the 24px frames, in art pixels.
  static const _b = 7.0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final img = PixelAssets._images[asset];
    final size = configuration.size;
    if (img == null || size == null) return;
    final w = img.width.toDouble();
    final h = img.height.toDouble();
    final b = (_b * px).clamp(0.0, size.shortestSide / 2).floorToDouble();
    final paint = Paint()..filterQuality = FilterQuality.none;
    final xs = [0.0, _b, w - _b, w];
    final ys = [0.0, _b, h - _b, h];
    final dx = [0.0, b, size.width - b, size.width];
    final dy = [0.0, b, size.height - b, size.height];
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        canvas.drawImageRect(
          img,
          Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
          Rect.fromLTRB(
            offset.dx + dx[i],
            offset.dy + dy[j],
            offset.dx + dx[i + 1],
            offset.dy + dy[j + 1],
          ),
          paint,
        );
      }
    }
  }
}

class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.dark = false,
    this.padding = const EdgeInsets.all(18),
    this.width,
    this.px = 3,
  });

  final Widget child;
  final bool dark;
  final EdgeInsets padding;
  final double? width;

  /// Screen pixels per art pixel; use 2 for small panels (min height 28).
  final double px;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: pixelFrame(
        dark ? 'assets/images/ui/panel_dark.png' : 'assets/images/ui/panel.png',
      ),
      child: child,
    );
  }
}

enum PixelColor { pink, purple, mint, grey, yellow, blue }

/// Chunky pixel button that visibly "presses" down.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.color = PixelColor.pink,
    this.fontSize = 18,
    this.width,
    this.height = 54,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  final String? label;
  final String? icon;
  final VoidCallback? onPressed;
  final PixelColor color;
  final double fontSize;
  final double? width;
  final double height;
  final EdgeInsets padding;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : PixelColor.grey;
    final asset =
        'assets/images/ui/button_${color.name}${_down ? '_down' : ''}.png';
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed!();
            }
          : null,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding.copyWith(
          top: _down ? 6 : 0,
          bottom: _down ? 0 : 6,
        ),
        decoration: pixelFrame(asset),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) PixelIcon(widget.icon!, scale: 2),
            if (widget.icon != null && widget.label != null)
              const SizedBox(width: 10),
            if (widget.label != null)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PixelText(widget.label!, size: widget.fontSize),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Row of 3 pixel stars.
class PixelStars extends StatelessWidget {
  const PixelStars(this.count, {super.key, this.scale = 2});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale),
            child: PixelIcon(i < count ? 'star' : 'star_empty', scale: scale),
          ),
      ],
    );
  }
}

/// Cute pastel sky + hills + grass backdrop used by the menus.
class PixelBackdrop extends StatelessWidget {
  const PixelBackdrop({
    super.key,
    required this.child,
    this.top = const Color(0xFF8CD2FF),
    this.bottom = const Color(0xFFD6F2FF),
    this.theme = 'feed',
    this.ground = true,
  });

  final Widget child;
  final Color top;
  final Color bottom;
  final String theme;
  final bool ground;

  @override
  Widget build(BuildContext context) {
    const px = 3.0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            height: 100 * px / 1.5,
            child: _Repeat('assets/images/sprites/bg_${theme}_clouds.png', 1.5),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: ground ? 24 * px - 6 : 0,
            height: 160 * px / 1.5,
            child: _Repeat('assets/images/sprites/bg_${theme}_far.png', 1.5),
          ),
          if (ground)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24 * px,
              child: _Repeat('assets/images/ui/tile_grass.png', px),
            ),
          child,
        ],
      ),
    );
  }
}

class _Repeat extends StatelessWidget {
  const _Repeat(this.asset, this.px);

  final String asset;
  final double px;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(asset),
          repeat: ImageRepeat.repeatX,
          scale: 1 / px,
          alignment: Alignment.bottomLeft,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}
