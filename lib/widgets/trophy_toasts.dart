import 'package:flutter/material.dart';

import '../services/achievements.dart';
import 'pixel_ui.dart';

/// Shows "Trofeo sbloccato!" toasts on top of every screen.
class TrophyToasts extends StatelessWidget {
  const TrophyToasts({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<List<Trophy>>(
        valueListenable: Achievements.toasts,
        builder: (context, list, _) {
          if (list.isEmpty) return const SizedBox.shrink();
          final t = list.first;
          return Align(
            alignment: const Alignment(0, -0.62),
            child: _Toast(key: ValueKey(t.id), trophy: t),
          );
        },
      ),
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({super.key, required this.trophy});

  final Trophy trophy;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward().whenComplete(() => Achievements.dismiss(widget.trophy));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        final s = v < .1
            ? Curves.easeOutBack.transform(v / .1)
            : (v > .9 ? (1 - v) / .1 : 1.0);
        return Opacity(
          opacity: s.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + 0.4 * s, child: child),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: PixelPanel(
          padding: const EdgeInsets.fromLTRB(14, 8, 18, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelIcon('trophy', scale: 3),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelText(
                    'Trofeo sbloccato!',
                    size: 12,
                    color: Color(0xFF9A8FB0),
                    outline: false,
                  ),
                  PixelText(
                    widget.trophy.name,
                    size: 20,
                    color: const Color(0xFFFF82B4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
