import 'package:flutter/material.dart';

import '../../widgets/pixel_ui.dart';
import '../memes_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final c = game.character;
    const body = TextStyle(
      fontFamily: kPixelFont,
      fontSize: 13,
      color: Color(0xFF6B5A78),
    );
    return Container(
      color: const Color(0x993A2440),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PixelPanel(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelText('Pausa', size: 34, color: Color(0xFFFF82B4)),
              PixelText(
                'Livello ${game.level.name} · ${game.level.subtitle}',
                size: 14,
                color: kPlum,
                outline: false,
              ),
              const SizedBox(height: 10),
              Text(
                '${c.passiveName}: ${c.passiveDescription}\n'
                '${c.specialName}: ${c.specialDescription}',
                textAlign: TextAlign.center,
                style: body,
              ),
              const SizedBox(height: 10),
              const SettingsPanel(),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  PixelButton(
                    label: 'Riprendi',
                    icon: 'play',
                    color: PixelColor.mint,
                    onPressed: game.togglePause,
                  ),
                  PixelButton(
                    label: 'Esci',
                    icon: 'home',
                    color: PixelColor.grey,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '←/→ muoviti · SPAZIO salta · X speciale · ESC pausa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kPixelFont,
                  fontSize: 11,
                  color: Color(0xFF9A8FB0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
