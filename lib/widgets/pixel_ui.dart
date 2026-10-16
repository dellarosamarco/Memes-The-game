import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/about_screen.dart';
import '../services/local_store.dart';
import '../services/sound.dart';
import '../l10n/l10n.dart';

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
      fontFamilyFallback: fontFallback,
      fontSize: size,
      // The bold weight's thick strokes close the small gaps of letters
      // like C, e, 6 at small sizes (C reads O, 6 reads 8): small text is
      // regular.
      fontWeight: bold && size >= 16 ? FontWeight.w700 : FontWeight.w400,
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
              // Thin enough not to fill the letters' openings.
              ..strokeWidth = (size / 7).clamp(1.5, 6)
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
    'music': (10, 9),
    'sound': (12, 8),
    'gear': (12, 12),
    'vibrate': (12, 7),
    'dice': (12, 10),
    'fist': (11, 9),
    'shield': (10, 10),
    'globe': (12, 12),
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
Decoration pixelFrame(String asset, {double px = 3, double alpha = 1}) =>
    _NineSliceDecoration(asset, px, alpha);

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
  const _NineSliceDecoration(this.asset, this.px, this.alpha);

  final String asset;
  final double px;

  /// See-through frames (touch buttons over the stage).
  final double alpha;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NineSlicePainter(asset, px, alpha);

  @override
  bool operator ==(Object other) =>
      other is _NineSliceDecoration &&
      other.asset == asset &&
      other.px == px &&
      other.alpha == alpha;

  @override
  int get hashCode => Object.hash(asset, px, alpha);
}

class _NineSlicePainter extends BoxPainter {
  _NineSlicePainter(this.asset, this.px, this.alpha);

  final String asset;
  final double px;
  final double alpha;

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
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..color = Color.fromRGBO(0, 0, 0, alpha);
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
              Sound.play('click', volume: .4);
              Sound.ensureMusic('menu');
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

/// Cute pastel sky + hills + grass backdrop used by the menus, alive with
/// drifting clouds, a smiling sun, floating hearts and twinkles.
class PixelBackdrop extends StatefulWidget {
  const PixelBackdrop({
    super.key,
    required this.child,
    this.top = const Color(0xFF8CD2FF),
    this.bottom = const Color(0xFFD6F2FF),
    this.theme = 'feed',
    this.ground = true,
    this.night = false,
  });

  final Widget child;
  final Color top;
  final Color bottom;
  final String theme;
  final bool ground;
  final bool night;

  @override
  State<PixelBackdrop> createState() => _PixelBackdropState();
}

class _PixelBackdropState extends State<PixelBackdrop>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const px = 3.0;
    final w = widget;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [w.top, w.bottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SkyPainter(_ctrl, night: w.night)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            height: 100 * px / 1.5,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => _Repeat(
                'assets/images/sprites/bg_${w.theme}_clouds.png',
                1.5,
                offset: _ctrl.value * 480 * 1.5 * 2,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: w.ground ? 24 * px - 6 : 0,
            height: 160 * px / 1.5,
            child: _Repeat('assets/images/sprites/bg_${w.theme}_far.png', 1.5),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: w.ground ? 24 * px - 6 : 0,
            height: 120 * px / 1.5,
            child: _Repeat('assets/images/sprites/bg_${w.theme}_mid.png', 1.5),
          ),
          if (w.ground)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24 * px,
              child: _Repeat('assets/images/ui/tile_grass.png', px),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FloatiesPainter(_ctrl)),
            ),
          ),
          w.child,
        ],
      ),
    );
  }
}

/// The smiling pixel sun (or moon) of the menus.
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.anim, {required this.night}) : super(repaint: anim);

  final Animation<double> anim;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 60;
    const z = 2.5;
    final cx = size.width * 0.86;
    final cy = 70 + sin(t * .8) * 3;
    const r = 16 * z;
    if (!night) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.45 + sin(t * 2) * z,
        Paint()..color = const Color(0x55FFE9A0),
      );
    }
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = night ? const Color(0xFFFFF4C8) : const Color(0xFFFFD86A),
    );
    final plum = Paint()..color = kPlum;
    for (final ex in [-6.0, 4.0]) {
      canvas.drawRect(
        Rect.fromLTWH(cx + ex * z, cy - 3 * z, 2 * z, 2 * z),
        plum,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx + (ex + 2) * z, cy - 3 * z, 2 * z, 2 * z),
        plum,
      );
    }
    canvas.drawRect(Rect.fromLTWH(cx - 2 * z, cy + 3 * z, 4 * z, 2 * z), plum);
    final blush = Paint()..color = const Color(0xFFFF96B0);
    canvas.drawRect(Rect.fromLTWH(cx - 11 * z, cy + z, 4 * z, 2 * z), blush);
    canvas.drawRect(Rect.fromLTWH(cx + 7 * z, cy + z, 4 * z, 2 * z), blush);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

/// Little pixel hearts and twinkles floating up the menus.
class _FloatiesPainter extends CustomPainter {
  _FloatiesPainter(this.anim) : super(repaint: anim);

  final Animation<double> anim;

  static final _seeds = List.generate(
    18,
    (i) => (
      (i * 0.6180339887) % 1.0,
      (i * 0.3819660113 + .2) % 1.0,
      0.6 + (i % 5) * 0.15,
      i % 3,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 60;
    const s = 3.0;
    final paint = Paint();
    for (final (fx, fy, speed, kind) in _seeds) {
      final y =
          size.height -
          ((fy * size.height + t * 18 * speed) % (size.height + 30));
      final x = fx * size.width + sin(t * speed + fx * 6) * 12;
      final fade = (y / size.height).clamp(0.0, 1.0);
      if (kind == 0) {
        paint.color = const Color(0xFFFF82B4).withValues(alpha: .75 * fade);
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
        canvas.drawRect(Rect.fromLTWH(x + s * 2, y, s, s), paint);
        canvas.drawRect(Rect.fromLTWH(x - s * .5, y + s, s * 4, s), paint);
        canvas.drawRect(Rect.fromLTWH(x + s * .5, y + s * 2, s * 2, s), paint);
      } else {
        final a = (sin(t * 3 * speed + fx * 9) + 1) / 2;
        paint.color =
            (kind == 1 ? const Color(0xFFFFF4B4) : const Color(0xFFFFFFFF))
                .withValues(alpha: a * fade);
        canvas.drawRect(Rect.fromLTWH(x - s, y, s * 3, s), paint);
        canvas.drawRect(Rect.fromLTWH(x, y - s, s, s * 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FloatiesPainter old) => false;
}

class _Repeat extends StatelessWidget {
  const _Repeat(this.asset, this.px, {this.offset = 0});

  final String asset;
  final double px;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.bottomLeft,
        maxWidth: double.infinity,
        child: Transform.translate(
          offset: Offset(-(offset % (480 * px)), 0),
          child: SizedBox(
            width: 4000,
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(asset),
                  repeat: ImageRepeat.repeatX,
                  scale: 1 / px,
                  alignment: Alignment.bottomLeft,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text whose letters bob up and down one after the other.
class BouncyText extends StatefulWidget {
  const BouncyText(
    this.text, {
    super.key,
    this.size = 48,
    this.color = Colors.white,
  });

  final String text;
  final double size;
  final Color color;

  @override
  State<BouncyText> createState() => _BouncyTextState();
}

class _BouncyTextState extends State<BouncyText>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.text.split('');
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < letters.length; i++)
            Transform.translate(
              offset: Offset(
                0,
                -max(0.0, sin((_ctrl.value * 2 * pi) - i * 0.6)) *
                    widget.size *
                    0.12,
              ),
              child: PixelText(
                letters[i],
                size: widget.size,
                color: widget.color,
              ),
            ),
        ],
      ),
    );
  }
}

/// Music / sound effects / vibration switches.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key, this.language = true});

  /// Show the language picker too (the pause menu has its own).
  final bool language;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

/// The language picker: shows the language in use, opens the list.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, this.width});

  final double? width;

  static Future<void> pick(BuildContext context) => showDialog<void>(
    context: context,
    builder: (ctx) {
      Future<void> choose(String? code) async {
        if (LocalStore.ready) await LocalStore.instance.setLanguage(code);
        L10n.use(code);
        if (ctx.mounted) Navigator.pop(ctx);
      }

      final saved = LocalStore.ready ? LocalStore.instance.language : null;
      Widget option(String? code, String label) {
        final on = code == saved;
        return PixelButton(
          label: label,
          height: 38,
          width: 168,
          fontSize: 13,
          color: on ? PixelColor.mint : PixelColor.purple,
          onPressed: () => choose(code),
        );
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: PixelPanel(
          width: 560,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelText(
                tr('settings.language', 'Lingua'),
                size: 20,
                color: const Color(0xFFFF82B4),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      option(
                        null,
                        '${tr('settings.languageAuto', 'Automatica')} '
                        '(${L10n.languages[L10n.deviceLanguage()]})',
                      ),
                      for (final e in L10n.languages.entries)
                        option(e.key, e.value),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PixelButton(
                label: tr('common.ok', 'OK'),
                color: PixelColor.pink,
                height: 40,
                fontSize: 14,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: L10n.current,
    builder: (context, code, _) => PixelButton(
      label: L10n.languages[code],
      icon: 'globe',
      color: PixelColor.blue,
      height: 40,
      width: width,
      fontSize: 13,
      onPressed: () => pick(context),
    ),
  );
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    Widget row(
      String icon,
      String label,
      bool on,
      Future<void> Function(bool) set,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              // (Aligned: a tight box would stretch the icon.)
              child: Align(
                alignment: Alignment.centerLeft,
                child: PixelIcon(icon, scale: 2),
              ),
            ),
            SizedBox(
              width: 112,
              child: PixelText(
                label,
                size: 15,
                color: kPlum,
                outline: false,
                align: TextAlign.left,
              ),
            ),
            PixelButton(
              label: on ? tr('common.yes', 'Sì') : tr('common.no', 'No'),
              height: 40,
              width: 76,
              fontSize: 14,
              color: on ? PixelColor.mint : PixelColor.grey,
              onPressed: () async {
                await set(!on);
                setState(() {});
              },
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(
          'music',
          tr('settings.music', 'Musica'),
          store.musicOn,
          Sound.setMusicOn,
        ),
        row(
          'sound',
          tr('settings.sfx', 'Effetti'),
          store.sfxOn,
          store.setSfxOn,
        ),
        row(
          'vibrate',
          tr('settings.haptics', 'Vibrazione'),
          store.hapticsOn,
          store.setHapticsOn,
        ),
        row(
          'fist',
          tr('settings.assist', 'Assistito'),
          store.assistOn,
          store.setAssistOn,
        ),
        if (widget.language)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LanguageButton(width: 216),
          ),
      ],
    );
  }
}

Future<void> showSettings(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog(
    backgroundColor: Colors.transparent,
    child: PixelPanel(
      width: 350,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelText(
            tr('settings.title', 'Impostazioni'),
            size: 22,
            color: Color(0xFFFF82B4),
          ),
          const SizedBox(height: 8),
          const SettingsPanel(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              PixelButton(
                label: tr('settings.info', 'Info'),
                color: PixelColor.grey,
                height: 44,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
              PixelButton(
                label: tr('common.ok', 'OK'),
                color: PixelColor.pink,
                height: 44,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

/// One frame of a horizontal sprite sheet, as a widget.
class SheetIcon extends StatelessWidget {
  const SheetIcon({
    super.key,
    required this.asset,
    required this.index,
    required this.frames,
    required this.size,
    this.height,
    this.scale = 2,
  });

  final String asset;
  final int index;
  final int frames;

  /// Frame width (and height, unless [height] is given), in art pixels.
  final double size;
  final double? height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final w = size * scale;
    final h = (height ?? size) * scale;
    return SizedBox(
      width: w,
      height: h,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: w * frames,
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: Offset(-index * w, 0),
            child: Image.asset(
              asset,
              width: w * frames,
              height: h,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// The likes you have, as a little panel (shop, missions...).
class WalletChip extends StatelessWidget {
  const WalletChip({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    // Follows every change (a match won, a purchase...).
    valueListenable: LocalStore.walletChanged,
    builder: (context, _, _) => PixelPanel(
      px: 1.5,
      padding: const EdgeInsets.fromLTRB(12, 6, 14, 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelIcon('like', scale: 2),
          const SizedBox(width: 6),
          PixelText(
            '${LocalStore.ready ? LocalStore.instance.wallet : 0}',
            size: 16,
            color: kPlum,
            outline: false,
          ),
        ],
      ),
    ),
  );
}

/// A yes/no question in a pixel panel; true when [ok] is pressed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? text,
  required String ok,
  PixelColor okColor = PixelColor.pink,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: PixelPanel(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelText(title, size: 20, color: const Color(0xFFFF82B4)),
            if (text != null) ...[
              const SizedBox(height: 6),
              PixelText(text, size: 14, color: kPlum, outline: false),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                PixelButton(
                  label: tr('common.cancel', 'Annulla'),
                  color: PixelColor.grey,
                  height: 46,
                  fontSize: 15,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                PixelButton(
                  label: ok,
                  color: okColor,
                  height: 46,
                  fontSize: 15,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return r ?? false;
}

/// A short message at the top of the screen that never blocks taps.
void showToast(BuildContext context, String text) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            builder: (_, v, child) => Transform.translate(
              offset: Offset(0, -20 * (1 - v)),
              child: child,
            ),
            child: PixelPanel(
              dark: true,
              px: 1.5,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 11),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: PixelText(text, size: 14),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2400), entry.remove);
}
