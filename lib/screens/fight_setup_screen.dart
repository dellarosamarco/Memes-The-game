import 'dart:math';

import 'package:flutter/material.dart';

import '../game/memes_game.dart';
import '../game/stages.dart';
import '../models/meme_character.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import 'character_select_screen.dart';
import 'game_screen.dart';

/// Free fight: pick the opponent, the arena and how tough the CPU is.
class FightSetupScreen extends StatefulWidget {
  const FightSetupScreen({super.key, required this.player});

  final MemeCharacter player;

  @override
  State<FightSetupScreen> createState() => _FightSetupScreenState();
}

class _FightSetupScreenState extends State<FightSetupScreen> {
  // Remembered between visits (for this session).
  static String? _lastOpponent;
  static int _lastStage = -1;
  static Difficulty _lastDifficulty = Difficulty.normal;
  static bool _lastItems = true;

  final _rnd = Random();

  /// Lives per fighter (a dev define shortens matches for testing).
  static const _stocks = int.fromEnvironment('MEMES_STOCKS', defaultValue: 3);

  /// null = random opponent.
  late MemeCharacter? _opponent = _lastOpponent == null
      ? null
      : MemeCharacter.byId(_lastOpponent!);

  /// -1 = random arena.
  late int _stage = _lastStage;
  late Difficulty _difficulty = _lastDifficulty;
  late bool _items = _lastItems;

  void _fight() {
    _lastOpponent = _opponent?.id;
    _lastStage = _stage;
    _lastDifficulty = _difficulty;
    _lastItems = _items;
    final others = MemeCharacter.all
        .where((c) => c.id != widget.player.id)
        .toList();
    final cpu = _opponent ?? others[_rnd.nextInt(others.length)];
    final stage = _stage >= 0 ? _stage : _rnd.nextInt(Stage.all.length);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          config: MatchConfig(
            player: widget.player,
            cpu: cpu,
            stage: stage,
            difficulty: _difficulty,
            stocks: _stocks,
            items: _items,
          ),
        ),
      ),
    );
  }

  void _cycleStage(int d) {
    final n = Stage.all.length + 1; // + random
    setState(() => _stage = (_stage + 1 + d + n) % n - 1);
  }

  @override
  Widget build(BuildContext context) {
    final stageName = _stage < 0 ? 'Arena casuale' : Stage.all[_stage].name;
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
                    const Expanded(child: PixelText('Lotta libera', size: 24)),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 11,
                        child: PixelPanel(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            children: [
                              const PixelText(
                                'Avversario',
                                size: 15,
                                color: kPlum,
                                outline: false,
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _RandomTile(
                                        selected: _opponent == null,
                                        onTap: () =>
                                            setState(() => _opponent = null),
                                      ),
                                      for (final c in MemeCharacter.all)
                                        SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: Center(
                                            child: MemeThumb(
                                              character: c,
                                              size: 44,
                                              selected: _opponent == c,
                                              onTap: () =>
                                                  setState(() => _opponent = c),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 9,
                        child: Column(
                          children: [
                            Expanded(
                              child: _Versus(
                                player: widget.player,
                                opponent: _opponent,
                              ),
                            ),
                            Row(
                              children: [
                                _SmallArrow('left', () => _cycleStage(-1)),
                                Expanded(
                                  child: _StagePreview(
                                    stage: _stage,
                                    name: stageName,
                                  ),
                                ),
                                _SmallArrow('right', () => _cycleStage(1)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final d in Difficulty.values)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: PixelButton(
                                      label: d.label,
                                      height: 38,
                                      fontSize: 12,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      color: d == _difficulty
                                          ? PixelColor.purple
                                          : PixelColor.grey,
                                      onPressed: () =>
                                          setState(() => _difficulty = d),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PixelButton(
                                  label: _items ? 'Oggetti: Sì' : 'Oggetti: No',
                                  height: 54,
                                  fontSize: 12,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  color: _items
                                      ? PixelColor.mint
                                      : PixelColor.grey,
                                  onPressed: () =>
                                      setState(() => _items = !_items),
                                ),
                                const SizedBox(width: 6),
                                PixelButton(
                                  label: 'Combatti!',
                                  icon: 'play',
                                  onPressed: _fight,
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

class _Versus extends StatelessWidget {
  const _Versus({required this.player, required this.opponent});

  final MemeCharacter player;
  final MemeCharacter? opponent;

  @override
  Widget build(BuildContext context) {
    final o = opponent;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CharacterSpriteView(character: player, scale: 2.2),
          const Padding(
            padding: EdgeInsets.only(bottom: 40, left: 4, right: 4),
            child: PixelText('VS', size: 30, color: Color(0xFFFFE07A)),
          ),
          if (o != null)
            Transform.flip(
              flipX: true,
              child: CharacterSpriteView(
                key: ValueKey(o.id),
                character: o,
                scale: 2.2,
                showHat: false,
              ),
            )
          else
            const SizedBox(
              width: 132,
              height: 132,
              child: Center(
                child: PixelText('?', size: 64, color: Color(0xFF7CC8FF)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StagePreview extends StatelessWidget {
  const _StagePreview({required this.stage, required this.name});

  final int stage;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = stage >= 0 ? Stage.all[stage].theme.name : null;
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2440),
        border: Border.all(color: kPlum, width: 3),
        borderRadius: BorderRadius.circular(4),
        image: theme == null
            ? null
            : DecorationImage(
                image: AssetImage('assets/images/sprites/bg_${theme}_far.png'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
              ),
      ),
      alignment: Alignment.center,
      child: PixelText(name, size: 14),
    );
  }
}

class _SmallArrow extends StatelessWidget {
  const _SmallArrow(this.icon, this.onTap);

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PixelButton(
    icon: icon,
    color: PixelColor.grey,
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    onPressed: onTap,
  );
}

class _RandomTile extends StatelessWidget {
  const _RandomTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: selected ? 54 : 44,
          height: selected ? 54 : 44,
          alignment: Alignment.center,
          decoration: pixelFrame(
            selected
                ? 'assets/images/ui/button_yellow.png'
                : 'assets/images/ui/button_blue.png',
            px: 2,
          ),
          child: const PixelIcon('dice', scale: 2),
        ),
      ),
    ),
  );
}
