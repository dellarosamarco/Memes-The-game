import 'package:flutter/material.dart';

import '../models/meme_character.dart';

/// Shows a character's pixel-art animation strip in Flutter UI.
class CharacterSpriteView extends StatefulWidget {
  const CharacterSpriteView({
    super.key,
    required this.character,
    this.scale = 3,
    this.running = false,
  });

  final MemeCharacter character;
  final double scale;
  final bool running;

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
    return SizedBox(
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
  }
}
