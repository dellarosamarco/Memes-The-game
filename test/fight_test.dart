import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/cpu.dart';
import 'package:memes_the_game/game/fighter/fighter.dart';
import 'package:memes_the_game/game/fighter/moves.dart';
import 'package:memes_the_game/game/memes_game.dart';
import 'package:memes_the_game/game/stages.dart';
import 'package:memes_the_game/models/meme_character.dart';

/// Boots the real game and lets two CPUs fight, to catch runtime errors in
/// fighters, specials and projectiles and to check matches actually end.
void main() {
  Future<MemesGame> boot(WidgetTester tester, MatchConfig config) async {
    final game = MemesGame(config: config);
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        GameWidget(
          game: game,
          overlayBuilderMap: {
            for (final o in [
              MemesGame.overlayHud,
              MemesGame.overlayPause,
              MemesGame.overlayResults,
              MemesGame.overlayCountdown,
            ])
              o: (_, _) => const SizedBox(),
          },
        ),
      );
      for (var i = 0; i < 100 && !game.isLoaded; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    expect(game.isLoaded, isTrue);
    return game;
  }

  /// Both sides played by the CPU; returns simulated seconds.
  Future<double> brawl(
    WidgetTester tester,
    MemesGame game, {
    double maxSecs = 240,
    Difficulty playerLevel = Difficulty.hard,
  }) async {
    final autopilot = CpuBrain(
      game.player,
      game.cpu,
      playerLevel,
      random: Random(7),
    );
    var t = 0.0;
    var f = 0;
    while (t < maxSecs && !game.matchOver) {
      if (!game.frozenFighters) autopilot.think(1 / 60);
      game.update(1 / 60);
      t += 1 / 60;
      // Let projectiles' and effects' async onLoad complete.
      if (++f % 30 == 0) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
    }
    return t;
  }

  test('knockback grows with damage and shrinks with weight', () {
    double v(double p, {double w = 1}) => Move.launchSpeed(
      base: Moves.smash.baseKb,
      growth: Moves.smash.kbGrowth,
      damage: Moves.smash.damage,
      targetPercent: p,
      weight: w,
    );
    expect(v(100), greaterThan(v(20)));
    expect(v(100, w: Fighter.weightOf(MemeCharacter.all.first) * 1.25),
        lessThan(v(100)));
  });

  test('a smash at ~120% launches a fighter from mid-stage past the side', () {
    // Horizontal travel during hitstun, with the same drag as the engine.
    final speed = Move.launchSpeed(
      base: Moves.smash.baseKb,
      growth: Moves.smash.kbGrowth,
      damage: Moves.smash.damage,
      targetPercent: 120,
    );
    final vx = Move.direction(Moves.smash.angle, true).dx * speed;
    final stun = .12 + speed * .00055;
    final travel = vx / -log(.12) * (1 - pow(.12, stun));
    final s = Stage.all.first;
    final mid = (s.left + s.right + 1) / 2;
    final toBlast = (Stage.cols + Stage.blastSide - mid) * 24;
    expect(travel, greaterThan(toBlast * .85));
  });

  test('every arena is inside its blast zones with room to fight', () {
    for (var i = 0; i < Stage.all.length; i++) {
      final s = Stage.all[i];
      final l = s.build(i);
      expect(l.walls, isFalse);
      expect(s.left, greaterThan(0));
      expect(s.right, lessThan(Stage.cols - 1));
      expect(s.right - s.left, greaterThanOrEqualTo(12), reason: s.name);
      // Both spawn points stand on solid ground.
      final w = (s.right + 1 - s.left).toDouble();
      for (final f in [.27, .73]) {
        final c = (s.left + w * f).floor();
        expect(l.isStandable(c, s.mainTop), isTrue, reason: '${s.name} $f');
      }
    }
  });

  testWidgets('a hard CPU match ends with a winner', (tester) async {
    final game = await boot(
      tester,
      const MatchConfig(
        player: MemeCharacter.wigDog,
        cpu: MemeCharacter.stareCat,
        stage: 0,
        difficulty: Difficulty.hard,
      ),
    );
    final secs = await brawl(tester, game);
    // ignore: avoid_print
    print('  match lasted ${secs.round()}s, winner ${game.winner?.character.name}');
    expect(game.matchOver, isTrue);
    expect(game.winner, isNotNull);
    expect(game.winner!.stocks, greaterThan(0));
    final loser = game.fighters.firstWhere((f) => f != game.winner);
    expect(loser.stocks, 0);
  });

  // Every meme fights on some arena, against another meme: catches errors
  // in all specials and passives.
  const all = MemeCharacter.all;
  for (var i = 0; i < all.length; i++) {
    final c = all[i];
    final o = all[(i * 7 + 5) % all.length] == c
        ? all[(i + 1) % all.length]
        : all[(i * 7 + 5) % all.length];
    final stage = i % Stage.all.length;
    testWidgets('${c.name} vs ${o.name} on ${Stage.all[stage].name}', (
      tester,
    ) async {
      final game = await boot(
        tester,
        MatchConfig(
          player: c,
          cpu: o,
          stage: stage,
          difficulty: Difficulty.values[i % 3],
        ),
      );
      await brawl(tester, game, maxSecs: 45);
      expect(game.elapsed, greaterThan(0));
      expect(game.player.specialsUsed + game.cpu.specialsUsed, greaterThan(0));
      for (final f in game.fighters) {
        expect(f.percent.isFinite, isTrue);
        expect(f.position.x.isFinite && f.position.y.isFinite, isTrue);
      }
    });
  }
}
