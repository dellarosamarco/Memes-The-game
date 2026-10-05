import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/components/enemy.dart';
import 'package:memes_the_game/game/components/items.dart';
import 'package:memes_the_game/game/level_gen.dart';
import 'package:memes_the_game/game/memes_game.dart';
import 'package:memes_the_game/models/meme_character.dart';

/// Boots the real game on a few levels and lets a dumb autopilot run right
/// and jump for a while, to catch runtime errors in the components.
void main() {
  Future<MemesGame> boot(
    WidgetTester tester,
    int level,
    MemeCharacter c,
  ) async {
    final game = MemesGame(character: c, levelIndex: level);
    await tester.binding.setSurfaceSize(const Size(860, 400));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        GameWidget(
          game: game,
          overlayBuilderMap: {
            for (final o in [
              MemesGame.overlayHud,
              MemesGame.overlayPause,
              MemesGame.overlayComplete,
              MemesGame.overlayGameOver,
              MemesGame.overlayIntro,
              MemesGame.overlayBoss,
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

  Future<void> autopilot(
    WidgetTester tester,
    MemesGame game,
    double secs,
  ) async {
    game.input.right = true;
    final frames = (secs * 60).round();
    for (var f = 0; f < frames; f++) {
      if (f % 30 == 0) game.input.pressJump();
      if (f % 30 == 20) game.input.jump = false;
      if (f % 240 == 100) game.input.specialQueued = true;
      game.update(1 / 60);
      if (game.isOver) break;
    }
    // ignore: avoid_print
    print(
      '  x=${game.player.position.x.round()}/${game.level.width.round()} '
      'likes=${game.likes} kills=${game.kills} hearts=${game.player.hearts} '
      'finished=${game.finished} over=${game.isOver}',
    );
  }

  // Levels chosen to cover springs, moving platforms, haters and a boss.
  final cases = <(int, MemeCharacter)>[
    (0, MemeCharacter.wigDog),
    (20, MemeCharacter.stareCat),
    (60, MemeCharacter.robberDog),
    (kLevelsPerWorld - 1, MemeCharacter.smileDog),
    (333, MemeCharacter.robberDog),
    (499, MemeCharacter.stareCat),
  ];
  for (final (level, c) in cases) {
    testWidgets('level $level with ${c.name} runs without errors', (
      tester,
    ) async {
      final game = await boot(tester, level, c);
      await autopilot(tester, game, 40);
      expect(game.elapsed, greaterThan(0));
      expect(game.likes, lessThanOrEqualTo(game.totalLikes));
    });
  }

  // Every newer meme plays a couple of levels, spamming its special.
  final newer = MemeCharacter.all.skip(4).toList();
  for (var i = 0; i < newer.length; i++) {
    final c = newer[i];
    final level = (i * 37 + 3) % 500;
    testWidgets('level $level with ${c.name} and its special', (tester) async {
      final game = await boot(tester, level, c);
      await autopilot(tester, game, 20);
      expect(game.elapsed, greaterThan(0));
      expect(game.likes, lessThanOrEqualTo(game.totalLikes));
    });
  }

  testWidgets('puffer jacket takes the first hit', (tester) async {
    final game = await boot(tester, 0, MemeCharacter.pigtailDog);
    final p = game.player;
    p.takeDamage(fromX: p.position.x + 10);
    expect(p.hearts, MemeCharacter.pigtailDog.hearts);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    p.takeDamage(fromX: p.position.x + 10);
    expect(p.hearts, MemeCharacter.pigtailDog.hearts - 1);
  });

  testWidgets('GTA respawn: pits cost no hearts', (tester) async {
    final game = await boot(tester, 0, MemeCharacter.gtaBean);
    game.fellInPit();
    expect(game.player.hearts, MemeCharacter.gtaBean.hearts);
    expect(game.isOver, isFalse);
  });

  testWidgets('rock head breaks bricks', (tester) async {
    final game = await boot(tester, 0, MemeCharacter.rockPatrick);
    game.level.setTile(2, 2, 'B');
    game.player.onCeiling(2, 2);
    expect(game.level.tileAt(2, 2), ' ');
  });

  testWidgets('lady terrier likes are worth double', (tester) async {
    final game = await boot(tester, 0, MemeCharacter.pearlTerrier);
    game.collectLike(Like(position: game.player.position.clone()));
    expect(game.likeScore, 20);
  });

  testWidgets('features appear in the levels used above', (tester) async {
    bool has(int i, String code) =>
        levelAt(i).spawns.any((s) => s.code == code);
    bool tile(int i, String t) => levelAt(i).map.contains(t);
    expect([20, 60, 333, 499].any((i) => tile(i, 'S')), isTrue);
    expect([20, 60, 333, 499].any((i) => has(i, 'M')), isTrue);
    expect(levelAt(kLevelsPerWorld - 1).hasBoss, isTrue);
  });

  testWidgets('power-ups: sunglasses, pizza and stonks', (tester) async {
    final game = await boot(tester, 0, MemeCharacter.wigDog);
    final p = game.player;

    // Deal with it: enemies die on contact and you take no damage.
    p.applyPowerUp(PowerUpKind.sunglasses);
    final e = Enemy(kind: EnemyKind.normie, position: p.position.clone());
    game.world.add(e);
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
      // Let the enemy's async onLoad complete.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(e.dead, isTrue);
    expect(p.hearts, MemeCharacter.wigDog.hearts);

    // Pizza heals one heart.
    p.hearts = 1;
    p.applyPowerUp(PowerUpKind.pizza);
    expect(p.hearts, 2);

    // Stonks doubles the points of a like.
    p.applyPowerUp(PowerUpKind.stonks);
    final before = game.likeScore;
    game.collectLike(Like(position: p.position.clone()));
    expect(game.likeScore - before, 20);
    expect(game.multiplier, 2);
  });
}
