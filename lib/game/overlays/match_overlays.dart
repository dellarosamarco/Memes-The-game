import 'package:flutter/material.dart';

import '../../models/meme_character.dart';
import '../../services/achievements.dart';
import '../../services/local_store.dart';
import '../../services/sound.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprite_view.dart';
import '../fighter/fighter.dart';
import '../memes_game.dart';
import '../../l10n/l10n.dart';

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
            text = round != null
                ? tr('countdown.round', 'Round {n}', {'n': round})
                : game.stage.name;
            size = 30;
          } else if (c > 0) {
            text = '${c.ceil()}';
            size = 80;
          } else {
            text = tr('countdown.go', 'VIA!');
            size = 80;
          }
          // Up in the sky (not where the fighters meet); "VIA!" fades out.
          final fade = c > 0 ? 1.0 : (1 + c / .7).clamp(0.0, 1.0);
          return Align(
            alignment: const Alignment(0, -.45),
            child: Opacity(
              opacity: fade,
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
    this.rewardMeme,
  });

  /// Unlocked for clearing the Arcade.
  final MemeCharacter? rewardMeme;

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
      title = tr('results.champion', 'CAMPIONE!');
    } else if (won) {
      title = tr('results.victory', 'VITTORIA!');
    } else {
      title = tr('results.defeat', 'SCONFITTA');
    }
    final winner = game.winner?.character ?? game.player.character;
    return Container(
      color: const Color(0xD03A2440),
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
                  color: won
                      ? const Color(0xFFFFE07A)
                      : const Color(0xFF9AB4FF),
                ),
                const SizedBox(height: 4),
                _Winner(character: winner, hat: won),
                PixelText(
                  won
                      ? tr('results.wins', '{name} vince!', {
                          'name': winner.name,
                        })
                      : tr('results.beatYou', '{name} ti ha battuto', {
                          'name': winner.name,
                        }),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: PixelText(
                        tr('results.arcadeRound', 'Arcade · round {n}/8', {
                          'n': round,
                        }),
                        size: 13,
                        color: kPlum,
                        outline: false,
                      ),
                    ),
                  _StatsTable(game: game),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const PixelIcon('like', scale: 2),
                      const SizedBox(width: 6),
                      PixelText(
                        tr('results.likes', '+{n} like', {
                          'n': game.likesEarned,
                        }),
                        size: 20,
                        color: const Color(0xFFFF82B4),
                      ),
                    ],
                  ),
                  if (rewardMeme != null)
                    PixelText(
                      tr('results.unlocked', 'Nuovo meme sbloccato: {name}!', {
                        'name': rewardMeme!.name,
                      }),
                      size: 13,
                      color: const Color(0xFFE08A00),
                      outline: false,
                    )
                  else
                    const _NextUnlock(),
                  for (final m in game.missionsDone)
                    PixelText(
                      tr('results.missionDone', 'Missione completata: {text}', {
                        'text': m.text,
                      }),
                      size: 11,
                      color: const Color(0xFF2E9E6E),
                      outline: false,
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onNext != null)
                        PixelButton(
                          label: tr('results.nextRound', 'Prossimo round'),
                          icon: 'play',
                          color: PixelColor.mint,
                          height: 46,
                          fontSize: 15,
                          onPressed: onNext!,
                        )
                      else if (!arcadeChampion)
                        PixelButton(
                          label: round != null
                              ? tr('results.retry', 'Riprova')
                              : tr('results.rematch', 'Rivincita'),
                          icon: 'replay',
                          color: PixelColor.mint,
                          height: 46,
                          fontSize: 15,
                          onPressed: onRematch,
                        ),
                      if (round == null)
                        PixelButton(
                          label: tr('results.change', 'Cambia'),
                          icon: 'left',
                          color: PixelColor.purple,
                          height: 46,
                          fontSize: 15,
                          onPressed: onBack,
                        ),
                      if (!won) const _PayRespects(),
                      PixelButton(
                        label: tr('results.menu', 'Menu'),
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

/// The cheapest locked meme and how far the wallet is from it.
class _NextUnlock extends StatelessWidget {
  const _NextUnlock();

  @override
  Widget build(BuildContext context) {
    if (!LocalStore.ready) return const SizedBox.shrink();
    final locked = [
      for (final c in MemeCharacter.all)
        if (!c.isUnlocked) c,
    ]..sort((a, b) => a.price.compareTo(b.price));
    if (locked.isEmpty) return const SizedBox.shrink();
    final c = locked.first;
    final missing = c.price - LocalStore.instance.wallet;
    return PixelText(
      missing <= 0
          ? tr('results.canUnlock', 'Puoi sbloccare {name}!', {'name': c.name})
          : tr('results.nextUnlock', '{name} si sblocca tra {n} like', {
              'name': c.name,
              'n': missing,
            }),
      size: 12,
      color: kPlum,
      outline: false,
    );
  }
}

class _Winner extends StatelessWidget {
  const _Winner({required this.character, required this.hat});

  final MemeCharacter character;

  /// Only the player wears the hat bought in the shop.
  final bool hat;

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    // Room for a hat under the title.
    margin: EdgeInsets.only(top: hat ? 18 : 0),
    child: CharacterSpriteView(
      character: character,
      scale: 2.4,
      running: true,
      showHat: hat,
    ),
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
        PixelText(
          label,
          size: 13,
          color: kPlum,
          outline: false,
          align: TextAlign.left,
        ),
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
        row('', tr('hud.you', 'TU'), tr('hud.cpu', 'CPU')),
        row(tr('results.kos', 'KO'), '${p.kos}', '${c.kos}'),
        row(tr('results.falls', 'Cadute'), '${p.falls}', '${c.falls}'),
        row(tr('results.damage', 'Danni inflitti'), dmg(p), dmg(c)),
        row(
          tr('results.bestCombo', 'Combo migliore'),
          '${p.bestCombo}',
          '${c.bestCombo}',
        ),
        row(
          tr('results.specials', 'Speciali'),
          '${p.specialsUsed}',
          '${c.specialsUsed}',
        ),
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
    label: _paid
        ? tr('results.respectsPaid', 'F: rispetto dato')
        : tr('results.payRespects', 'Premi F'),
    color: _paid ? PixelColor.grey : PixelColor.yellow,
    height: 46,
    fontSize: 15,
    onPressed: _pay,
  );
}
