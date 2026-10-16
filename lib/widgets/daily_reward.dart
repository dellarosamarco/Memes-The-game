import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/daily.dart';
import '../services/sound.dart';
import 'pixel_ui.dart';

/// Shows today's login reward (once a day), with the 7-day streak.
Future<void> showDailyReward(BuildContext context) async {
  if (!DailyReward.available) return;
  final today = DailyReward.todayIndex;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: PixelPanel(
        width: 600,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelText(
              tr('daily.title', 'Ricompensa giornaliera'),
              size: 22,
              color: const Color(0xFFFF82B4),
            ),
            PixelText(
              tr('daily.subtitle', 'Torna ogni giorno: il premio cresce!'),
              size: 13,
              color: kPlum,
              outline: false,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < DailyReward.rewards.length; i++)
                  _Day(
                    day: i + 1,
                    likes: DailyReward.rewards[i],
                    state: i < today
                        ? _DayState.taken
                        : (i == today ? _DayState.today : _DayState.later),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PixelButton(
              label: tr('daily.claim', 'Riscuoti +{n}', {
                'n': DailyReward.rewards[today],
              }),
              icon: 'like',
              color: PixelColor.mint,
              height: 48,
              fontSize: 16,
              onPressed: () async {
                await DailyReward.claim();
                Sound.play('finish');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

enum _DayState { taken, today, later }

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.likes, required this.state});

  final int day;
  final int likes;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final today = state == _DayState.today;
    final big = day == DailyReward.rewards.length;
    return Container(
      width: big ? 92 : 66,
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: switch (state) {
          _DayState.taken => const Color(0xFFDDF5E8),
          _DayState.today => const Color(0xFFFFE9A8),
          _DayState.later => const Color(0xFFF4ECF2),
        },
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: today ? const Color(0xFFFF82B4) : kPlum,
          width: today ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PixelText(
            tr('daily.day', 'Giorno {n}', {'n': day}),
            size: 11,
            color: kPlum,
            outline: false,
          ),
          PixelIcon(
            state == _DayState.taken ? 'star' : 'like',
            scale: big ? 2.6 : 2,
          ),
          state == _DayState.taken
              ? PixelText(
                  tr('common.ok', 'OK'),
                  size: 13,
                  color: const Color(0xFF2E9E6E),
                  outline: false,
                )
              : PixelText('+$likes', size: 13, color: kPlum, outline: false),
        ],
      ),
    );
  }
}
