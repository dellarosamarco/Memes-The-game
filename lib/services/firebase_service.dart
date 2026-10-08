import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class ScoreEntry {
  const ScoreEntry({
    required this.name,
    required this.levelId,
    required this.characterId,
    required this.score,
    required this.likes,
    required this.kills,
    required this.seconds,
  });

  final String name;
  final String levelId;
  final String characterId;
  final int score;
  final int likes;
  final int kills;
  final int seconds;

  factory ScoreEntry.fromMap(Map<String, dynamic> m) => ScoreEntry(
    name: m['name'] as String? ?? '???',
    levelId: m['levelId'] as String? ?? '',
    characterId: m['characterId'] as String? ?? '',
    score: (m['score'] as num?)?.toInt() ?? 0,
    likes: (m['likes'] as num?)?.toInt() ?? 0,
    kills: (m['kills'] as num?)?.toInt() ?? 0,
    seconds: (m['seconds'] as num?)?.toInt() ?? 0,
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
    required String levelId,
    required String characterId,
    required int score,
    required int likes,
    required int kills,
    required int seconds,
  }) async {
    if (!available) return false;
    try {
      await FirebaseFirestore.instance.collection(_scores).add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'name': name,
        'levelId': levelId,
        'characterId': characterId,
        'score': score,
        'likes': likes,
        'kills': kills,
        'seconds': seconds,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Invio punteggio fallito: $e');
      return false;
    }
  }

  /// Deletes every score this player sent and their anonymous account
  /// ("Cancella i miei dati"). Returns false when offline or on errors.
  Future<bool> deleteMyData() async {
    if (!available) return false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return true;
      final mine = await FirebaseFirestore.instance
          .collection(_scores)
          .where('uid', isEqualTo: user.uid)
          .get();
      for (final d in mine.docs) {
        await d.reference.delete();
      }
      await user.delete();
      await FirebaseAuth.instance.signInAnonymously();
      return true;
    } catch (e) {
      debugPrint('Cancellazione dati fallita: $e');
      return false;
    }
  }

  /// Top scores of a level.
  Future<List<ScoreEntry>> topScores({
    required String levelId,
    int limit = 50,
  }) {
    if (!available) return Future.value(const []);
    final q = FirebaseFirestore.instance
        .collection(_scores)
        .where('levelId', isEqualTo: levelId);
    return q
        .orderBy('score', descending: true)
        .limit(limit)
        .get()
        .then((s) => s.docs.map((d) => ScoreEntry.fromMap(d.data())).toList());
  }
}
