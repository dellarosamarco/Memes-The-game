import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_game/models/hats.dart';
import 'package:memes_the_game/services/achievements.dart';
import 'package:memes_the_game/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
  });

  test('likes go to the wallet and buy hats', () async {
    final s = LocalStore.instance;
    expect(s.wallet, 0);
    await s.addToWallet(100);
    final party = Hat.byId('party')!;
    expect(await s.buyHat('crown', 500), isFalse);
    expect(await s.buyHat(party.id, party.price), isTrue);
    expect(s.wallet, 100 - party.price);
    expect(s.ownedHats, contains('party'));
    expect(await s.buyHat(party.id, party.price), isFalse); // already owned
    await s.equipHat('party');
    expect(s.equippedHat, 'party');
    await s.equipHat(null);
    expect(s.equippedHat, isNull);
  });

  test('trophies unlock once and from stats', () async {
    final s = LocalStore.instance;
    Achievements.toasts.value = [];
    Achievements.unlock('first_win');
    Achievements.unlock('first_win');
    expect(s.trophies, {'first_win'});
    expect(Achievements.toasts.value.length, 1);

    await s.addStat('kos', 100);
    Achievements.checkStats();
    expect(s.trophies, contains('kos100'));
  });

  test('every hat has a unique id and sheet frame', () {
    expect(Hat.all.map((h) => h.id).toSet().length, Hat.all.length);
    expect(Hat.all.map((h) => h.index).toSet().length, Hat.all.length);
  });

  test('"Cancella i miei dati" forgets everything but keeps a name', () async {
    final s = LocalStore.instance;
    await s.addToWallet(300);
    await s.buyHat('party', 30);
    await s.setPlayerName('Marco');
    await s.recordArcade('stare_cat', 3);
    await s.markWonWith('stare_cat');
    await s.clearAll();
    expect(s.wallet, 0);
    expect(s.ownedHats, isEmpty);
    expect(s.playerName, startsWith('Anon'));
    expect(s.arcadeBest('stare_cat'), 0);
    expect(s.wonWith, isEmpty);
  });
}
