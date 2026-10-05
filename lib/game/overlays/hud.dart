import 'package:flutter/material.dart';

import '../../widgets/meme_text.dart';
import '../memes_game.dart';

class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  final MemesGame game;

  String _time(double s) {
    final m = s ~/ 60;
    final sec = (s % 60).floor();
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.hudTick,
      builder: (context, _, _) {
        final p = game.player;
        return SafeArea(
          child: Stack(
            children: [
              // Top bar: HP, XP, time, kills.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: game.character.color,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundImage: AssetImage(
                              'assets/images/${game.character.spritePath}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Bar(
                            value: p.hp / p.stats.maxHp,
                            color: const Color(0xFFE74C3C),
                            label:
                                '${p.hp.ceil()} / ${p.stats.maxHp.round()} HP',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: game.togglePause,
                          icon: const Icon(Icons.pause),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _Bar(
                      value: game.xp / game.xpToNext,
                      color: const Color(0xFF4FC3F7),
                      label: 'LV ${game.level}',
                      height: 12,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MemeText('⏱ ${_time(game.elapsed)}', fontSize: 18),
                        MemeText('💀 ${game.kills}', fontSize: 18),
                        MemeText('⭐ ${game.score}', fontSize: 18),
                      ],
                    ),
                  ],
                ),
              ),
              // Special button bottom-right.
              Positioned(
                right: 24,
                bottom: 28,
                child: _SpecialButton(game: game),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.color,
    required this.label,
    this.height = 18,
  });

  final double value;
  final Color color;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1),
              child: ColoredBox(color: color),
            ),
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height * 0.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialButton extends StatelessWidget {
  const _SpecialButton({required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final p = game.player;
    final ready = p.specialReady;
    return GestureDetector(
      onTap: p.useSpecial,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: p.specialProgress,
                    strokeWidth: 7,
                    backgroundColor: Colors.black45,
                    color: ready ? const Color(0xFFFFD54F) : Colors.white54,
                  ),
                ),
                AnimatedScale(
                  scale: ready ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 200),
                  child: Opacity(
                    opacity: ready ? 1 : 0.5,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: game.character.color,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage(
                          'assets/images/${game.character.spritePath}',
                        ),
                      ),
                    ),
                  ),
                ),
                if (!ready)
                  MemeText('${(p.specialTimer).ceil()}', fontSize: 28),
              ],
            ),
          ),
          const SizedBox(height: 4),
          MemeText(game.character.specialName, fontSize: 12),
        ],
      ),
    );
  }
}
