import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../services/firebase_service.dart';
import '../services/local_store.dart';
import '../widgets/meme_text.dart';
import '../widgets/sprite_view.dart';
import 'character_select_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _editName() async {
    final ctrl = TextEditingController(text: LocalStore.instance.playerName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Il tuo nome'),
        content: TextField(
          controller: ctrl,
          maxLength: 16,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'xX_MemeLord_Xx'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      await LocalStore.instance.setPlayerName(trimmed);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FD3FF), Color(0xFFD6F2FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // A grass strip with the four memes standing on it.
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final c in MemeCharacter.all)
                          CharacterSpriteView(character: c, scale: 1.6),
                      ],
                    ),
                    Container(height: 10, color: const Color(0xFF58C448)),
                    Container(height: 22, color: const Color(0xFF966038)),
                  ],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MemeText('Memes:', fontSize: 52),
                      const MemeText(
                        'the game',
                        fontSize: 30,
                        color: Color(0xFFFFD54F),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          MemeButton(
                            label: 'Gioca',
                            icon: Icons.play_arrow,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CharacterSelectScreen(),
                              ),
                            ),
                          ),
                          MemeButton(
                            label: 'Classifica',
                            icon: Icons.leaderboard,
                            color: const Color(0xFF7E57C2),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LeaderboardScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _editName,
                        icon: const Icon(Icons.edit, color: Colors.black87),
                        label: Text(
                          'Giocatore: ${LocalStore.instance.playerName}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        FirebaseService.instance.available
                            ? '🟢 Online'
                            : '⚪ Offline (Firebase non configurato)',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
