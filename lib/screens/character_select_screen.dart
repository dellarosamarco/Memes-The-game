import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import 'world_map_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const chars = MemeCharacter.all;
    final c = chars[_index];
    return Scaffold(
      body: PixelBackdrop(
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
                    const Expanded(
                      child: PixelText('Scegli il tuo meme', size: 24),
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
                            CharacterSpriteView(
                              key: ValueKey(c.id),
                              character: c,
                              scale: 3.2,
                              running: true,
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
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chars.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => Center(
                            child: _Thumb(
                              character: chars[i],
                              selected: i == _index,
                              onTap: () => setState(() => _index = i),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PixelButton(
                      label: 'Scegli ${c.name.split(' ').first}',
                      icon: 'play',
                      color: PixelColor.pink,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorldMapScreen(character: c),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          Row(
            children: [
              for (var i = 0; i < c.hearts; i++)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: PixelIcon('heart', scale: 1.6),
                ),
              const SizedBox(width: 10),
              PixelText(
                'Velocità ${c.runSpeed.round()}',
                size: 13,
                color: kPlum,
                outline: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
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

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final MemeCharacter character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 64 : 54,
        height: selected ? 64 : 54,
        padding: const EdgeInsets.all(6),
        decoration: pixelFrame(
          selected
              ? 'assets/images/ui/button_yellow.png'
              : 'assets/images/ui/panel.png',
          px: 2,
        ),
        child: Image.asset(
          character.portraitAsset,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
