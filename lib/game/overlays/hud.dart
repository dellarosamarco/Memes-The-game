import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/local_store.dart';
import '../../services/sound.dart';
import '../../widgets/pixel_ui.dart';
import '../fighter/fighter.dart';
import '../memes_game.dart';
import '../../l10n/l10n.dart';

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
                    f.isCpu ? tr('hud.cpu', 'CPU') : tr('hud.you', 'TU'),
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
    final w = MediaQuery.sizeOf(context).width;
    return Stack(
      children: [
        // Floating stick: anywhere on the left part of the screen.
        Positioned(
          left: 0,
          top: 64,
          bottom: 0,
          width: w * .45,
          child: RepaintBoundary(child: _Joystick(input: input)),
        ),
        // Buttons: the whole lower right of the screen is theirs.
        Positioned(
          right: 0,
          top: 64,
          bottom: 0,
          width: max(240.0, w * .42),
          child: _ButtonPad(game: game),
        ),
      ],
    );
  }
}

/// The three action buttons. A touch anywhere on the pad goes to the
/// nearest button, so a thumb that lands a bit off still counts.
class _ButtonPad extends StatefulWidget {
  const _ButtonPad({required this.game});

  final MemesGame game;

  @override
  State<_ButtonPad> createState() => _ButtonPadState();
}

class _ButtonPadState extends State<_ButtonPad> {
  static const _special = 0, _attack = 1, _jump = 2;
  final _keys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final _pointers = <int, int>{};
  final _down = [false, false, false];

  void _apply(int b, bool v) {
    final i = widget.game.player.input;
    switch (b) {
      case _special:
        i.special = v;
        if (v) i.specialPressed = true;
      case _attack:
        i.attack = v;
        if (v) i.attackPressed = true;
      case _jump:
        i.jump = v;
        if (v) i.jumpPressed = true;
    }
  }

  void _refresh() {
    for (var b = 0; b < 3; b++) {
      final v = _pointers.containsValue(b);
      if (v == _down[b]) continue;
      _down[b] = v;
      if (v) Sound.haptic();
      _apply(b, v);
    }
    setState(() {});
  }

  int _nearest(Offset global) {
    var best = _attack;
    var bestD = double.infinity;
    for (var b = 0; b < 3; b++) {
      final box = _keys[b].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final c = box.localToGlobal(box.size.center(Offset.zero));
      final d = (c - global).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = b;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _pointers[e.pointer] = _nearest(e.position);
        _refresh();
      },
      onPointerUp: (e) {
        _pointers.remove(e.pointer);
        _refresh();
      },
      onPointerCancel: (e) {
        _pointers.remove(e.pointer);
        _refresh();
      },
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: SizedBox(
            width: 196,
            height: 170,
            child: Stack(
              children: [
                Positioned(
                  left: 46,
                  bottom: 92,
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.hudTick,
                    builder: (_, _, _) => _PadButton(
                      key: _keys[_special],
                      icon: 'bolt',
                      label: tr('btn.special', 'Speciale'),
                      size: 64,
                      color: game.player.specialReady ? 'yellow' : 'grey',
                      progress: game.player.specialProgress,
                      down: _down[_special],
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 0,
                  child: _PadButton(
                    key: _keys[_attack],
                    icon: 'fist',
                    label: tr('btn.attack', 'Attacco'),
                    size: 78,
                    color: 'pink',
                    down: _down[_attack],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 30,
                  child: _PadButton(
                    key: _keys[_jump],
                    icon: 'up',
                    label: tr('btn.jump', 'Salto'),
                    size: 70,
                    color: 'blue',
                    down: _down[_jump],
                  ),
                ),
              ],
            ),
          ),
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

  /// Where the stick sits while untouched (bottom-left), and where the
  /// thumb landed while touched: the stick follows the thumb.
  Offset? _origin;
  Offset _offset = Offset.zero;
  int? _pointer;

  void _set(Offset local) {
    final c = _origin!;
    var d = local - c;
    const maxR = _size / 2 - _knob / 4;
    // Dragging far past the rim drags the stick along (no dead thumb).
    if (d.distance > maxR * 1.6) {
      _origin = c + d / d.distance * (d.distance - maxR * 1.6);
      d = local - _origin!;
    }
    if (d.distance > maxR) d = d / d.distance * maxR;
    final nx = d.dx / maxR, ny = d.dy / maxR;
    final i = widget.input;
    final wasX = i.x.abs() > .5;
    i.x = nx.abs() < .22 ? 0 : nx.clamp(-1.0, 1.0);
    // Up/down only when they dominate: running a bit diagonally must not
    // turn a forward attack into an up attack.
    i.up = ny < -.5 && ny.abs() > nx.abs() * .8;
    i.down = ny > .5 && ny.abs() > nx.abs() * .8;
    // Simple controls: flicking the stick up jumps (diagonals too).
    if (_tapJump) {
      final up = ny < -.6 && -ny > nx.abs() * .6;
      if (up && !_jumpHeld) i.pressJump();
      if (!up && _jumpHeld) i.jump = false;
      _jumpHeld = up;
    }
    if (!wasX && i.x.abs() > .5) Sound.haptic();
    setState(() => _offset = d);
  }

  bool _jumpHeld = false;

  bool get _tapJump => LocalStore.ready && LocalStore.instance.assistOn;

  void _release() {
    final i = widget.input;
    if (_jumpHeld) i.jump = false;
    _jumpHeld = false;
    i.x = 0;
    i.up = false;
    i.down = false;
    _pointer = null;
    setState(() {
      _origin = null;
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final rest = Offset(14 + _size / 2, box.maxHeight - 8 - _size / 2);
        final c = _origin ?? rest;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (_pointer != null) return;
            _pointer = e.pointer;
            _origin = e.localPosition;
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
          child: Stack(
            children: [
              Positioned(
                left: c.dx - _size / 2,
                top: c.dy - _size / 2,
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
                        color: Color(_origin == null ? 0x403A2440 : 0x663A2440),
                        border: Border.all(
                          color: const Color(0xAA3A2440),
                          width: 3,
                        ),
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
            ],
          ),
        );
      },
    );
  }
}

/// Round-ish pixel button reporting press/release (multi-touch friendly).
class _PadButton extends StatelessWidget {
  const _PadButton({
    super.key,
    required this.icon,
    required this.label,
    required this.down,
    this.size = 64,
    this.color = 'blue',
    this.progress = 1,
  });

  final String icon;
  final String label;
  final bool down;
  final double size;
  final String color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // (No Opacity here: it forced an offscreen layer every frame.)
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.only(top: down ? 5 : 0, bottom: down ? 0 : 5),
            decoration: pixelFrame(
              'assets/images/ui/button_$color${down ? '_down' : ''}.png',
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (progress < 1)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        color: const Color(0xFFFFD86A),
                        backgroundColor: const Color(0x333A2440),
                      ),
                    ),
                  ),
                PixelIcon(icon, scale: size / 24),
              ],
            ),
          ),
          PixelText(label, size: 10, color: Colors.white),
        ],
      ),
    );
  }
}
