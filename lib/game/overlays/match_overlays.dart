import 'package:flutter/material.dart';

import '../../models/meme_character.dart';
import '../../services/achievements.dart';
import '../../services/local_store.dart';
import '../../services/sound.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprite_view.dart';
import '../fighter/fighter.dart';
import '../memes_game.dart';

/// "3, 2, 1, VIA!" before the fight (with the arena name first).
class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: game.hudTick,
        builder: (context, _, _) {
          final c = game.countdown;
          final round = game.config.arcadeRound;
          final String text;
          final double size;
          if (c > 3) {
            text = round != null ? 'Round $round' : game.stage.name;
            size = 30;
          } else if (c > 0) {
            text = '${c.ceil()}';
            size = 80;
          } else {
            text = 'VIA!';
            size = 80;
          }
          return Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(text),
              tween: Tween(begin: 1.8, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, s, child) =>
                  Transform.scale(scale: s, child: child),
              child: PixelText(
                text,
                size: size,
                color: c > 0
                    ? const Color(0xFFFFE07A)
                    : const Color(0xFFFF82B4),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Who won, the numbers of the fight, likes earned and what's next.
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay({
    super.key,
    required this.game,
    required this.onRematch,
    required this.onBack,
    required this.onMenu,
    this.onNext,
    this.arcadeChampion = false,
  });

  final MemesGame game;
  final VoidCallback onRematch;

  /// Back to the previous screen (change opponent / meme).
  final VoidCallback onBack;
  final VoidCallback onMenu;

  /// Arcade: the next round, when the player won and there is one.
  final VoidCallback? onNext;

  /// Arcade: the whole ladder is beaten.
  final bool arcadeChampion;

  @override
  Widget build(BuildContext context) {
    final won = game.winner == game.player;
    final round = game.config.arcadeRound;
    final String title;
    if (arcadeChampion) {
      title = 'CAMPIONE!';
    } else if (won) {
      title = 'VITTORIA!';
    } else {
      title = 'SCONFITTA';
    }
    final winner = game.winner?.character ?? game.player.character;
    return Container(
      color: const Color(0xAA3A2440),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BouncyText(
                  title,
                  size: 40,
                  color: won ? const Color(0xFFFFE07A) : const Color(0xFF9AB4FF),
                ),
                const SizedBox(height: 4),
                _Winner(character: winner),
                PixelText(
                  won ? '${winner.name} vince!' : '${winner.name} ti ha battuto',
                  size: 15,
                ),
              ],
            ),
            const SizedBox(width: 16),
            PixelPanel(
              width: 340,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (round != null)
                    PixelText(
                      'Arcade · round $round/8',
                      size: 13,
                      color: kPlum,
                      outline: false,
                    ),
                  _StatsTable(game: game),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const PixelIcon('like', scale: 2),
                      const SizedBox(width: 6),
                      PixelText(
                        '+${game.likesEarned} like',
                        size: 20,
                        color: const Color(0xFFFF82B4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onNext != null)
                        PixelButton(
                          label: 'Prossimo round',
                          icon: 'play',
                          color: PixelColor.mint,
                          height: 46,
                          fontSize: 15,
                          onPressed: onNext!,
                        )
                      else if (!arcadeChampion)
                        PixelButton(
                          label: round != null ? 'Riprova' : 'Rivincita',
                          icon: 'replay',
                          color: PixelColor.mint,
                          height: 46,
                          fontSize: 15,
                          onPressed: onRematch,
                        ),
                      if (round == null)
                        PixelButton(
                          label: 'Cambia',
                          icon: 'left',
                          color: PixelColor.purple,
                          height: 46,
                          fontSize: 15,
                          onPressed: onBack,
                        ),
                      if (!won) const _PayRespects(),
                      PixelButton(
                        label: 'Menu',
                        icon: 'home',
                        color: PixelColor.grey,
                        height: 46,
                        fontSize: 15,
                        onPressed: onMenu,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Winner extends StatelessWidget {
  const _Winner({required this.character});

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: CharacterSpriteView(character: character, scale: 2.4, running: true),
  );
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final p = game.player, c = game.cpu;
    TableRow row(String label, String a, String b) => TableRow(
      children: [
        PixelText(label, size: 13, color: kPlum, outline: false, align: TextAlign.left),
        PixelText(a, size: 14, color: const Color(0xFFFF4F8E), outline: false),
        PixelText(b, size: 14, color: const Color(0xFF3F8FE0), outline: false),
      ],
    );
    String dmg(Fighter f) => '${f.damageDealt.round()}%';
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.6),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        row('', 'TU', 'CPU'),
        row('KO', '${p.kos}', '${c.kos}'),
        row('Cadute', '${p.falls}', '${c.falls}'),
        row('Danni inflitti', dmg(p), dmg(c)),
        row('Speciali', '${p.specialsUsed}', '${c.specialsUsed}'),
      ],
    );
  }
}

/// "Press F to pay respects" after a defeat.
class _PayRespects extends StatefulWidget {
  const _PayRespects();

  @override
  State<_PayRespects> createState() => _PayRespectsState();
}

class _PayRespectsState extends State<_PayRespects> {
  bool _paid = false;

  void _pay() {
    if (_paid) return;
    setState(() => _paid = true);
    Sound.play('click');
    if (!LocalStore.ready) return;
    LocalStore.instance.addStat('respects', 1).then((_) {
      Achievements.checkStats();
    });
  }

  @override
  Widget build(BuildContext context) => PixelButton(
    label: _paid ? 'F' : 'Premi F',
    color: _paid ? PixelColor.grey : PixelColor.yellow,
    height: 46,
    fontSize: 15,
    onPressed: _pay,
  );
}
