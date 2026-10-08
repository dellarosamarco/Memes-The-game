import 'package:flutter/material.dart';

import '../game/level.dart';
import '../game/level_gen.dart';
import '../models/meme_character.dart';
import '../services/firebase_service.dart';
import '../services/name_filter.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';

/// Global top scores of one level at a time (pick it with the arrows).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.initialLevel});

  final int? initialLevel;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late int _level =
      widget.initialLevel ??
      (LocalStore.instance.unlockedLevels - 1).clamp(0, kLevelCount - 1);
  late Future<List<ScoreEntry>> _future = _load();

  String get _id => 'L${(_level + 1).toString().padLeft(3, '0')}';

  Future<List<ScoreEntry>> _load() =>
      FirebaseService.instance.topScores(levelId: _id);

  void _go(int delta) {
    setState(() {
      _level = (_level + delta).clamp(0, kLevelCount - 1);
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final world = _level ~/ kLevelsPerWorld;
    return Scaffold(
      body: PixelBackdrop(
        ground: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    PixelButton(
                      icon: 'left',
                      color: PixelColor.grey,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(child: PixelText('Classifica', size: 26)),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PixelButton(
                      label: '-10',
                      height: 44,
                      color: PixelColor.purple,
                      fontSize: 14,
                      onPressed: () => _go(-10),
                    ),
                    const SizedBox(width: 6),
                    PixelButton(
                      icon: 'left',
                      height: 44,
                      color: PixelColor.purple,
                      onPressed: () => _go(-1),
                    ),
                    SizedBox(
                      width: 230,
                      child: Column(
                        children: [
                          PixelText(
                            'Livello ${world + 1}-${_level % kLevelsPerWorld + 1}',
                            size: 20,
                          ),
                          PixelText(
                            LevelTheme.values[world].worldName,
                            size: 12,
                            color: const Color(0xFFFFE07A),
                          ),
                        ],
                      ),
                    ),
                    PixelButton(
                      icon: 'right',
                      height: 44,
                      color: PixelColor.purple,
                      onPressed: () => _go(1),
                    ),
                    const SizedBox(width: 6),
                    PixelButton(
                      label: '+10',
                      height: 44,
                      color: PixelColor.purple,
                      fontSize: 14,
                      onPressed: () => _go(10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PixelPanel(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                    child: _body(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (!FirebaseService.instance.available) {
      return _message(
        'Classifica online non disponibile:\nFirebase non è configurato.\n\n'
        'Il tuo record su questo livello: '
        '${LocalStore.instance.bestScore(_id)}',
      );
    }
    return FutureBuilder<List<ScoreEntry>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return _message('Errore: ${snap.error}');
        final list = snap.data!;
        if (list.isEmpty) return _message('Nessun punteggio. Sii il primo!');
        final me = LocalStore.instance.playerName;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i];
            final c = MemeCharacter.byId(e.characterId);
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: e.name == me ? const Color(0x33FF82B4) : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: i < 3
                        ? const PixelIcon('trophy', scale: 2)
                        : PixelText(
                            '${i + 1}',
                            size: 16,
                            color: kPlum,
                            outline: false,
                          ),
                  ),
                  Image.asset(
                    c.portraitAsset,
                    width: 36,
                    height: 36,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PixelText(
                      NameFilter.display(e.name),
                      size: 16,
                      color: kPlum,
                      outline: false,
                      align: TextAlign.left,
                    ),
                  ),
                  PixelText(
                    '${e.score}',
                    size: 18,
                    color: const Color(0xFFFF82B4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _message(String text) =>
      Center(child: PixelText(text, size: 15, color: kPlum, outline: false));
}
