import 'package:flutter/material.dart';

import '../../screens/game_screen.dart';
import '../../services/firebase_service.dart';
import '../../services/local_store.dart';
import '../../widgets/meme_text.dart';
import '../levels.dart';
import '../memes_game.dart';

enum _Upload { sending, done, failed, offline }

class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> {
  bool _newBest = false;
  _Upload _upload = _Upload.sending;

  MemesGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    final best = await LocalStore.instance.recordLevel(
      levelIndex: game.levelIndex,
      levelId: game.level.id,
      score: game.score,
      stars: game.stars,
    );
    if (!mounted) return;
    setState(() {
      _newBest = best;
      if (!FirebaseService.instance.available) _upload = _Upload.offline;
    });
    if (_upload == _Upload.offline) return;
    final ok = await FirebaseService.instance.submitScore(
      name: LocalStore.instance.playerName,
      levelId: game.level.id,
      characterId: game.character.id,
      score: game.score,
      likes: game.likes,
      kills: game.kills,
      seconds: game.elapsed.floor(),
    );
    if (mounted) setState(() => _upload = ok ? _Upload.done : _Upload.failed);
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = game.levelIndex + 1 < kLevels.length;
    return _Panel(
      children: [
        const MemeText('Virale!', fontSize: 46, color: Color(0xFFFFD54F)),
        MemeText('${game.level.name} completato', fontSize: 16),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < game.stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFFFD54F),
                size: 44,
                shadows: const [Shadow(blurRadius: 2)],
              ),
          ],
        ),
        _Stats(game: game),
        if (_newBest)
          const MemeText(
            'Nuovo record!',
            fontSize: 16,
            color: Color(0xFFFFD54F),
          ),
        const SizedBox(height: 6),
        Text(switch (_upload) {
          _Upload.sending => 'Invio in classifica…',
          _Upload.done => 'Punteggio inviato alla classifica ✅',
          _Upload.failed => 'Invio in classifica fallito ❌',
          _Upload.offline => 'Classifica online non disponibile (offline)',
        }, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            if (hasNext)
              _SmallButton(
                label: 'Prossimo livello',
                icon: Icons.skip_next,
                onPressed: () => _goto(context, game.levelIndex + 1),
              ),
            _SmallButton(
              label: 'Rigioca',
              icon: Icons.replay,
              color: const Color(0xFF7E57C2),
              onPressed: () => _goto(context, game.levelIndex),
            ),
            _SmallButton(
              label: 'Menu',
              icon: Icons.home,
              color: const Color(0xFF555066),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  void _goto(BuildContext context, int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(character: game.character, levelIndex: index),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.33, 0.33, 0.33, 0, 0, //
              0.33, 0.33, 0.33, 0, 0, //
              0.33, 0.33, 0.33, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: Image.asset(
              game.character.portraitAsset,
              height: 110,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const MemeText('Wasted', fontSize: 46, color: Color(0xFFE53935)),
        MemeText('${game.character.name} è stato ratioato', fontSize: 14),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _SmallButton(
              label: 'Riprova',
              icon: Icons.replay,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    character: game.character,
                    levelIndex: game.levelIndex,
                  ),
                ),
              ),
            ),
            _SmallButton(
              label: 'Menu',
              icon: Icons.home,
              color: const Color(0xFF555066),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final t = game.elapsed;
    final time = '${t ~/ 60}:${(t % 60).floor().toString().padLeft(2, '0')}';
    TableRow row(String a, String b) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Text(a, style: const TextStyle(color: Colors.white70)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Text(
            b,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    return SizedBox(
      width: 280,
      child: Table(
        children: [
          row('👍 Like ${game.likes}/${game.totalLikes}', '${game.likes * 10}'),
          row('💀 Nemici ${game.kills}', '${game.enemyScore}'),
          row('⏱ Tempo $time', '${game.timeBonus}'),
          row('❤️ Cuori ${game.player.hearts}', '${game.player.hearts * 100}'),
          row('⭐ TOTALE', '${game.score}'),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFFFF4FA3),
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: MemeText(label, fontSize: 16),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
      ),
    );
  }
}
