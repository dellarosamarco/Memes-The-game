import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/level.dart';
import 'package:memes_the_game/game/levels.dart';
import 'package:memes_the_game/models/meme_character.dart';

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

  for (final level in kLevels) {
    group('level ${level.id}', () {
      test('has exactly one start and one finish', () {
        expect(level.spawns.where((s) => s.code == 'P').length, 1);
        expect(level.spawns.where((s) => s.code == 'F').length, 1);
      });

      test('is 14 rows tall and every spawn is a known code', () {
        expect(level.rows, 14);
        for (final s in level.spawns) {
          expect('PoKFncbhA'.contains(s.code), isTrue, reason: s.code);
        }
      });

      test('start and finish stand on solid ground', () {
        for (final code in ['P', 'F']) {
          final s = level.spawns.firstWhere((s) => s.code == code);
          expect(level.isStandable(s.col, s.row + 1), isTrue, reason: code);
        }
      });

      test('copy restores mutated tiles', () {
        final l = level.copy();
        l.setTile(0, 13, ' ');
        expect(l.copy().tileAt(0, 13), level.tileAt(0, 13));
      });
    });
  }

  test('isSolid treats the level sides as walls and the bottom as a pit', () {
    final l = kLevels.first;
    expect(l.isSolid(-1, 5), isTrue);
    expect(l.isSolid(l.cols, 5), isTrue);
    expect(l.isSolid(5, l.rows), isFalse);
    expect(kTile, 24);
  });
}
