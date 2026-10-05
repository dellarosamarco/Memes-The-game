import 'package:flutter/material.dart';

import '../game/level.dart';
import '../game/levels.dart';
import '../models/meme_character.dart';
import '../services/local_store.dart';
import '../widgets/meme_text.dart';
import '../widgets/sprite_view.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.character});

  final MemeCharacter character;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const _colors = {
    LevelTheme.feed: [Color(0xFF58C448), Color(0xFF2E7D32)],
    LevelTheme.comments: [Color(0xFFAA6EE6), Color(0xFF4A2C7A)],
    LevelTheme.server: [Color(0xFF3CE6A0), Color(0xFF14273A)],
  };

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        title: const MemeText('Scegli il livello', fontSize: 22),
        centerTitle: true,
        actions: [
          CharacterSpriteView(character: widget.character, scale: 0.8),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (var i = 0; i < kLevels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _LevelCard(
                      index: i,
                      level: kLevels[i],
                      colors: _colors[kLevels[i].theme]!,
                      locked: i >= store.unlockedLevels,
                      stars: store.stars(kLevels[i].id),
                      best: store.bestScore(kLevels[i].id),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              character: widget.character,
                              levelIndex: i,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.index,
    required this.level,
    required this.colors,
    required this.locked,
    required this.stars,
    required this.best,
    required this.onTap,
  });

  final int index;
  final LevelData level;
  final List<Color> colors;
  final bool locked;
  final int stars;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemeText('Livello ${index + 1}', fontSize: 16),
                const SizedBox(height: 4),
                MemeText(level.name, fontSize: 22),
                const SizedBox(height: 4),
                Text(
                  level.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                if (locked)
                  const Icon(Icons.lock, color: Colors.white, size: 40)
                else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFD54F),
                          size: 32,
                          shadows: const [Shadow(blurRadius: 2)],
                        ),
                    ],
                  ),
                  Text(
                    best > 0 ? 'Record: $best' : 'Mai completato',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
