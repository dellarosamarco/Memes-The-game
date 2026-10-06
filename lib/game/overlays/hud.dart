import 'package:flutter/material.dart';

import '../../services/sound.dart';
import '../../widgets/pixel_ui.dart';
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
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixelPanel(
            px: 1.5,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < game.character.hearts; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: PixelIcon(
                      i < p.hearts ? 'heart' : 'heart_empty',
                      scale: 2,
                    ),
                  ),
                const SizedBox(width: 10),
                const PixelIcon('like', scale: 1.5),
                const SizedBox(width: 4),
                PixelText(
                  '${game.likes}/${game.totalLikes}',
                  size: 15,
                  color: kPlum,
                  outline: false,
                ),
              ],
            ),
          ),
          if (p.power != null) ...[
            const SizedBox(width: 8),
            PixelPanel(
              px: 1.5,
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetIcon(
                    asset: 'assets/images/sprites/powerups.png',
                    index: p.power!.index,
                    frames: 4,
                    size: 16,
                    scale: 1.6,
                  ),
                  const SizedBox(width: 6),
                  PixelText(
                    '${p.powerTime.ceil()}s',
                    size: 14,
                    color: kPlum,
                    outline: false,
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          PixelPanel(
            px: 1.5,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelText(
                  game.level.name,
                  size: 15,
                  color: const Color(0xFFFF82B4),
                  outline: false,
                ),
                const SizedBox(width: 12),
                const PixelIcon('clock', scale: 1.5),
                const SizedBox(width: 4),
                PixelText(time, size: 15, color: kPlum, outline: false),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PixelButton(
            icon: 'pause',
            color: PixelColor.grey,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: game.togglePause,
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _DPad(input: input),
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: game.hudTick,
              builder: (context, _, _) => _SpecialButton(game: game),
            ),
            const SizedBox(width: 12),
            _HoldButton(
              icon: 'up',
              size: 78,
              color: 'pink',
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

/// Left/right pad: one touch zone you can slide your thumb across to change
/// direction without lifting it (much better than two separate buttons).
class _DPad extends StatefulWidget {
  const _DPad({required this.input});

  final GameInput input;

  @override
  State<_DPad> createState() => _DPadState();
}

class _DPadState extends State<_DPad> {
  static const _size = 70.0;
  static const _gap = 8.0;
  static const _width = _size * 2 + _gap;

  /// Horizontal position of each finger on the pad.
  final Map<int, double> _fingers = {};

  void _update() {
    var left = false;
    var right = false;
    for (final x in _fingers.values) {
      if (x < _width / 2) {
        left = true;
      } else {
        right = true;
      }
    }
    if (left != widget.input.left || right != widget.input.right) {
      if (left || right) Sound.haptic();
      widget.input
        ..left = left
        ..right = right;
      setState(() {});
    }
  }

  void _set(PointerEvent e) {
    _fingers[e.pointer] = e.localPosition.dx;
    _update();
  }

  void _lift(PointerEvent e) {
    _fingers.remove(e.pointer);
    _update();
  }

  Widget _half(String icon, bool down) => Container(
    width: _size,
    height: _size,
    padding: EdgeInsets.only(top: down ? 6 : 0, bottom: down ? 0 : 6),
    decoration: pixelFrame(
      'assets/images/ui/button_blue${down ? '_down' : ''}.png',
    ),
    child: Center(child: PixelIcon(icon, scale: 3)),
  );

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _set,
      onPointerMove: _set,
      onPointerUp: _lift,
      onPointerCancel: _lift,
      child: Opacity(
        opacity: 0.85,
        child: Padding(
          // Generous invisible margin: thumbs are not precise.
          padding: const EdgeInsets.only(top: 24, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _half('left', widget.input.left),
              const SizedBox(width: _gap),
              _half('right', widget.input.right),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pixel button that reports press/release, with multi-touch support.
class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.onChanged,
    this.size = 66,
    this.color = 'blue',
  });

  final String icon;
  final ValueChanged<bool> onChanged;
  final double size;
  final String color;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    if (v) Sound.haptic();
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Opacity(
        opacity: 0.85,
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.only(top: _down ? 6 : 0, bottom: _down ? 0 : 6),
          decoration: pixelFrame(
            'assets/images/ui/button_${widget.color}'
            '${_down ? '_down' : ''}.png',
          ),
          child: Center(child: PixelIcon(widget.icon, scale: 3)),
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
      child: Opacity(
        opacity: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
              decoration: pixelFrame(
                ready
                    ? 'assets/images/ui/button_yellow.png'
                    : 'assets/images/ui/button_grey_down.png',
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: ready ? 1 : .4,
                    child: Image.asset(
                      game.character.portraitAsset,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  if (!ready)
                    PixelText('${p.specialTimer.ceil()}', size: 22)
                  else
                    const Align(
                      alignment: Alignment.topRight,
                      child: PixelIcon('bolt', scale: 1.5),
                    ),
                ],
              ),
            ),
            PixelText(game.character.specialName, size: 10),
          ],
        ),
      ),
    );
  }
}
