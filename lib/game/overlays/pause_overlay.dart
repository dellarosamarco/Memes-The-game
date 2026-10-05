import 'package:flutter/material.dart';

import '../../widgets/meme_text.dart';
import '../memes_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final s = game.player.stats;
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MemeText('Pausa', fontSize: 44),
            const SizedBox(height: 8),
            MemeText(
              'Danno ${s.damage.toStringAsFixed(1)} · '
              'Ricarica ${s.attackCooldown.toStringAsFixed(2)}s · '
              'Velocità ${s.speed.round()}',
              fontSize: 13,
              upper: false,
              color: Colors.white70,
            ),
            const SizedBox(height: 28),
            MemeButton(
              label: 'Riprendi',
              icon: Icons.play_arrow,
              onPressed: game.togglePause,
            ),
            const SizedBox(height: 14),
            MemeButton(
              label: 'Esci',
              icon: Icons.exit_to_app,
              color: const Color(0xFF555066),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 24),
            const Text(
              'WASD / frecce per muoverti · SPAZIO per la mossa speciale',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
