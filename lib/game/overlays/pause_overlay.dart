import 'package:flutter/material.dart';

import '../../widgets/meme_text.dart';
import '../memes_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final c = game.character;
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MemeText('Pausa', fontSize: 40),
            const SizedBox(height: 8),
            Text(
              '${c.passiveName}: ${c.passiveDescription}\n'
              '${c.specialName}: ${c.specialDescription}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            MemeButton(
              label: 'Riprendi',
              icon: Icons.play_arrow,
              onPressed: game.togglePause,
            ),
            const SizedBox(height: 12),
            MemeButton(
              label: 'Esci',
              icon: Icons.exit_to_app,
              color: const Color(0xFF555066),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tastiera: ←/→ o A/D per muoverti · SPAZIO/↑ per saltare · '
              'X per la mossa speciale · ESC pausa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
