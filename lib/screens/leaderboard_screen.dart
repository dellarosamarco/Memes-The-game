import 'package:flutter/material.dart';

import '../game/levels.dart';
import '../models/meme_character.dart';
import '../services/firebase_service.dart';
import '../services/local_store.dart';
import '../widgets/meme_text.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, this.initialLevelId});

  final String? initialLevelId;

  @override
  Widget build(BuildContext context) {
    final initial = initialLevelId == null
        ? 0
        : kLevels.indexWhere((l) => l.id == initialLevelId);
    return DefaultTabController(
      length: kLevels.length,
      initialIndex: initial < 0 ? 0 : initial,
      child: Scaffold(
        backgroundColor: const Color(0xFF14121F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF221D33),
          foregroundColor: Colors.white,
          toolbarHeight: 44,
          title: const MemeText('Classifica', fontSize: 22),
          centerTitle: true,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFFFF4FA3),
            tabs: [for (final l in kLevels) Tab(text: l.name.toUpperCase())],
          ),
        ),
        body: TabBarView(
          children: [for (final l in kLevels) _ScoreList(levelId: l.id)],
        ),
      ),
    );
  }
}

class _ScoreList extends StatefulWidget {
  const _ScoreList({required this.levelId});

  final String levelId;

  @override
  State<_ScoreList> createState() => _ScoreListState();
}

class _ScoreListState extends State<_ScoreList> {
  late Future<List<ScoreEntry>> _future = _load();

  Future<List<ScoreEntry>> _load() =>
      FirebaseService.instance.topScores(levelId: widget.levelId);

  @override
  Widget build(BuildContext context) {
    if (!FirebaseService.instance.available) {
      final best = LocalStore.instance.bestScore(widget.levelId);
      return _message(
        'Classifica online non disponibile: Firebase non è configurato.\n\n'
        'Il tuo record su questo livello: $best',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: FutureBuilder<List<ScoreEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _message('Errore nel caricamento:\n${snap.error}');
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return _message('Ancora nessun punteggio. Sii il primo!');
          }
          final me = LocalStore.instance.playerName;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e = list[i];
              final c = MemeCharacter.byId(e.characterId);
              final medal = switch (i) {
                0 => '🥇',
                1 => '🥈',
                2 => '🥉',
                _ => '#${i + 1}',
              };
              return Card(
                color: e.name == me
                    ? const Color(0xFF3D2D5C)
                    : const Color(0xFF221D33),
                child: ListTile(
                  leading: SizedBox(
                    width: 86,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          child: Text(
                            medal,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Image.asset(
                          c.portraitAsset,
                          width: 44,
                          height: 44,
                          filterQuality: FilterQuality.none,
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    e.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${c.name} · 👍 ${e.likes} · 💀 ${e.kills} · '
                    '⏱ ${e.seconds ~/ 60}:${(e.seconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: MemeText('${e.score}', fontSize: 20),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(String text) => ListView(
    children: [
      const SizedBox(height: 60),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    ],
  );
}
