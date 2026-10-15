import 'dart:math';

import '../l10n/l10n.dart';
import '../models/meme_character.dart';
import 'daily.dart';
import 'local_store.dart';

/// What a mission counts.
enum MissionKind {
  play,
  win,
  kos,
  combo,
  specials,
  damage,
  smash,
  winNormal,
  winOfTheDay,
  arcadeRounds,
}

/// One of today's three missions.
class Mission {
  const Mission(this.index, this.kind, this.target, this.reward);

  /// Position in today's list (0-2), for the saved progress.
  final int index;
  final MissionKind kind;
  final int target;
  final int reward;

  int get progress =>
      min(target, LocalStore.instance.getInt('mission_p$index'));
  bool get done => progress >= target;
  bool get claimed => LocalStore.instance.getBool('mission_c$index');

  String get text {
    final n = {'n': target};
    return switch (kind) {
      MissionKind.play => tr('mission.play', 'Gioca {n} incontri', n),
      MissionKind.win =>
        target == 1
            ? tr('mission.win1', 'Vinci un incontro')
            : tr('mission.win', 'Vinci {n} incontri', n),
      MissionKind.kos => tr('mission.kos', 'Manda KO {n} avversari', n),
      MissionKind.combo => tr('mission.combo', 'Fai una combo da {n} colpi', n),
      MissionKind.specials => tr(
        'mission.specials',
        'Usa {n} mosse speciali',
        n,
      ),
      MissionKind.damage => tr('mission.damage', 'Infliggi {n}% di danni', n),
      MissionKind.smash => tr('mission.smash', 'Manda KO con uno smash'),
      MissionKind.winNormal => tr(
        'mission.winNormal',
        'Vinci a Normale o Difficile',
      ),
      MissionKind.winOfTheDay => tr(
        'mission.winOfTheDay',
        'Vinci con il meme del giorno ({name})',
        {'name': MemeCharacter.ofTheDay().name},
      ),
      MissionKind.arcadeRounds => tr(
        'mission.arcadeRounds',
        'Vinci {n} round dell\'Arcade',
        n,
      ),
    };
  }
}

/// Three missions a day (the same for everyone on a given day), with likes
/// as rewards and a bonus for finishing all of them.
class Missions {
  Missions._();

  static const bonus = 100;

  static LocalStore get _s => LocalStore.instance;

  /// Today's missions, picked from the date.
  static List<Mission> today([int? day]) {
    final d = day ?? dayNumber();
    final rnd = Random(d * 7919);
    final kinds = [...MissionKind.values]..shuffle(rnd);
    // Always one easy "play or win" mission, so every day starts gently.
    final easy = rnd.nextBool() ? MissionKind.play : MissionKind.win;
    final picked = [
      easy,
      ...kinds
          .where((k) => k != MissionKind.play && k != MissionKind.win)
          .take(2),
    ];
    return [
      for (var i = 0; i < 3; i++)
        switch (picked[i]) {
          MissionKind.play => Mission(i, picked[i], 3, 40),
          MissionKind.win => Mission(i, picked[i], 1 + rnd.nextInt(2), 50),
          MissionKind.kos => Mission(i, picked[i], 4 + rnd.nextInt(4), 60),
          MissionKind.combo => Mission(i, picked[i], 3 + rnd.nextInt(2), 60),
          MissionKind.specials => Mission(i, picked[i], 6 + rnd.nextInt(6), 50),
          MissionKind.damage => Mission(
            i,
            picked[i],
            (3 + rnd.nextInt(4)) * 100,
            60,
          ),
          MissionKind.smash => Mission(i, picked[i], 1, 70),
          MissionKind.winNormal => Mission(i, picked[i], 1, 80),
          MissionKind.winOfTheDay => Mission(i, picked[i], 1, 80),
          MissionKind.arcadeRounds => Mission(i, picked[i], 3, 80),
        },
    ];
  }

  /// A new day: progress starts over.
  static Future<void> refresh() => _rollOver();

  static Future<void> _rollOver() async {
    if (_s.getInt('missions_day', -1) == dayNumber()) return;
    for (var i = 0; i < 3; i++) {
      await _s.setInt('mission_p$i', 0);
      await _s.setBool('mission_c$i', false);
    }
    await _s.setBool('missions_bonus', false);
    await _s.setInt('missions_day', dayNumber());
  }

  /// Missions done but not claimed yet (the badge on the home button).
  static int get claimable {
    if (!LocalStore.ready) return 0;
    if (_s.getInt('missions_day', -1) != dayNumber()) return 0;
    final ms = today();
    var n = ms.where((m) => m.done && !m.claimed).length;
    if (bonusReady) n++;
    return n;
  }

  static bool get bonusReady =>
      today().every((m) => m.claimed) && !_s.getBool('missions_bonus');

  /// Counts one finished match; returns the missions it completed.
  static Future<List<Mission>> recordMatch({
    required bool won,
    required int kos,
    required int bestCombo,
    required int specials,
    required int damage,
    required int smashKos,
    required bool normalOrHard,
    required bool ofTheDay,
    required bool arcade,
  }) async {
    if (!LocalStore.ready) return const [];
    await _rollOver();
    final completed = <Mission>[];
    for (final m in today()) {
      final before = m.done;
      final p = _s.getInt('mission_p${m.index}');
      final next = switch (m.kind) {
        MissionKind.play => p + 1,
        MissionKind.win => p + (won ? 1 : 0),
        MissionKind.kos => p + kos,
        MissionKind.combo => max(p, bestCombo),
        MissionKind.specials => p + specials,
        MissionKind.damage => p + damage,
        MissionKind.smash => p + smashKos,
        MissionKind.winNormal => p + (won && normalOrHard ? 1 : 0),
        MissionKind.winOfTheDay => p + (won && ofTheDay ? 1 : 0),
        MissionKind.arcadeRounds => p + (won && arcade ? 1 : 0),
      };
      await _s.setInt('mission_p${m.index}', next);
      if (!before && m.done) completed.add(m);
    }
    return completed;
  }

  /// Claims a done mission's likes.
  static Future<int> claim(Mission m) async {
    await _rollOver();
    if (!m.done || m.claimed) return 0;
    await _s.setBool('mission_c${m.index}', true);
    await _s.addToWallet(m.reward);
    return m.reward;
  }

  static Future<int> claimBonus() async {
    if (!bonusReady) return 0;
    await _s.setBool('missions_bonus', true);
    await _s.addToWallet(bonus);
    return bonus;
  }

  /// Time left before tomorrow's missions.
  static Duration get timeLeft {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }
}
