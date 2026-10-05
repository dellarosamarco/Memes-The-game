import 'package:flutter/material.dart';

import '../../widgets/pixel_ui.dart';
import '../../widgets/sprite_view.dart';
import '../memes_game.dart';

/// Slides a pixel banner in from the top, holds it, slides it out and then
/// removes its overlay.
class _Banner extends StatefulWidget {
  const _Banner({
    required this.game,
    required this.overlay,
    required this.child,
    this.hold = 1.6,
  });

  final MemesGame game;
  final String overlay;
  final Widget child;
  final double hold;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (600 + widget.hold * 1000).round()),
  )..forward().whenComplete(() => widget.game.overlays.remove(widget.overlay));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _ctrl.duration!.inMilliseconds / 1000;
    final inEnd = 0.3 / total;
    final outStart = 1 - 0.3 / total;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final v = _ctrl.value;
          double y;
          if (v < inEnd) {
            y = Curves.easeOutBack.transform(v / inEnd);
          } else if (v > outStart) {
            y = 1 - Curves.easeIn.transform((v - outStart) / (1 - outStart));
          } else {
            y = 1;
          }
          return Align(alignment: Alignment(0, -1.6 + y * 1.25), child: child);
        },
        child: widget.child,
      ),
    );
  }
}

class LevelIntroBanner extends StatelessWidget {
  const LevelIntroBanner({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final l = game.level;
    return _Banner(
      game: game,
      overlay: MemesGame.overlayIntro,
      child: PixelPanel(
        padding: const EdgeInsets.fromLTRB(16, 8, 22, 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CharacterSpriteView(character: game.character, scale: 1),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelText(
                  'Livello ${l.name}',
                  size: 26,
                  color: const Color(0xFFFF82B4),
                ),
                PixelText(l.subtitle, size: 14, color: kPlum, outline: false),
                const SizedBox(height: 2),
                const PixelText(
                  'Pronti? Via!',
                  size: 12,
                  color: Color(0xFF9A8FB0),
                  outline: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BossBanner extends StatelessWidget {
  const BossBanner({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      game: game,
      overlay: MemesGame.overlayBoss,
      hold: 2,
      child: PixelPanel(
        dark: true,
        padding: const EdgeInsets.fromLTRB(16, 10, 22, 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: 144,
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/sprites/enemy_algorithm.png',
                    width: 144,
                    height: 72,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText('Attenzione!', size: 14, color: Color(0xFFFFD86A)),
                PixelText("L'Algoritmo", size: 30, color: Color(0xFF7CFFC4)),
                PixelText(
                  'vuole il tuo engagement',
                  size: 12,
                  color: Color(0xFFE0D4F0),
                  outline: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
