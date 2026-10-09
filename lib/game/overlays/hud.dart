import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/sound.dart';
import '../../widgets/pixel_ui.dart';
import '../fighter/fighter.dart';
import '../memes_game.dart';

/// In-fight HUD: both fighters' cards on top, touch controls at the bottom.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    // Repaint boundaries: the game canvas repaints every frame, the HUD
    // only when it changes (it used to cost half of the frame time).
    return RepaintBoundary(
      child: SafeArea(
        child: Stack(
          children: [
            RepaintBoundary(
              child: ValueListenableBuilder<int>(
                valueListenable: game.hudTick,
                builder: (context, _, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FighterCard(fighter: game.player),
                      const Spacer(),
                      PixelButton(
                        icon: 'pause',
                        color: PixelColor.grey,
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        onPressed: game.togglePause,
                      ),
                      const Spacer(),
                      FighterCard(fighter: game.cpu),
                    ],
                  ),
                ),
              ),
            ),
            RepaintBoundary(child: _TouchControls(game: game)),
          ],
        ),
      ),
    );
  }
}

/// Portrait, damage % (white → yellow → red) and remaining lives.
class FighterCard extends StatelessWidget {
  const FighterCard({super.key, required this.fighter});

  final Fighter fighter;

  static Color percentColor(double p) {
    if (p < 50) return Colors.white;
    if (p < 100) {
      return Color.lerp(Colors.white, const Color(0xFFFFD23F), (p - 50) / 50)!;
    }
    if (p < 160) {
      return Color.lerp(
        const Color(0xFFFFD23F),
        const Color(0xFFFF4D5E),
        (p - 100) / 60,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFF4D5E),
      const Color(0xFF9B1B30),
      min(1.0, (p - 160) / 100),
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final f = fighter;
    final tag = f.slot == 0 ? const Color(0xFFFF4F8E) : const Color(0xFF4FA8FF);
    final ko = !f.alive;
    return PixelPanel(
      px: 1.5,
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tag.withValues(alpha: .25),
              border: Border.all(color: tag, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Opacity(
              opacity: ko ? .35 : 1,
              child: Image.asset(
                f.character.portraitAsset,
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Shake(
                value: f.percent.floor(),
                child: PixelText(
                  ko ? '--' : '${f.percent.floor()}%',
                  size: 22,
                  color: percentColor(f.percent),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < max(f.stocks, 0); i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: tag,
                          shape: BoxShape.circle,
                          border: Border.all(color: kPlum, width: 1.5),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  PixelText(
                    f.isCpu ? 'CPU' : 'TU',
                    size: 10,
                    color: kPlum,
                    outline: false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shakes its child when [value] jumps (a hit landed).
class _Shake extends StatefulWidget {
  const _Shake({required this.value, required this.child});

  final int value;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void didUpdateWidget(_Shake old) {
    super.didUpdateWidget(old);
    if (widget.value > old.value) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (context, child) {
      final v = _ctrl.isAnimating ? _ctrl.value : 1.0;
      final dx = sin(v * pi * 8) * 4 * (1 - v);
      final s = 1 + .35 * (1 - v);
      return Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(
          scale: s,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}

class _TouchControls extends StatelessWidget {
  const _TouchControls({required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) {
    final input = game.player.input;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RepaintBoundary(child: _Joystick(input: input)),
            const Spacer(),
            SizedBox(
              width: 196,
              height: 170,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 6,
                    child: _HoldButton(
                      icon: 'shield',
                      label: 'Scudo',
                      size: 54,
                      color: 'grey',
                      onChanged: (v) => input.shield = v,
                    ),
                  ),
                  Positioned(
                    left: 64,
                    bottom: 84,
                    child: ValueListenableBuilder<int>(
                      valueListenable: game.hudTick,
                      builder: (_, _, _) => _HoldButton(
                        icon: 'bolt',
                        label: 'Speciale',
                        size: 60,
                        color: game.player.specialReady ? 'yellow' : 'grey',
                        progress: game.player.specialProgress,
                        onChanged: (v) {
                          input.special = v;
                          if (v) input.specialPressed = true;
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 60,
                    bottom: 0,
                    child: _HoldButton(
                      icon: 'fist',
                      label: 'Attacco',
                      size: 66,
                      color: 'pink',
                      onChanged: (v) {
                        input.attack = v;
                        if (v) input.attackPressed = true;
                      },
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 26,
                    child: _HoldButton(
                      icon: 'up',
                      label: 'Salto',
                      size: 64,
                      color: 'blue',
                      onChanged: (v) {
                        input.jump = v;
                        if (v) input.jumpPressed = true;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Virtual stick: drag anywhere on it; left/right move, up/down aim
/// attacks (and drop through platforms / fast fall).
class _Joystick extends StatefulWidget {
  const _Joystick({required this.input});

  final FighterInput input;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const _size = 132.0;
  static const _knob = 52.0;
  Offset _offset = Offset.zero;
  int? _pointer;

  void _set(Offset local) {
    const c = Offset(_size / 2, _size / 2);
    var d = local - c;
    const maxR = _size / 2 - _knob / 4;
    if (d.distance > maxR) d = d / d.distance * maxR;
    final nx = d.dx / maxR, ny = d.dy / maxR;
    final i = widget.input;
    final wasX = i.x.abs() > .5;
    i.x = nx.abs() < .25 ? 0 : nx.clamp(-1.0, 1.0);
    // Up/down only when they dominate: running a bit diagonally must not
    // turn a forward attack into an up attack.
    i.up = ny < -.5 && ny.abs() > nx.abs() * .8;
    i.down = ny > .5 && ny.abs() > nx.abs() * .8;
    if (!wasX && i.x.abs() > .5) Sound.haptic();
    setState(() => _offset = d);
  }

  void _release() {
    final i = widget.input;
    i.x = 0;
    i.up = false;
    i.down = false;
    _pointer = null;
    setState(() => _offset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _pointer = e.pointer;
        _set(e.localPosition);
      },
      onPointerMove: (e) {
        if (e.pointer == _pointer) _set(e.localPosition);
      },
      onPointerUp: (e) {
        if (e.pointer == _pointer) _release();
      },
      onPointerCancel: (e) {
        if (e.pointer == _pointer) _release();
      },
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _size - 8,
              height: _size - 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x553A2440),
                border: Border.all(color: const Color(0xAA3A2440), width: 3),
              ),
            ),
            Transform.translate(
              offset: _offset,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: pixelFrame(
                  'assets/images/ui/button_blue.png',
                  px: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round-ish pixel button reporting press/release (multi-touch friendly).
class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.label,
    required this.onChanged,
    this.size = 64,
    this.color = 'blue',
    this.progress = 1,
  });

  final String icon;
  final String label;
  final ValueChanged<bool> onChanged;
  final double size;
  final String color;
  final double progress;

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
      // (No Opacity here: it forced an offscreen layer every frame.)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.only(top: _down ? 5 : 0, bottom: _down ? 0 : 5),
            decoration: pixelFrame(
              'assets/images/ui/button_${widget.color}${_down ? '_down' : ''}.png',
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.progress < 1)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        value: widget.progress,
                        strokeWidth: 3,
                        color: const Color(0xFFFFD86A),
                        backgroundColor: const Color(0x333A2440),
                      ),
                    ),
                  ),
                PixelIcon(widget.icon, scale: widget.size / 24),
              ],
            ),
          ),
          PixelText(widget.label, size: 10, color: Colors.white),
        ],
      ),
    );
  }
}
