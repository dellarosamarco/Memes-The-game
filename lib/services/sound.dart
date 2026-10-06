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
    'boss_roar', 'like_1', 'like_2', 'like_3', 'like_4', 'like_5', //
    'land', 'skid',
  ];

  static String? _track;
  static bool _ready = false;

  static Future<void> init() async {
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([for (final e in effects) '$e.wav']);
      _ready = true;
    } catch (e) {
      debugPrint('Audio non disponibile: $e');
    }
  }

  static void play(String name, {double volume = 0.7}) {
    if (!_ready || !LocalStore.instance.sfxOn) return;
    FlameAudio.play('$name.wav', volume: volume).catchError((Object e) {
      debugPrint('sfx $name: $e');
      return AudioPlayer();
    });
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

  static void pauseMusic() {
    if (_ready) FlameAudio.bgm.pause().catchError((Object _) {});
  }

  static void resumeMusic() {
    if (_ready && LocalStore.instance.musicOn) {
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
