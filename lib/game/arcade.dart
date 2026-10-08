import 'dart:math';

import '../models/meme_character.dart';
import 'memes_game.dart';
import 'stages.dart';

/// One Arcade run: eight CPU fights in a row, each a bit harder.
class ArcadeRun {
  ArcadeRun({required this.player, required this.difficulty, Random? random}) {
    final rnd = random ?? Random();
    final pool = MemeCharacter.all.where((c) => c.id != player.id).toList()
      ..shuffle(rnd);
    opponents = pool.take(rounds).toList();
    final arenas = List.generate(Stage.all.length, (i) => i)..shuffle(rnd);
    stages = [for (var i = 0; i < rounds; i++) arenas[i % arenas.length]];
  }

  static const rounds = 8;

  final MemeCharacter player;

  /// The difficulty chosen for the run: the CPU starts below it and ends
  /// above it.
  final Difficulty difficulty;
  late final List<MemeCharacter> opponents;
  late final List<int> stages;

  /// CPU level for a 1-based [round].
  Difficulty difficultyFor(int round) {
    final steps = switch (difficulty) {
      Difficulty.easy => [0, 0, 0, 0, 0, 1, 1, 1],
      Difficulty.normal => [0, 0, 1, 1, 1, 1, 2, 2],
      Difficulty.hard => [1, 1, 2, 2, 2, 2, 2, 2],
    };
    return Difficulty.values[steps[round - 1]];
  }

  /// Fewer lives in the early rounds keeps a run short.
  int stocksFor(int round) => round <= 3 ? 2 : 3;

  MatchConfig configFor(int round) => MatchConfig(
    player: player,
    cpu: opponents[round - 1],
    stage: stages[round - 1],
    difficulty: difficultyFor(round),
    stocks: stocksFor(round),
    arcadeRound: round,
  );
}
