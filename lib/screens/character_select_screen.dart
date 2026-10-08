import 'dart:math';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/fighter/fighter.dart';
import '../models/meme_character.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({
    super.key,
    required this.onChosen,
    this.title = 'Scegli il tuo meme',
  });

  /// What happens once the player picks a meme (opens the next screen).
  final void Function(BuildContext context, MemeCharacter character) onChosen;
  final String title;

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  int _index = 0;
  final _thumbs = ScrollController();

  static const _thumbStride = 60.0;

  @override
  void dispose() {
    _thumbs.dispose();
    super.dispose();
  }

  /// Next/previous meme, keeping its thumbnail in view.
  void _select(int delta) {
    final n = MemeCharacter.all.length;
    setState(() => _index = (_index + delta + n) % n);
    if (!_thumbs.hasClients) return;
    final pos = _thumbs.position;
    final target = (_index * _thumbStride - pos.viewportDimension / 2 + 30)
        .clamp(0.0, pos.maxScrollExtent);
    _thumbs.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const chars = MemeCharacter.all;
    final c = chars[_index];
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _select(-1);
          if (e.logicalKey == LogicalKeyboardKey.arrowRight) _select(1);
          return KeyEventResult.handled;
        },
        child: PixelBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      PixelButton(
                        icon: 'left',
                        color: PixelColor.grey,
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: PixelText(widget.title, size: 24),
                      ),
                      const SizedBox(width: 56),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Arrow(
                                    icon: 'left',
                                    onTap: () => _select(-1),
                                  ),
                                  CharacterSpriteView(
                                    key: ValueKey(c.id),
                                    character: c,
                                    scale: 3.2,
                                    running: true,
                                  ),
                                  _Arrow(
                                    icon: 'right',
                                    onTap: () => _select(1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: PixelPanel(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                            child: _Info(character: c),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: PointerDeviceKind.values.toSet(),
                            ),
                            child: ListView.separated(
                              controller: _thumbs,
                              scrollDirection: Axis.horizontal,
                              itemCount: chars.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, i) => Center(
                                child: MemeThumb(
                                  character: chars[i],
                                  selected: i == _index,
                                  onTap: () => setState(() => _index = i),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PixelButton(
                        icon: 'dice',
                        color: PixelColor.mint,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => _select(
                          1 + Random().nextInt(MemeCharacter.all.length - 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PixelButton(
                        label: 'Scegli',
                        icon: 'play',
                        color: PixelColor.pink,
                        onPressed: () => widget.onChosen(context, c),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PixelButton(
    icon: icon,
    color: PixelColor.grey,
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    onPressed: onTap,
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.character});

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) {
    final c = character;
    const body = TextStyle(
      fontFamily: kPixelFont,
      color: Color(0xFF6B5A78),
      fontSize: 13,
      height: 1.25,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText(
                      c.name,
                      size: 24,
                      color: const Color(0xFFFF82B4),
                      align: TextAlign.left,
                    ),
                    PixelText(
                      c.memeAlias,
                      size: 13,
                      color: kPlum,
                      outline: false,
                      align: TextAlign.left,
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  c.photoAsset,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.lore, style: body),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _Stat('Velocità', Fighter.speedRating(c)),
              _Stat('Salto', Fighter.jumpRating(c)),
              _Stat('Peso', Fighter.weightRating(c)),
            ],
          ),
          const SizedBox(height: 8),
          if (c.isOfTheDay)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: PixelText(
                'Meme del giorno: like doppi nel portafoglio!',
                size: 12,
                color: Color(0xFFFF82B4),
                outline: false,
                align: TextAlign.left,
              ),
            ),
          _Ability(title: c.passiveName, text: c.passiveDescription),
          _Ability(
            title: '${c.specialName} (${c.specialCooldown}s)',
            text: c.specialDescription,
            special: true,
          ),
        ],
      ),
    );
  }
}

class _Ability extends StatelessWidget {
  const _Ability({
    required this.title,
    required this.text,
    this.special = false,
  });

  final String title;
  final String text;
  final bool special;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: PixelIcon(special ? 'bolt' : 'heart', scale: 1.5),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kPlum,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: const TextStyle(
                fontFamily: kPixelFont,
                fontSize: 13,
                color: Color(0xFF6B5A78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small portrait tile, highlighted when [selected].
class MemeThumb extends StatelessWidget {
  const MemeThumb({
    super.key,
    required this.character,
    required this.selected,
    required this.onTap,
    this.size = 54,
  });

  final MemeCharacter character;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? size + 10 : size,
        height: selected ? size + 10 : size,
        padding: const EdgeInsets.all(6),
        decoration: pixelFrame(
          selected
              ? 'assets/images/ui/button_yellow.png'
              : 'assets/images/ui/panel.png',
          px: 2,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                character.portraitAsset,
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
            // Meme of the day: double likes.
            if (character.isOfTheDay)
              const Positioned(
                right: -8,
                top: -8,
                child: PixelIcon('star', scale: 1.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tiny 5-segment stat bar.
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;

  /// 0..1
  final double value;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * 4).round() + 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelText(label, size: 12, color: kPlum, outline: false),
        const SizedBox(width: 5),
        for (var i = 0; i < 5; i++)
          Container(
            width: 9,
            height: 10,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: i < filled
                  ? const Color(0xFFFF82B4)
                  : const Color(0x333A2440),
              border: Border.all(color: kPlum, width: 1.5),
            ),
          ),
      ],
    );
  }
}
