import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_fight/models/meme_character.dart';
import 'package:memes_the_fight/services/daily.dart';
import 'package:memes_the_fight/services/local_store.dart';
import 'package:memes_the_fight/services/missions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalStore> fresh([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    await LocalStore.init();
    return LocalStore.instance;
  }

  test(
    'daily reward: once a day, a growing streak, reset after a gap',
    () async {
      final s = await fresh();
      expect(DailyReward.available, isTrue);
      expect(await DailyReward.claim(), DailyReward.rewards[0]);
      expect(DailyReward.available, isFalse);
      expect(await DailyReward.claim(), 0);
      // Came back the next day: day 2 of the streak.
      await s.setInt('daily_last', dayNumber() - 1);
      expect(await DailyReward.claim(), DailyReward.rewards[1]);
      // Skipped a day: back to day 1.
      await s.setInt('daily_last', dayNumber() - 2);
      expect(await DailyReward.claim(), DailyReward.rewards[0]);
      expect(s.wallet, DailyReward.rewards[0] * 2 + DailyReward.rewards[1]);
    },
  );

  test('missions: three a day, progress, claims and the bonus', () async {
    final s = await fresh();
    for (var day = 20000; day < 20030; day++) {
      final ms = Missions.today(day);
      expect(ms, hasLength(3));
      expect(ms.map((m) => m.kind).toSet(), hasLength(3), reason: '$day');
      expect([MissionKind.play, MissionKind.win], contains(ms.first.kind));
      expect(ms.every((m) => m.text.isNotEmpty && m.target > 0), isTrue);
    }
    // A crushing match completes whatever it can.
    Future<void> win() => Missions.recordMatch(
      won: true,
      kos: 3,
      bestCombo: 6,
      specials: 6,
      damage: 400,
      smashKos: 1,
      normalOrHard: true,
      ofTheDay: true,
      arcade: true,
    );
    for (var i = 0; i < 4; i++) {
      await win();
    }
    final ms = Missions.today();
    expect(ms.every((m) => m.done), isTrue);
    expect(Missions.claimable, 3);
    var got = 0;
    for (final m in ms) {
      got += await Missions.claim(m);
      expect(await Missions.claim(m), 0); // only once
    }
    expect(got, ms.fold<int>(0, (a, m) => a + m.reward));
    expect(Missions.claimable, 1); // the bonus
    expect(await Missions.claimBonus(), Missions.bonus);
    expect(Missions.claimable, 0);
    expect(s.wallet, got + Missions.bonus);
  });

  test('memes: the first ones are free, the others are bought', () async {
    final s = await fresh();
    const free = MemeCharacter.all;
    expect(
      free.take(MemeCharacter.freeCount).every((c) => c.isUnlocked),
      isTrue,
    );
    final locked = MemeCharacter.all
        .skip(MemeCharacter.freeCount)
        .firstWhere((c) => !c.isOfTheDay);
    expect(locked.isUnlocked, isFalse);
    expect(locked.price, greaterThan(0));
    expect(await s.buyMeme(locked.id, locked.price), isFalse); // no likes
    await s.addToWallet(locked.price);
    expect(await s.buyMeme(locked.id, locked.price), isTrue);
    expect(locked.isUnlocked, isTrue);
    expect(s.wallet, 0);
    // The meme of the day can be tried for free (but isn't owned).
    final day = MemeCharacter.ofTheDay();
    expect(day.isUnlocked, isTrue);
  });

  test('old saves keep the memes they already played with', () async {
    final last = MemeCharacter.all.last;
    await fresh({
      'playerName': 'Old',
      'playedWith': [last.id],
    });
    expect(last.isOwned, isTrue);
  });
}
