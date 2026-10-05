import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/memes_game.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/hud.dart';
import '../game/overlays/level_up_overlay.dart';
import '../game/overlays/pause_overlay.dart';
import '../models/meme_character.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.character});

  final MemeCharacter character;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MemesGame _game = MemesGame(character: widget.character);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<MemesGame>(
        game: _game,
        overlayBuilderMap: {
          MemesGame.overlayHud: (_, g) => Hud(game: g),
          MemesGame.overlayLevelUp: (_, g) => LevelUpOverlay(game: g),
          MemesGame.overlayPause: (_, g) => PauseOverlay(game: g),
          MemesGame.overlayGameOver: (_, g) => GameOverOverlay(game: g),
        },
        initialActiveOverlays: const [MemesGame.overlayHud],
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
