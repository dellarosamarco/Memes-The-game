import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_fight/game/components/fight_items.dart';
import 'package:memes_the_fight/game/cpu.dart';
import 'package:memes_the_fight/game/fighter/fighter.dart';
import 'package:memes_the_fight/game/fighter/moves.dart';
import 'package:memes_the_fight/game/memes_game.dart';
import 'package:memes_the_fight/game/stages.dart';
import 'package:memes_the_fight/models/meme_character.dart';

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
              MemesGame.overlayTutorial,
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
    expect(
      v(100, w: Fighter.weightOf(MemeCharacter.all.first) * 1.25),
      lessThan(v(100)),
    );
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

  testWidgets('items: pizza heals, stonks hits harder, bombs explode', (
    tester,
  ) async {
    final game = await boot(
      tester,
      const MatchConfig(
        player: MemeCharacter.wigDog,
        cpu: MemeCharacter.stareCat,
        stage: 0,
        items: false,
      ),
    );
    for (var i = 0; i < 4 * 60; i++) {
      game.update(1 / 60); // countdown
    }
    final p = game.player, c = game.cpu;
    game.cpuOff = true;
    p.percent = 50;
    p.useItem(ItemKind.pizza);
    expect(p.percent, 30);

    // Same jab, with and without stonks.
    double jab() {
      // Let both settle on the ground first.
      for (var i = 0; i < 180 && !(c.onGround && p.onGround); i++) {
        game.update(1 / 60);
      }
      p.position.y = c.position.y;
      final before = c.percent;
      // No specials or statuses in the way.
      c.specialTimer = 99;
      p.frozen = p.asleep = p.scared = p.dizzy = 0;
      c.invincible = 0;
      c.frozen = 5; // hold still (a hit unfreezes)
      c.state = FighterState.normal;
      c.velocity.setZero();
      p.facingRight = true;
      p.position.x = c.position.x - 24; // out of the push-apart range
      p.input.pressAttack();
      p.input.attack = false;
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
        p.input.attack = false;
        if (c.percent > before) break;
      }
      return c.percent - before;
    }

    final normal = jab();
    p.useItem(ItemKind.stonks);
    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
    }
    final boosted = jab();
    expect(normal, greaterThan(0));
    // (The second jab is a repeat: stale moves take 7% off.)
    expect(boosted, closeTo(normal * 1.5 * .93, .01));

    // A bomb dropped between the two.
    final before = p.percent + c.percent;
    final at = (p.position + c.position) / 2 - Vector2(0, 40);
    final bomb = FightItem(ItemKind.bomb, position: at);
    game.world.add(bomb);
    p.invincible = c.invincible = 0;
    p.stonks = 0;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 4 * 60; i++) {
      p.position.x = at.x - 30;
      c.position.x = at.x + 30;
      game.update(1 / 60);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      if (bomb.isRemoved) break;
    }
    expect(bomb.isRemoved, isTrue);
    expect(p.percent + c.percent, greaterThan(before + 20));
  });

  testWidgets('out of air jumps, jump triggers the recovery', (tester) async {
    final game = await boot(
      tester,
      const MatchConfig(
        player: MemeCharacter.stareCat,
        cpu: MemeCharacter.wigDog,
        stage: 0,
        items: false,
      ),
    );
    for (var i = 0; i < 4 * 60; i++) {
      game.update(1 / 60);
    }
    game.cpuOff = true;
    final p = game.player;
    // Off the side of the stage, falling, no jumps left.
    p.position.setValues(
      game.stage.left * 24.0 - 60,
      game.stage.mainTop * 24.0 + 40,
    );
    p.onGround = false;
    p.velocity.setValues(0, 200);
    p.airJumps = 0;
    p.usedRecovery = false;
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60); // falling for a moment
    }
    p.input.pressJump();
    game.update(1 / 60);
    expect(p.usedRecovery, isTrue);
    expect(p.velocity.y, lessThan(-300));
  });

  testWidgets('mashing buttons breaks a freeze sooner', (tester) async {
    final game = await boot(
      tester,
      const MatchConfig(
        player: MemeCharacter.wigDog,
        cpu: MemeCharacter.stareCat,
        stage: 0,
        items: false,
      ),
    );
    for (var i = 0; i < 4 * 60; i++) {
      game.update(1 / 60);
    }
    final p = game.player;
    game.cpu.specialTimer = 99;
    double freeFor({required bool mash}) {
      p.frozen = 1.2;
      var t = 0.0;
      while (p.frozen > 0 && t < 3) {
        if (mash && (t * 60).round() % 6 == 0) p.input.pressAttack();
        p.input.attack = false;
        game.cpu.frozen = 5; // keep the CPU out of it
        game.update(1 / 60);
        t += 1 / 60;
      }
      return t;
    }

    final still = freeFor(mash: false);
    final mashed = freeFor(mash: true);
    expect(still, greaterThan(1));
    expect(mashed, lessThan(still * .7));
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
    print(
      '  match lasted ${secs.round()}s, winner ${game.winner?.character.name}',
    );
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
      // Every special runs at least once (recovery-only ones, like flight
      // or the balloon, may otherwise never be needed in a short brawl).
      for (var i = 0; i < 4 * 60; i++) {
        game.update(1 / 60);
      }
      game.player.useSpecial();
      game.cpu.useSpecial();
      await brawl(tester, game, maxSecs: 45);
      expect(game.elapsed, greaterThan(0));
      expect(
        game.player.specialsUsed + game.cpu.specialsUsed,
        greaterThanOrEqualTo(2),
      );
      for (final f in game.fighters) {
        expect(f.percent.isFinite, isTrue);
        expect(f.position.x.isFinite && f.position.y.isFinite, isTrue);
      }
    });
  }
}
