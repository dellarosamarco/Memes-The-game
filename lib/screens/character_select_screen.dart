import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../widgets/meme_text.dart';
import '../widgets/sprite_view.dart';
import 'level_select_screen.dart';

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
    final buttonColor = c.color == const Color(0xFF3A3A3A)
        ? const Color(0xFFFF4FA3)
        : c.color;
    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        title: const MemeText('Scegli il tuo meme', fontSize: 22),
        centerTitle: true,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.5, 0),
            radius: 1.2,
            colors: [c.color.withValues(alpha: 0.45), const Color(0xFF14121F)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > box.maxHeight;
              final preview = _Preview(character: c, compact: !wide);
              final info = _Info(character: c);
              return Column(
                children: [
                  Expanded(
                    child: wide
                        ? Row(
                            children: [
                              Expanded(flex: 5, child: preview),
                              Expanded(flex: 6, child: info),
                            ],
                          )
                        : ListView(children: [preview, info]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: Row(
                      children: [
                        for (var i = 0; i < chars.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Thumb(
                              character: chars[i],
                              selected: i == _index,
                              onTap: () => setState(() => _index = i),
                            ),
                          ),
                        const Spacer(),
                        MemeButton(
                          label: 'Scegli ${c.name.split(' ').first}',
                          icon: Icons.check,
                          color: buttonColor,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LevelSelectScreen(character: c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.character, required this.compact});

  final MemeCharacter character;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CharacterSpriteView(
          key: ValueKey(character.id),
          character: character,
          scale: compact ? 3 : 3.6,
          running: true,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                character.photoAsset,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'meme originale',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.character});

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) {
    final c = character;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemeText(c.name, fontSize: 30, textAlign: TextAlign.left),
          Text(
            c.memeAlias,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(c.lore, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < c.hearts; i++)
                const Icon(Icons.favorite, color: Color(0xFFFF4F6A), size: 20),
              const SizedBox(width: 12),
              Text(
                'Velocità ${c.runSpeed.round()}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Ability(
            icon: '🧬',
            title: c.passiveName,
            text: c.passiveDescription,
          ),
          _Ability(
            icon: '🔥',
            title: '${c.specialName} (${c.specialCooldown}s)',
            text: c.specialDescription,
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
        duration: const Duration(milliseconds: 200),
        width: selected ? 60 : 50,
        height: selected ? 60 : 50,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? character.color : Colors.white12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
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

class _Ability extends StatelessWidget {
  const _Ability({required this.icon, required this.title, required this.text});

  final String icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
