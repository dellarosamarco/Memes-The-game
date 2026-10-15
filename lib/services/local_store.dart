import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: player name, settings, likes, hats, stats, trophies.
class LocalStore {
  LocalStore._(this._prefs);
  static LocalStore? _instance;
  static LocalStore get instance => _instance!;
  static bool get ready => _instance != null;

  final SharedPreferences _prefs;

  static Future<void> init() async {
    _instance = LocalStore._(await SharedPreferences.getInstance());
    if (instance.playerName.isEmpty) {
      await instance.setPlayerName('Anon${Random().nextInt(9000) + 1000}');
    }
    // Saves from before memes had to be unlocked keep every meme they
    // already played with.
    if (!instance.getBool('memes_migrated')) {
      await instance._prefs.setStringList('memes', [
        ...instance.ownedMemes,
        ...instance.playedWith,
      ]);
      await instance.setBool('memes_migrated', true);
    }
  }

  /// Forgets everything: progress, stars, likes, hats, trophies, settings.
  Future<void> clearAll() async {
    await _prefs.clear();
    await setPlayerName('Anon${Random().nextInt(9000) + 1000}');
  }

  String get playerName => _prefs.getString('playerName') ?? '';
  Future<void> setPlayerName(String name) =>
      _prefs.setString('playerName', name);

  /// Dev aid: `--dart-define=MEMES_UNLOCK_ALL=true` (every arena open).
  static const unlockAll = bool.fromEnvironment('MEMES_UNLOCK_ALL');

  bool get musicOn => _prefs.getBool('music') ?? true;
  bool get sfxOn => _prefs.getBool('sfx') ?? true;
  bool get hapticsOn => _prefs.getBool('haptics') ?? true;
  Future<void> setMusicOn(bool v) => _prefs.setBool('music', v);
  Future<void> setSfxOn(bool v) => _prefs.setBool('sfx', v);
  Future<void> setHapticsOn(bool v) => _prefs.setBool('haptics', v);

  /// The player's language (null: follow the device).
  String? get language => _prefs.getString('lang');
  Future<void> setLanguage(String? code) =>
      code == null ? _prefs.remove('lang') : _prefs.setString('lang', code);

  /// Simple controls: smart attacks and automatic recovery.
  /// The meme picked last time (character select starts there).
  String? get lastMeme => _prefs.getString('last_meme');
  Future<void> setLastMeme(String id) => _prefs.setString('last_meme', id);

  bool get assistOn => _prefs.getBool('assist') ?? true;
  Future<void> setAssistOn(bool v) => _prefs.setBool('assist', v);

  /// The "how to fight" card was shown once already.
  bool get tutorialSeen => _prefs.getBool('tutorial_seen') ?? false;
  Future<void> setTutorialSeen() => _prefs.setBool('tutorial_seen', true);

  // ------------------------------------------------- wallet & cosmetics

  /// Likes you can spend in the shop.
  int get wallet => (_prefs.getInt('wallet') ?? 0) + (_rich ? 2000 : 0);

  /// Dev aid: `--dart-define=MEMES_RICH=true` adds 2000 likes to spend.
  static const _rich = bool.fromEnvironment('MEMES_RICH');
  Future<void> addToWallet(int likes) =>
      _prefs.setInt('wallet', (_prefs.getInt('wallet') ?? 0) + likes);

  Set<String> get ownedHats => (_prefs.getStringList('hats') ?? []).toSet();
  String? get equippedHat => _prefs.getString('hat');
  Future<void> equipHat(String? id) =>
      id == null ? _prefs.remove('hat') : _prefs.setString('hat', id);

  /// Returns false when you can't afford it.
  Future<bool> buyHat(String id, int price) async {
    if (wallet < price || ownedHats.contains(id)) return false;
    await _prefs.setInt('wallet', (_prefs.getInt('wallet') ?? 0) - price);
    await _prefs.setStringList('hats', [...ownedHats, id]);
    return true;
  }

  /// Memes bought with likes (the first ones are free, see
  /// [MemeCharacter.price]).
  Set<String> get ownedMemes => (_prefs.getStringList('memes') ?? []).toSet();

  /// Returns false when you can't afford it.
  Future<bool> buyMeme(String id, int price) async {
    if (wallet < price || ownedMemes.contains(id)) return false;
    await _prefs.setInt('wallet', (_prefs.getInt('wallet') ?? 0) - price);
    await _prefs.setStringList('memes', [...ownedMemes, id]);
    return true;
  }

  // Small typed accessors for the daily systems (rewards, missions).
  int getInt(String key, [int fallback = 0]) => _prefs.getInt(key) ?? fallback;
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  bool getBool(String key) => _prefs.getBool(key) ?? false;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  // --------------------------------------------------- stats & trophies

  int stat(String key) => _prefs.getInt('stat_$key') ?? 0;
  Future<void> addStat(String key, int amount) =>
      _prefs.setInt('stat_$key', stat(key) + amount);

  Set<String> get trophies => (_prefs.getStringList('trophies') ?? []).toSet();
  Future<void> addTrophy(String id) =>
      _prefs.setStringList('trophies', [...trophies, id]);

  Set<String> get playedWith =>
      (_prefs.getStringList('playedWith') ?? []).toSet();
  Future<void> markPlayedWith(String characterId) =>
      _prefs.setStringList('playedWith', {...playedWith, characterId}.toList());

  /// Memes you've won at least one fight with.
  Set<String> get wonWith => (_prefs.getStringList('wonWith') ?? []).toSet();
  Future<void> markWonWith(String characterId) =>
      _prefs.setStringList('wonWith', {...wonWith, characterId}.toList());

  /// Best Arcade result per meme: rounds won (8 = champion).
  int arcadeBest(String characterId) =>
      _prefs.getInt('arcade_$characterId') ?? 0;
  Future<void> recordArcade(String characterId, int rounds) async {
    if (rounds > arcadeBest(characterId)) {
      await _prefs.setInt('arcade_$characterId', rounds);
    }
  }

  /// Arcade champion titles across all memes.
  int get arcadeTitles => _prefs
      .getKeys()
      .where((k) => k.startsWith('arcade_'))
      .where((k) => (_prefs.getInt(k) ?? 0) >= 8)
      .length;
}
