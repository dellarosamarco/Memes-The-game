import 'package:flutter/material.dart';

import '../game/arcade.dart';
import '../game/memes_game.dart';
import '../models/meme_character.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import 'game_screen.dart';

/// Arcade: eight CPU fights in a row. Shows the ladder before starting.
class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key, required this.player});

  final MemeCharacter player;

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  Difficulty _difficulty = Difficulty.normal;
  late ArcadeRun _run = _newRun();

  ArcadeRun _newRun() =>
      ArcadeRun(player: widget.player, difficulty: _difficulty);

  void _start() {
    final run = _run;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => GameScreen(config: run.configFor(1), arcade: run),
          ),
        )
        .then((_) {
          // A new ladder for the next attempt.
          if (mounted) setState(() => _run = _newRun());
        });
  }

  @override
  Widget build(BuildContext context) {
    final best = LocalStore.ready
        ? LocalStore.instance.arcadeBest(widget.player.id)
        : 0;
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
                    const Expanded(child: PixelText('Arcade', size: 24)),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 4),
                PixelText(
                  best >= ArcadeRun.rounds
                      ? 'Campione con ${widget.player.name}!'
                      : 'Record con ${widget.player.name}: $best/${ArcadeRun.rounds}',
                  size: 14,
                  color: const Color(0xFFFFE07A),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CharacterSpriteView(character: widget.player, scale: 2.4),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PixelPanel(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PixelText(
                                '8 avversari, sempre più forti',
                                size: 14,
                                color: kPlum,
                                outline: false,
                              ),
                              const SizedBox(height: 8),
                              ArcadeLadder(run: _run, round: 1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final d in Difficulty.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: PixelButton(
                          label: d.label,
                          height: 44,
                          fontSize: 13,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          color: d == _difficulty
                              ? PixelColor.purple
                              : PixelColor.grey,
                          onPressed: () => setState(() {
                            _difficulty = d;
                            _run = _newRun();
                          }),
                        ),
                      ),
                    const SizedBox(width: 14),
                    PixelButton(
                      label: 'Inizia',
                      icon: 'play',
                      width: 180,
                      onPressed: _start,
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

/// The eight opponents of a run; beaten ones are greyed, the next one
/// highlighted, the last one is a surprise until you get there.
class ArcadeLadder extends StatelessWidget {
  const ArcadeLadder({super.key, required this.run, required this.round});

  final ArcadeRun run;

  /// The round about to be played (1-based).
  final int round;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < ArcadeRun.rounds; i++)
          _Rung(
            character: run.opponents[i],
            number: i + 1,
            beaten: i + 1 < round,
            current: i + 1 == round,
            hidden: i == ArcadeRun.rounds - 1 && i + 1 > round,
          ),
      ],
    );
  }
}

class _Rung extends StatelessWidget {
  const _Rung({
    required this.character,
    required this.number,
    required this.beaten,
    required this.current,
    required this.hidden,
  });

  final MemeCharacter character;
  final int number;
  final bool beaten;
  final bool current;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final size = current ? 56.0 : 46.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(5),
          decoration: pixelFrame(
            current
                ? 'assets/images/ui/button_yellow.png'
                : 'assets/images/ui/panel_dark.png',
            px: 2,
          ),
          child: hidden
              ? const Center(
                  child: PixelText('?', size: 22, color: Color(0xFFFF82B4)),
                )
              : Opacity(
                  opacity: beaten ? .35 : 1,
                  child: Image.asset(
                    character.portraitAsset,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
        PixelText(
          beaten ? 'OK' : '$number',
          size: 10,
          color: beaten ? const Color(0xFF7CFFA0) : Colors.white,
        ),
      ],
    );
  }
}
