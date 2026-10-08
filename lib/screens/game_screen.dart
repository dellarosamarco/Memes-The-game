import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/memes_game.dart';
import '../game/overlays/banners.dart';
import '../game/overlays/end_overlays.dart';
import '../game/overlays/hud.dart';
import '../game/overlays/pause_overlay.dart';
import '../models/meme_character.dart';
import '../services/sound.dart';
import '../widgets/pixel_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.character,
    required this.levelIndex,
  });

  final MemeCharacter character;
  final int levelIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final MemesGame _game = MemesGame(
    character: widget.character,
    levelIndex: widget.levelIndex,
  );

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

  @override
  Widget build(BuildContext context) {
    // Android back button / gesture: first pause, then (from the pause
    // menu or an end screen) leave the level.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_game.isPaused || _game.isOver || _game.finished) {
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
            MemesGame.overlayComplete: (_, g) => LevelCompleteOverlay(game: g),
            MemesGame.overlayGameOver: (_, g) => GameOverOverlay(game: g),
            MemesGame.overlayIntro: (_, g) => LevelIntroBanner(game: g),
            MemesGame.overlayBoss: (_, g) => BossBanner(game: g),
          },
          initialActiveOverlays: const [MemesGame.overlayHud],
          loadingBuilder: (_) =>
              const Center(child: PixelText('Caricamento...', size: 22)),
        ),
      ),
    );
  }
}
