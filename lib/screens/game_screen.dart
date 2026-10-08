import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/arcade.dart';
import '../game/memes_game.dart';
import '../game/overlays/how_to_play.dart';
import '../game/overlays/hud.dart';
import '../game/overlays/match_overlays.dart';
import '../game/overlays/pause_overlay.dart';
import '../services/achievements.dart';
import '../services/local_store.dart';
import '../services/sound.dart';
import '../widgets/pixel_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.config, this.arcade});

  final MatchConfig config;

  /// The Arcade run this fight belongs to, if any.
  final ArcadeRun? arcade;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final MemesGame _game = MemesGame(config: widget.config)
    ..onMatchEnd = _matchEnded;

  int? get _round => widget.config.arcadeRound;
  bool get _lastRound => _round == ArcadeRun.rounds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A phone call, the home button...: stop the action.
    if (state != AppLifecycleState.resumed) _game.pauseIfPlaying();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Back to the menus.
    Sound.music('menu');
    super.dispose();
  }

  void _matchEnded(bool won) {
    final run = widget.arcade;
    final round = _round;
    if (run == null || round == null || !LocalStore.ready) return;
    final cleared = won ? round : round - 1;
    LocalStore.instance.recordArcade(widget.config.player.id, cleared).then((
      _,
    ) {
      if (won && _lastRound) {
        Achievements.checkStats();
        if (run.difficulty == Difficulty.hard) {
          Achievements.unlock('arcade_hard');
        }
      }
    });
  }

  void _replace(MatchConfig config) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(config: config, arcade: widget.arcade),
      ),
    );
  }

  void _toMenu() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final run = widget.arcade;
    // Android back button / gesture: first pause, then (from the pause
    // menu or the results) leave the fight.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_game.isPaused || _game.matchOver) {
          Navigator.of(context).pop();
        } else {
          _game.togglePause();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF8CCBFF),
        body: GameWidget<MemesGame>(
          game: _game,
          overlayBuilderMap: {
            MemesGame.overlayHud: (_, g) => Hud(game: g),
            MemesGame.overlayPause: (_, g) => PauseOverlay(game: g),
            MemesGame.overlayCountdown: (_, g) => CountdownOverlay(game: g),
            MemesGame.overlayTutorial: (_, g) => TutorialOverlay(game: g),
            MemesGame.overlayResults: (_, g) {
              final won = g.winner == g.player;
              final round = _round;
              return ResultsOverlay(
                game: g,
                arcadeChampion: won && _lastRound,
                onNext: run != null && round != null && won && !_lastRound
                    ? () => _replace(run.configFor(round + 1))
                    : null,
                onRematch: () => _replace(widget.config),
                onBack: () => Navigator.of(context).pop(),
                onMenu: _toMenu,
              );
            },
          },
          initialActiveOverlays: const [MemesGame.overlayHud],
          loadingBuilder: (_) =>
              const Center(child: PixelText('Caricamento...', size: 22)),
        ),
      ),
    );
  }
}
