import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/arcade.dart';
import 'package:memes_the_game/game/memes_game.dart';
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

  test('arcade: 8 different opponents, never yourself, harder and harder', () {
    for (final d in Difficulty.values) {
      final run = ArcadeRun(player: MemeCharacter.stareCat, difficulty: d);
      expect(run.opponents.length, ArcadeRun.rounds);
      expect(run.opponents.toSet().length, ArcadeRun.rounds);
      expect(run.opponents, isNot(contains(MemeCharacter.stareCat)));
      for (var r = 2; r <= ArcadeRun.rounds; r++) {
        expect(
          run.difficultyFor(r).index,
          greaterThanOrEqualTo(run.difficultyFor(r - 1).index),
        );
      }
      final last = run.configFor(ArcadeRun.rounds);
      expect(last.arcadeRound, ArcadeRun.rounds);
      expect(last.player, MemeCharacter.stareCat);
    }
  });

  test('meme of the day changes every day and covers everyone', () {
    final seen = <String>{};
    for (var d = 0; d < MemeCharacter.all.length; d++) {
      seen.add(MemeCharacter.ofTheDay(DateTime(2026, 1, 1 + d)).id);
    }
    expect(seen.length, MemeCharacter.all.length);
  });

  test('character texts only use glyphs the pixel font has', () {
    // Pixelify Sans covers Latin-1 (+ a few dashes); arrows, music notes and
    // emoji would show up as empty boxes.
    bool ok(String t) =>
        t.runes.every((r) => r < 0x250 || r == 0x2014 || r == 0x2013);
    for (final c in MemeCharacter.all) {
      for (final t in [
        c.name,
        c.memeAlias,
        c.tagline,
        c.lore,
        c.passiveName,
        c.passiveDescription,
        c.specialName,
        c.specialDescription,
        c.specialShout,
        ...c.hurtLines,
      ]) {
        expect(ok(t), isTrue, reason: '${c.id}: "$t"');
      }
    }
  });
}
