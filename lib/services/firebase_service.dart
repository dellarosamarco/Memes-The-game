import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class ScoreEntry {
  const ScoreEntry({
    required this.name,
    required this.characterId,
    required this.score,
    required this.kills,
    required this.seconds,
    required this.level,
  });

  final String name;
  final String characterId;
  final int score;
  final int kills;
  final int seconds;
  final int level;

  factory ScoreEntry.fromMap(Map<String, dynamic> m) => ScoreEntry(
    name: m['name'] as String? ?? '???',
    characterId: m['characterId'] as String? ?? '',
    score: (m['score'] as num?)?.toInt() ?? 0,
    kills: (m['kills'] as num?)?.toInt() ?? 0,
    seconds: (m['seconds'] as num?)?.toInt() ?? 0,
    level: (m['level'] as num?)?.toInt() ?? 1,
  );
}

/// Thin wrapper around Firebase. If Firebase isn't configured the game keeps
/// working offline and [available] stays false.
class FirebaseService {
  FirebaseService._();
  static final instance = FirebaseService._();

  bool available = false;
  String? initError;

  static const _scores = 'scores';

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      available = true;
    } catch (e) {
      initError = e.toString();
      debugPrint('Firebase disabilitato: $e');
    }
  }

  Future<bool> submitScore({
    required String name,
    required String characterId,
    required int score,
    required int kills,
    required int seconds,
    required int level,
  }) async {
    if (!available) return false;
    try {
      await FirebaseFirestore.instance.collection(_scores).add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'name': name,
        'characterId': characterId,
        'score': score,
        'kills': kills,
        'seconds': seconds,
        'level': level,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Invio punteggio fallito: $e');
      return false;
    }
  }

  /// Top scores, optionally filtered by character.
  Future<List<ScoreEntry>> topScores({String? characterId, int limit = 50}) {
    if (!available) return Future.value(const []);
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection(
      _scores,
    );
    if (characterId != null) {
      q = q.where('characterId', isEqualTo: characterId);
    }
    return q
        .orderBy('score', descending: true)
        .limit(limit)
        .get()
        .then((s) => s.docs.map((d) => ScoreEntry.fromMap(d.data())).toList());
  }
}
