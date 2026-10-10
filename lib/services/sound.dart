import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_store.dart';

/// Chiptune sound effects, music loops and haptics (assets/audio/, made by
/// tool/generate_audio.py). Every call is fire-and-forget and never throws:
/// audio is a nice-to-have (e.g. browsers block it before the first tap).
class Sound {
  Sound._();

  static const effects = [
    'jump', 'double_jump', 'like', 'stomp', 'hurt', 'spring', 'special', //
    'checkpoint', 'finish', 'block', 'click', 'gameover', 'boss_hit',
    'boss_roar', 'land', 'skid', 'hit_light', 'hit_heavy', 'charge', 'ko',
    'whoosh',
  ];

  /// Effects that can overlap a lot in a fight get more voices.
  static const _busy = {'hit_light', 'hit_heavy', 'land', 'whoosh', 'jump'};

  /// Ready-made players per effect, reused round-robin. Creating a new
  /// player for every sound (FlameAudio.play) costs several platform calls
  /// and stutters the game on phones in the middle of a fight.
  static final Map<String, List<AudioPlayer>> _pools = {};
  static final Map<String, int> _next = {};
  static final Set<AudioPlayer> _loaded = {};

  static String? _track;
  static bool _ready = false;

  static Future<void> init() async {
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([for (final e in effects) '$e.wav']);
      final context = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      for (final e in effects) {
        _pools[e] = [
          for (var i = 0; i < (_busy.contains(e) ? 4 : 2); i++)
            AudioPlayer()..audioCache = FlameAudio.audioCache,
        ];
        _next[e] = 0;
      }
      // In the background: never hold up the app start.
      for (final pool in _pools.entries) {
        for (final p in pool.value) {
          _prepare(p, pool.key, context);
        }
      }
      _ready = true;
    } catch (e) {
      debugPrint('Audio non disponibile: $e');
    }
  }

  static Future<void> _prepare(
    AudioPlayer p,
    String name,
    AudioContext context,
  ) async {
    try {
      await p.setAudioContext(context);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setSource(AssetSource('$name.wav'));
      _loaded.add(p);
    } catch (e) {
      debugPrint('sfx $name: $e');
    }
  }

  /// [pitch] > 0 plays the sound slightly faster/slower (e.g. 1.08):
  /// varied hits don't sound like a machine gun.
  static void play(String name, {double volume = 0.7, double pitch = 1}) {
    if (!_ready || !LocalStore.instance.sfxOn) return;
    final pool = _pools[name];
    if (pool == null) return;
    // A free voice if there is one, else the oldest gets cut.
    var i = _next[name]!;
    for (var k = 0; k < pool.length; k++) {
      final j = (i + k) % pool.length;
      if (pool[j].state != PlayerState.playing) {
        i = j;
        break;
      }
    }
    _next[name] = (i + 1) % pool.length;
    final p = pool[i];
    if (!_loaded.contains(p)) return;
    Future<void> start() async {
      if (p.state == PlayerState.playing) await p.stop();
      await p.setVolume(volume);
      await p.setPlaybackRate(pitch);
      await p.resume();
    }

    start().catchError((Object e) => debugPrint('sfx $name: $e'));
  }

  /// Plays a looping track: 'menu', 'level' or 'boss'.
  static void music(String track) {
    if (!_ready) return;
    if (!LocalStore.instance.musicOn) {
      _track = track;
      return;
    }
    if (_track == track && FlameAudio.bgm.isPlaying) return;
    _track = track;
    FlameAudio.bgm.play('music_$track.wav', volume: 0.45).catchError((
      Object e,
    ) {
      debugPrint('music $track: $e');
      // Typically blocked before the first user gesture on the web.
      _track = null;
    });
  }

  /// Retries the current track (call it after a user gesture).
  static void ensureMusic(String fallback) => music(_track ?? fallback);

  static void stopMusic() {
    if (!_ready) return;
    _track = null;
    FlameAudio.bgm.stop().catchError((Object _) {});
  }

  /// Set while the game is paused: coming back to the app must not restart
  /// the music under the pause menu.
  static bool held = false;

  static void pauseMusic() {
    if (_ready) FlameAudio.bgm.pause().catchError((Object _) {});
  }

  static void resumeMusic() {
    if (_ready && !held && LocalStore.instance.musicOn) {
      FlameAudio.bgm.resume().catchError((Object _) {});
    }
  }

  static Future<void> setMusicOn(bool on) async {
    await LocalStore.instance.setMusicOn(on);
    if (on) {
      final t = _track ?? 'menu';
      _track = null;
      music(t);
    } else {
      final t = _track;
      stopMusic();
      _track = t;
    }
  }

  static void haptic({bool strong = false}) {
    if (kIsWeb || !LocalStore.ready || !LocalStore.instance.hapticsOn) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
  }
}
