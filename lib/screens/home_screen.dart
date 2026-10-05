import 'dart:math';

import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../services/firebase_service.dart';
import '../services/local_store.dart';
import '../widgets/meme_text.dart';
import 'character_select_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

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
            colors: [Color(0xFF2B1B4A), Color(0xFF14121F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _OrbitingMemes(animation: _anim),
                  const SizedBox(height: 16),
                  const MemeText('Memes:', fontSize: 64),
                  const MemeText(
                    'the game',
                    fontSize: 36,
                    color: Color(0xFFFFD54F),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sopravvivi all\'orda di Normie, Cringe, Hater e Boomer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 36),
                  MemeButton(
                    label: 'Gioca',
                    icon: Icons.play_arrow,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CharacterSelectScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 28),
                  TextButton.icon(
                    onPressed: _editName,
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    label: Text(
                      'Giocatore: ${LocalStore.instance.playerName}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    FirebaseService.instance.available
                        ? '🟢 Online'
                        : '⚪ Offline (Firebase non configurato)',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four memes spinning around the title.
class _OrbitingMemes extends StatelessWidget {
  const _OrbitingMemes({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const chars = MemeCharacter.all;
    return SizedBox(
      width: 240,
      height: 180,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final items = [
            for (var i = 0; i < chars.length; i++)
              (animation.value * 2 * pi + i * pi / 2, chars[i]),
          ]..sort((a, b) => sin(a.$1).compareTo(sin(b.$1)));
          return Stack(
            children: [
              for (final (a, c) in items)
                Builder(
                  builder: (context) {
                    final r = 34 + (sin(a) + 1) / 2 * 18;
                    return Positioned(
                      left: 120 + cos(a) * 85 - r,
                      top: 80 + sin(a) * 40 - r,
                      child: CircleAvatar(
                        radius: r,
                        backgroundColor: c.color,
                        child: CircleAvatar(
                          radius: r - 3,
                          backgroundImage: AssetImage(
                            'assets/images/${c.spritePath}',
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
