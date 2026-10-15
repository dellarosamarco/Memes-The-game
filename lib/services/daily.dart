import 'local_store.dart';

/// Today as a number (days since 1970, local calendar), for "once a day".
int dayNumber([DateTime? now]) {
  final d = now ?? DateTime.now();
  return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// The daily login reward: a 7-day streak of growing likes. Skipping a
/// day starts the streak again; after day 7 it loops.
class DailyReward {
  DailyReward._();

  static const rewards = [20, 30, 40, 60, 80, 100, 250];

  static LocalStore get _s => LocalStore.instance;

  /// Days of the streak already claimed (0-7), as of [today].
  static int streak([int? today]) {
    final t = today ?? dayNumber();
    final last = _s.getInt('daily_last', -10);
    // Missed a day (or never played): back to the start.
    if (t - last > 1) return 0;
    return _s.getInt('daily_streak');
  }

  /// Today's reward is waiting.
  static bool get available =>
      LocalStore.ready && _s.getInt('daily_last', -10) != dayNumber();

  /// Index (0-6) of the reward that is (or was) claimable today.
  static int get todayIndex {
    final s = available ? streak() : _s.getInt('daily_streak') - 1;
    return s % rewards.length;
  }

  /// Claims today's likes; returns how many (0 if already claimed).
  static Future<int> claim() async {
    if (!available) return 0;
    final i = todayIndex;
    final likes = rewards[i];
    await _s.setInt('daily_streak', streak() + 1);
    await _s.setInt('daily_last', dayNumber());
    await _s.addToWallet(likes);
    return likes;
  }
}
