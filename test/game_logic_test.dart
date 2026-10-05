import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/game/upgrades.dart';
import 'package:memes_the_game/models/meme_character.dart';

void main() {
  test('every character has a unique id and attack/special', () {
    const all = MemeCharacter.all;
    expect(all.map((c) => c.id).toSet().length, all.length);
    expect(all.map((c) => c.attackType).toSet().length, all.length);
    expect(all.map((c) => c.specialType).toSet().length, all.length);
  });

  test('byId falls back to the first character', () {
    expect(MemeCharacter.byId('stare_cat'), MemeCharacter.stareCat);
    expect(MemeCharacter.byId('nope'), MemeCharacter.all.first);
  });

  test('upgrade roll returns 3 distinct upgrades', () {
    for (final c in MemeCharacter.all) {
      final roll = Upgrade.roll(c, Random(1));
      expect(roll.length, 3);
      expect(roll.map((u) => u.id).toSet().length, 3);
    }
  });

  test('upgrades modify stats', () {
    final stats = PlayerStats(MemeCharacter.wigDog);
    var healed = 0.0;
    final pool = {for (final u in Upgrade.pool(MemeCharacter.wigDog)) u.id: u};
    pool['dmg']!.apply(stats, (h) => healed += h);
    pool['hp']!.apply(stats, (h) => healed += h);
    pool['multi']!.apply(stats, (h) => healed += h);
    expect(stats.damage, closeTo(MemeCharacter.wigDog.damage * 1.2, 1e-9));
    expect(stats.maxHp, MemeCharacter.wigDog.maxHp + 25);
    expect(stats.extraProjectiles, 1);
    expect(healed, 25);
  });
}
