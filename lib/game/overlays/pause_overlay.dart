import 'package:flutter/material.dart';

import '../../widgets/pixel_ui.dart';
import '../memes_game.dart';
import 'how_to_play.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final c = game.config.player;
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
                '${c.name} vs ${game.config.cpu.name} · ${game.stage.name}',
                size: 14,
                color: kPlum,
                outline: false,
              ),
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
                    label: 'Comandi',
                    icon: 'gear',
                    color: PixelColor.blue,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: HowToPlay(onClose: () => Navigator.pop(ctx)),
                      ),
                    ),
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
              const SettingsPanel(),
              const SizedBox(height: 10),
              Text(
                '${c.passiveName}: ${c.passiveDescription}\n'
                '${c.specialName}: ${c.specialDescription}',
                textAlign: TextAlign.center,
                style: body,
              ),
              const SizedBox(height: 10),
              const Text(
                'Frecce/WASD muoviti · Z/SPAZIO salta · X/J attacco · '
                'C/K speciale · V/L/SHIFT scudo · ESC pausa\n'
                'Su + speciale: recupero · tieni premuto attacco: smash',
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
