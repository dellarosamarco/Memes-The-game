import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: player name and personal bests per character.
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

  int bestScore(String characterId) => _prefs.getInt('best_$characterId') ?? 0;

  /// Returns true when [score] is a new personal best.
  Future<bool> recordScore(String characterId, int score) async {
    if (score <= bestScore(characterId)) return false;
    await _prefs.setInt('best_$characterId', score);
    return true;
  }
}
