import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/level.dart';
import 'package:memes_the_game/game/level_gen.dart';
import 'package:memes_the_game/game/level_solver.dart';

void main() {
  test('all 500 levels are generated and solvable', () {
    final sw = Stopwatch()..start();
    final retries = <int, int>{};
    for (var i = 0; i < kLevelCount; i++) {
      var attempt = 0;
      while (true) {
        final l = LevelGenerator(i, attempt).build();
        if (LevelSolver(l).solve()) break;
        attempt++;
        expect(attempt, lessThan(40), reason: 'level $i never solvable');
      }
      if (attempt > 0) retries[i] = attempt;
    }
    // ignore: avoid_print
    print(
      '500 levels in ${sw.elapsedMilliseconds} ms, '
      '${retries.length} needed a retry: $retries',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('levels are deterministic and well formed', () {
    for (final i in [0, 1, 49, 50, 123, 249, 499]) {
      final a = levelAt(i);
      expect(LevelGenerator(i, 0).build().map.isNotEmpty, isTrue);
      expect(a.rows, 14);
      expect(a.spawns.where((s) => s.code == 'P').length, 1);
      expect(a.spawns.where((s) => s.code == 'F').length, 1);
      expect(a.hasBoss, i % kLevelsPerWorld == kLevelsPerWorld - 1);
      expect(a.theme, LevelTheme.values[i ~/ kLevelsPerWorld]);
      expect(levelAt(i).map, a.map);
    }
  });

  test('the solver rejects an impossible level', () {
    final l = LevelData(
      index: 0,
      theme: LevelTheme.feed,
      parTime: 60,
      map: [
        for (var r = 0; r < 12; r++) ' ' * 30,
        '${'P'.padLeft(3)}${' ' * 27}'.replaceRange(29, 30, 'F'),
        '#####${' ' * 20}#####',
        '#####${' ' * 20}#####',
      ].join('\n'),
    );
    expect(LevelSolver(l).solve(), isFalse);
  });
}
