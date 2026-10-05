import 'package:flutter/material.dart';

import '../../widgets/meme_text.dart';
import '../memes_game.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemeText('Level up! LV ${game.level}', fontSize: 36),
            const SizedBox(height: 4),
            const MemeText(
              'Scegli un potenziamento',
              fontSize: 16,
              color: Color(0xFFFFD54F),
            ),
            const SizedBox(height: 20),
            for (final u in game.upgradeChoices)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: const Color(0xFF2A2440),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: game.character.color, width: 3),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => game.chooseUpgrade(u),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Text(u.emoji, style: const TextStyle(fontSize: 38)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MemeText(
                                    u.title,
                                    fontSize: 20,
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    u.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
