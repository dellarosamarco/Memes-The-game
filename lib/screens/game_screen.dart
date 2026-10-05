import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/memes_game.dart';
import '../game/overlays/banners.dart';
import '../game/overlays/end_overlays.dart';
import '../game/overlays/hud.dart';
import '../game/overlays/pause_overlay.dart';
import '../models/meme_character.dart';
import '../services/sound.dart';

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

class _GameScreenState extends State<GameScreen> {
  late final MemesGame _game = MemesGame(
    character: widget.character,
    levelIndex: widget.levelIndex,
  );

  @override
  void dispose() {
    // Back to the menus.
    Sound.music('menu');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
