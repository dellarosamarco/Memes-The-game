import 'package:flutter/material.dart';

import '../../widgets/meme_text.dart';
import '../memes_game.dart';

class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: game.hudTick,
            builder: (context, _, _) => _TopBar(game: game),
          ),
          _TouchControls(game: game),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final p = game.player;
    final t = game.elapsed;
    final time = '${t ~/ 60}:${(t % 60).floor().toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          for (var i = 0; i < game.character.hearts; i++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i < p.hearts ? Icons.favorite : Icons.favorite_border,
                color: const Color(0xFFFF4F6A),
                size: 26,
                shadows: const [Shadow(blurRadius: 2)],
              ),
            ),
          const SizedBox(width: 14),
          MemeText('👍 ${game.likes}/${game.totalLikes}', fontSize: 18),
          const Spacer(),
          MemeText(game.level.name, fontSize: 14),
          const Spacer(),
          MemeText('⏱ $time', fontSize: 18),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: game.togglePause,
            icon: const Icon(Icons.pause),
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _TouchControls extends StatelessWidget {
  const _TouchControls({required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final input = game.input;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _HoldButton(
              icon: Icons.arrow_back_rounded,
              onChanged: (v) => input.left = v,
            ),
            const SizedBox(width: 14),
            _HoldButton(
              icon: Icons.arrow_forward_rounded,
              onChanged: (v) => input.right = v,
            ),
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: game.hudTick,
              builder: (context, _, _) => _SpecialButton(game: game),
            ),
            const SizedBox(width: 16),
            _HoldButton(
              icon: Icons.arrow_upward_rounded,
              size: 84,
              color: const Color(0xCCFF4FA3),
              onChanged: (v) {
                if (v) {
                  input.pressJump();
                } else {
                  input.jump = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A button that reports press/release, with multi-touch support.
class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.onChanged,
    this.size = 72,
    this.color = const Color(0x66FFFFFF),
  });

  final IconData icon;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color color;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 60),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black54, width: 3),
          ),
          child: Icon(widget.icon, color: Colors.white, size: widget.size * .5),
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
    return Listener(
      onPointerDown: (_) => game.input.specialQueued = true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: p.specialProgress,
                    strokeWidth: 6,
                    backgroundColor: Colors.black45,
                    color: ready ? const Color(0xFFFFD54F) : Colors.white54,
                  ),
                ),
                Opacity(
                  opacity: ready ? 1 : 0.45,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: game.character.color,
                    child: ClipOval(
                      child: Image.asset(
                        game.character.portraitAsset,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
                if (!ready) MemeText('${p.specialTimer.ceil()}', fontSize: 24),
              ],
            ),
          ),
          MemeText(game.character.specialName, fontSize: 10),
        ],
      ),
    );
  }
}
