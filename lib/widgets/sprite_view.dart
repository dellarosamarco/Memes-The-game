import 'package:flutter/material.dart';

import '../models/hats.dart';
import '../models/meme_character.dart';
import '../services/local_store.dart';
import 'pixel_ui.dart';

/// Shows a character's pixel-art animation strip in Flutter UI.
class CharacterSpriteView extends StatefulWidget {
  const CharacterSpriteView({
    super.key,
    required this.character,
    this.scale = 3,
    this.running = false,
    this.showHat = true,
    this.hat,
  });

  final MemeCharacter character;
  final double scale;
  final bool running;

  /// Wears the hat equipped in the shop.
  final bool showHat;

  /// Shows this hat instead of the equipped one (shop preview).
  final Hat? hat;

  @override
  State<CharacterSpriteView> createState() => _CharacterSpriteViewState();
}

class _CharacterSpriteViewState extends State<CharacterSpriteView>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  static const _frame = 60.0;
  static const _frames = 8;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final hat = !widget.showHat
        ? null
        : widget.hat ??
              (LocalStore.ready
                  ? Hat.byId(LocalStore.instance.equippedHat)
                  : null);
    final sprite = SizedBox(
      width: _frame * s,
      height: _frame * s,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final v = _ctrl.value;
            final frame = widget.running
                ? 2 + (v * 8).floor() % 4
                : (v * 2.5).floor() % 2;
            return OverflowBox(
              maxWidth: _frame * _frames * s,
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(-frame * _frame * s, 0),
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/${widget.character.spriteSheet}',
            width: _frame * _frames * s,
            height: _frame * s,
            filterQuality: FilterQuality.none,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
    if (hat == null) return sprite;
    final a = widget.character.hatAnchor;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        sprite,
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            // Follow the sprite's little bob (frames 1, 3, 5 are 1px lower).
            final v = _ctrl.value;
            final frame = widget.running
                ? 2 + (v * 8).floor() % 4
                : (v * 2.5).floor() % 2;
            final bob = frame.isOdd ? 1.0 : 0.0;
            return Positioned(
              left: (30 + a.x - Hat.width / 2) * s,
              top: (58 + a.y - Hat.height + 3 + bob) * s,
              child: child!,
            );
          },
          child: SheetIcon(
            asset: 'assets/images/${Hat.sheet}',
            index: hat.index,
            frames: Hat.all.length,
            size: Hat.width,
            height: Hat.height,
            scale: s,
          ),
        ),
      ],
    );
  }
}
