import 'package:flutter/material.dart';

import '../../screens/game_screen.dart';
import '../../screens/leaderboard_screen.dart';
import '../../services/firebase_service.dart';
import '../../services/local_store.dart';
import '../../widgets/meme_text.dart';
import '../memes_game.dart';

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

enum _Upload { idle, sending, done, failed, offline }

class _GameOverOverlayState extends State<GameOverOverlay> {
  bool _newBest = false;
  _Upload _upload = _Upload.idle;

  MemesGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    final best = await LocalStore.instance.recordScore(
      game.character.id,
      game.score,
    );
    if (!mounted) return;
    setState(() {
      _newBest = best;
      _upload = FirebaseService.instance.available
          ? _Upload.sending
          : _Upload.offline;
    });
    if (_upload == _Upload.offline) return;
    final ok = await FirebaseService.instance.submitScore(
      name: LocalStore.instance.playerName,
      characterId: game.character.id,
      score: game.score,
      kills: game.kills,
      seconds: game.elapsed.floor(),
      level: game.level,
    );
    if (mounted) setState(() => _upload = ok ? _Upload.done : _Upload.failed);
  }

  @override
  Widget build(BuildContext context) {
    final c = game.character;
    final minutes = game.elapsed ~/ 60;
    final seconds = (game.elapsed % 60).floor().toString().padLeft(2, '0');
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.33, 0.33, 0.33, 0, 0, //
                  0.33, 0.33, 0.33, 0, 0, //
                  0.33, 0.33, 0.33, 0, 0, //
                  0, 0, 0, 1, 0,
                ]),
                child: Image.asset(
                  c.portraitAsset,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const MemeText('Wasted', fontSize: 52, color: Color(0xFFE53935)),
            MemeText('${c.name} è stato ratioato', fontSize: 16),
            const SizedBox(height: 18),
            MemeText('⭐ ${game.score}', fontSize: 40),
            if (_newBest)
              const MemeText(
                'Nuovo record personale!',
                fontSize: 16,
                color: Color(0xFFFFD54F),
              ),
            const SizedBox(height: 8),
            Text(
              '⏱ $minutes:$seconds   💀 ${game.kills}   LV ${game.level}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(switch (_upload) {
              _Upload.idle || _Upload.sending => 'Invio in classifica…',
              _Upload.done => 'Punteggio inviato alla classifica globale ✅',
              _Upload.failed => 'Invio in classifica fallito ❌',
              _Upload.offline => 'Classifica online non disponibile (offline)',
            }, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 24),
            MemeButton(
              label: 'Riprova',
              icon: Icons.replay,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => GameScreen(character: c)),
              ),
            ),
            const SizedBox(height: 12),
            MemeButton(
              label: 'Classifica',
              icon: Icons.leaderboard,
              color: const Color(0xFF7E57C2),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(initialCharacterId: c.id),
                ),
              ),
            ),
            const SizedBox(height: 12),
            MemeButton(
              label: 'Menu',
              icon: Icons.home,
              color: const Color(0xFF555066),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
