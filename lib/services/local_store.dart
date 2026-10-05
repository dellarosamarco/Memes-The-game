import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: player name, unlocked levels, bests and stars.
class LocalStore {
  LocalStore._(this._prefs);
  static late LocalStore instance;

  final SharedPreferences _prefs;

  static Future<void> init() async {
    instance = LocalStore._(await SharedPreferences.getInstance());
    if (instance.playerName.isEmpty) {
      await instance.setPlayerName('Anon${Random().nextInt(9000) + 1000}');
    }
  }

  String get playerName => _prefs.getString('playerName') ?? '';
  Future<void> setPlayerName(String name) =>
      _prefs.setString('playerName', name);

  /// Number of levels the player can choose (at least the first).
  int get unlockedLevels => _unlockAll ? 500 : _prefs.getInt('unlocked') ?? 1;

  /// Dev aid: `--dart-define=MEMES_UNLOCK_ALL=true`.
  static const _unlockAll = bool.fromEnvironment('MEMES_UNLOCK_ALL');

  int bestScore(String levelId) => _prefs.getInt('best_$levelId') ?? 0;

  /// Sum of the stars of every level.
  int get totalStars => _prefs
      .getKeys()
      .where((k) => k.startsWith('stars_'))
      .fold(0, (s, k) => s + (_prefs.getInt(k) ?? 0));
  int stars(String levelId) => _prefs.getInt('stars_$levelId') ?? 0;

  /// Saves a completed level. Returns true when [score] is a new best.
  Future<bool> recordLevel({
    required int levelIndex,
    required String levelId,
    required int score,
    required int stars,
  }) async {
    if (levelIndex + 2 > unlockedLevels) {
      await _prefs.setInt('unlocked', levelIndex + 2);
    }
    if (stars > this.stars(levelId)) {
      await _prefs.setInt('stars_$levelId', stars);
    }
    if (score <= bestScore(levelId)) return false;
    await _prefs.setInt('best_$levelId', score);
    return true;
  }
}
