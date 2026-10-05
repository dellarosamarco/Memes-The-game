import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/level.dart';
import 'package:memes_the_game/game/level_gen.dart';
import 'package:memes_the_game/game/level_solver.dart';
import 'package:memes_the_game/models/meme_character.dart';

LevelData _flatWithGap(int gap, {String obstacle = ' '}) {
  final cols = 12 + gap + 12;
  String row(String Function(int c) f) => List.generate(cols, f).join();
  return LevelData(
    index: 0,
    theme: LevelTheme.feed,
    parTime: 60,
    map: [
      for (var r = 0; r < 11; r++) row((_) => ' '),
      row((c) => c == 2 ? 'P' : (c == cols - 3 ? 'F' : ' ')),
      for (var r = 0; r < 2; r++)
        row((c) => c >= 12 && c < 12 + gap ? obstacle : '#'),
    ].join('\n'),
  );
}

void main() {
  test('every character has a unique id, passive and special', () {
    const all = MemeCharacter.all;
    expect(all.map((c) => c.id).toSet().length, all.length);
    expect(all.map((c) => c.passive).toSet().length, all.length);
    expect(all.map((c) => c.specialType).toSet().length, all.length);
  });

  test('byId falls back to the first character', () {
    expect(MemeCharacter.byId('stare_cat'), MemeCharacter.stareCat);
    expect(MemeCharacter.byId('nope'), MemeCharacter.all.first);
  });

  test('solver: 3-tile gaps are jumpable, 6-tile gaps are not', () {
    expect(LevelSolver(_flatWithGap(3)).solve(), isTrue);
    expect(LevelSolver(_flatWithGap(6)).solve(), isFalse);
  });

  test('level ids, names and worlds', () {
    final l = levelAt(123);
    expect(l.id, 'L124');
    expect(l.world, 3);
    expect(l.number, 24);
    expect(l.name, '3-24');
    expect(l.theme, LevelTheme.beach);
  });

  test('copy restores mutated tiles', () {
    final l = levelAt(0).copy();
    l.setTile(0, 13, ' ');
    expect(l.copy().tileAt(0, 13), levelAt(0).tileAt(0, 13));
  });

  test('isSolid treats the level sides as walls and the bottom as a pit', () {
    final l = levelAt(0);
    expect(l.isSolid(-1, 5), isTrue);
    expect(l.isSolid(l.cols, 5), isTrue);
    expect(l.isSolid(5, l.rows), isFalse);
  });

  test('meme of the day changes every day and covers everyone', () {
    final seen = <String>{};
    for (var d = 0; d < MemeCharacter.all.length; d++) {
      seen.add(MemeCharacter.ofTheDay(DateTime(2026, 1, 1 + d)).id);
    }
    expect(seen.length, MemeCharacter.all.length);
  });
}
