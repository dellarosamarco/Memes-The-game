import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../services/firebase_service.dart';
import '../services/local_store.dart';
import '../widgets/meme_text.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, this.initialCharacterId});

  final String? initialCharacterId;

  @override
  Widget build(BuildContext context) {
    const chars = MemeCharacter.all;
    final initial = initialCharacterId == null
        ? 0
        : chars.indexWhere((c) => c.id == initialCharacterId) + 1;
    return DefaultTabController(
      length: chars.length + 1,
      initialIndex: initial.clamp(0, chars.length),
      child: Scaffold(
        backgroundColor: const Color(0xFF14121F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF221D33),
          foregroundColor: Colors.white,
          title: const MemeText('Classifica', fontSize: 24),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFFFF4FA3),
            tabs: [
              const Tab(text: 'TUTTI'),
              for (final c in chars)
                Tab(
                  icon: CircleAvatar(
                    radius: 14,
                    backgroundImage: AssetImage(
                      'assets/images/${c.spritePath}',
                    ),
                  ),
                  text: c.name.split(' ').first,
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _ScoreList(characterId: null),
            for (final c in chars) _ScoreList(characterId: c.id),
          ],
        ),
      ),
    );
  }
}

class _ScoreList extends StatefulWidget {
  const _ScoreList({required this.characterId});

  final String? characterId;

  @override
  State<_ScoreList> createState() => _ScoreListState();
}

class _ScoreListState extends State<_ScoreList> {
  late Future<List<ScoreEntry>> _future = _load();

  Future<List<ScoreEntry>> _load() =>
      FirebaseService.instance.topScores(characterId: widget.characterId);

  @override
  Widget build(BuildContext context) {
    if (!FirebaseService.instance.available) {
      return _offline();
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
                    width: 84,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            medal,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(
                            'assets/images/${c.spritePath}',
                          ),
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
                    '${c.name} · LV ${e.level} · 💀 ${e.kills} · '
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
      const SizedBox(height: 120),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    ],
  );

  Widget _offline() {
    final chars = widget.characterId == null
        ? MemeCharacter.all
        : [MemeCharacter.byId(widget.characterId!)];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Classifica online non disponibile: Firebase non è configurato.\n'
          'Ecco i tuoi record personali.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 16),
        for (final c in chars)
          Card(
            color: const Color(0xFF221D33),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/${c.spritePath}'),
              ),
              title: Text(c.name, style: const TextStyle(color: Colors.white)),
              trailing: MemeText(
                '${LocalStore.instance.bestScore(c.id)}',
                fontSize: 20,
              ),
            ),
          ),
      ],
    );
  }
}
