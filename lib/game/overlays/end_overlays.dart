import 'dart:math';

import 'package:flutter/material.dart';

import '../../screens/game_screen.dart';
import '../../services/achievements.dart';
import '../../services/firebase_service.dart';
import '../../services/local_store.dart';
import '../../widgets/pixel_ui.dart';
import '../level_gen.dart';
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
    game.recordRunStats();
    Achievements.unlock('first_win');
    if (game.stars == 3) Achievements.unlock('three_stars');
    if (!game.damageTaken) Achievements.unlock('no_damage');
    if (game.elapsed < 30) Achievements.unlock('speedrun');
    if (game.level.hasBoss) Achievements.unlock('boss');
    Achievements.checkStats();
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
    final hasNext = game.levelIndex + 1 < kLevelCount;
    return _Panel(
      children: [
        PixelText(
          game.level.hasBoss ? 'Mondo completato!' : 'Virale!',
          size: 34,
          color: const Color(0xFFFF82B4),
        ),
        PixelText(
          'Livello ${game.level.name} superato',
          size: 14,
          color: kPlum,
          outline: false,
        ),
        const SizedBox(height: 6),
        PixelStars(game.stars, scale: 3.5),
        const SizedBox(height: 6),
        _Stats(game: game),
        if (_newBest)
          const PixelText('Nuovo record!', size: 15, color: Color(0xFFFFC94A)),
        PixelText(
          switch (_upload) {
            _Upload.sending => 'Invio in classifica...',
            _Upload.done => 'Inviato alla classifica!',
            _Upload.failed => 'Invio in classifica fallito',
            _Upload.offline => 'Classifica offline',
          },
          size: 11,
          color: const Color(0xFF9A8FB0),
          outline: false,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (hasNext)
              PixelButton(
                label: 'Avanti',
                icon: 'play',
                color: PixelColor.mint,
                onPressed: () => _goto(context, game.levelIndex + 1),
              ),
            PixelButton(
              icon: 'replay',
              color: PixelColor.purple,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => _goto(context, game.levelIndex),
            ),
            PixelButton(
              icon: 'home',
              color: PixelColor.grey,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  /// "Press F to pay respects": every press rains a few Fs.
  final List<(double, double, double)> _fs = [];
  int _respects = 0;
  late final _ticker = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  )..forward();
  final _rnd = Random();

  double get _now =>
      _ticker.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0;

  void _payRespects() {
    LocalStore.instance.addStat('respects', 1).then((_) {
      Achievements.checkStats();
    });
    setState(() {
      _respects++;
      for (var i = 0; i < 4; i++) {
        _fs.add((_rnd.nextDouble(), _now, 14 + _rnd.nextDouble() * 22));
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Stack(
      children: [
        _Panel(
          children: [
            Opacity(
              opacity: .6,
              child: Image.asset(
                game.character.portraitAsset,
                height: 90,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 6),
            const PixelText('Oh no!', size: 36, color: Color(0xFFFF6F8A)),
            PixelText(
              '${game.character.name} è stato ratioato',
              size: 14,
              color: kPlum,
              outline: false,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                PixelButton(
                  label: 'Riprova',
                  icon: 'replay',
                  color: PixelColor.pink,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        character: game.character,
                        levelIndex: game.levelIndex,
                      ),
                    ),
                  ),
                ),
                PixelButton(
                  label: 'F',
                  color: PixelColor.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  onPressed: _payRespects,
                ),
                PixelButton(
                  icon: 'home',
                  color: PixelColor.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PixelText(
              _respects == 0
                  ? 'Premi F per rendere omaggio'
                  : 'Omaggi resi: $_respects',
              size: 11,
              color: const Color(0xFF9A8FB0),
              outline: false,
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                final h = MediaQuery.sizeOf(context).height;
                final w = MediaQuery.sizeOf(context).width;
                return Stack(
                  children: [
                    for (final (fx, t0, size) in _fs)
                      if ((_now - t0) / 1000 * 220 < h + 40)
                        Positioned(
                          left: fx * (w - 30),
                          top: -40 + (_now - t0) / 1000 * 220,
                          child: PixelText('F', size: size),
                        ),
                  ],
                );
              },
            ),
          ),
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
      color: const Color(0x993A2440),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: PixelPanel(
          width: 420,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
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
    Widget row(String icon, String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(width: 26, child: PixelIcon(icon, scale: 1.5)),
          Expanded(
            child: PixelText(
              a,
              size: 13,
              color: kPlum,
              outline: false,
              align: TextAlign.left,
              bold: false,
            ),
          ),
          PixelText(b, size: 14, color: kPlum, outline: false),
        ],
      ),
    );
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          row(
            'like',
            'Like ${game.likes}/${game.totalLikes}',
            '${game.likeScore}',
          ),
          row('skull', 'Nemici ${game.kills}', '${game.enemyScore}'),
          row('clock', 'Tempo $time', '${game.timeBonus}'),
          row(
            'heart',
            'Cuori ${game.player.hearts}',
            '${game.player.hearts * 100}',
          ),
          const Divider(color: Color(0x553A2440), height: 8),
          row('star', 'Totale', '${game.score}'),
          if (game.walletGain != game.likes)
            row('like', 'Bonus negozio', '+${game.walletGain}'),
        ],
      ),
    );
  }
}
