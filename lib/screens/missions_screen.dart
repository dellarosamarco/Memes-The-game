import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/missions.dart';
import '../services/local_store.dart';
import '../services/sound.dart';
import '../widgets/pixel_ui.dart';

/// Today's three missions, their progress and rewards.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  @override
  void initState() {
    super.initState();
    Missions.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _claim(Mission m) async {
    final likes = await Missions.claim(m);
    if (likes > 0) Sound.play('like');
    setState(() {});
  }

  Future<void> _claimBonus() async {
    final likes = await Missions.claimBonus();
    if (likes > 0) Sound.play('finish');
    setState(() {});
  }

  String _timeLeft() {
    final t = Missions.timeLeft;
    return tr('missions.newIn', 'Nuove missioni tra {h}h {m}m', {
      'h': t.inHours,
      'm': t.inMinutes % 60,
    });
  }

  @override
  Widget build(BuildContext context) {
    final missions = Missions.today();
    final allClaimed = missions.every((m) => m.claimed);
    final bonusTaken = LocalStore.instance.getBool('missions_bonus');
    return Scaffold(
      body: PixelBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    PixelButton(
                      icon: 'left',
                      color: PixelColor.grey,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: PixelText(
                        tr('missions.title', 'Missioni del giorno'),
                        size: 24,
                      ),
                    ),
                    WalletChip(likes: LocalStore.instance.wallet),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: PixelPanel(
                    width: 620,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final m in missions) _MissionRow(m, _claim),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const PixelIcon('star', scale: 2),
                              const SizedBox(width: 10),
                              Expanded(
                                child: PixelText(
                                  tr(
                                    'missions.bonus',
                                    'Completale tutte e 3: +{n} like',
                                    {'n': Missions.bonus},
                                  ),
                                  size: 14,
                                  color: kPlum,
                                  outline: false,
                                  align: TextAlign.left,
                                ),
                              ),
                              if (bonusTaken)
                                const PixelIcon('star', scale: 2)
                              else
                                PixelButton(
                                  label: tr('missions.claim', 'Riscuoti'),
                                  height: 38,
                                  fontSize: 13,
                                  color: allClaimed
                                      ? PixelColor.yellow
                                      : PixelColor.grey,
                                  onPressed: allClaimed ? _claimBonus : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PixelText(
                            _timeLeft(),
                            size: 12,
                            color: const Color(0xFF9A8FB0),
                            outline: false,
                          ),
                        ],
                      ),
                    ),
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

class _MissionRow extends StatelessWidget {
  const _MissionRow(this.mission, this.onClaim);

  final Mission mission;
  final void Function(Mission) onClaim;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          PixelIcon(m.done ? 'star' : 'star_empty', scale: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  m.text,
                  size: 14,
                  color: kPlum,
                  outline: false,
                  align: TextAlign.left,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: m.progress / m.target,
                          minHeight: 8,
                          color: const Color(0xFF6FD6A0),
                          backgroundColor: const Color(0x223A2440),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PixelText(
                      '${m.progress}/${m.target}',
                      size: 12,
                      color: kPlum,
                      outline: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (m.claimed)
            SizedBox(
              width: 120,
              child: PixelText(
                tr('missions.claimed', 'Fatto!'),
                size: 14,
                color: const Color(0xFF2E9E6E),
                outline: false,
              ),
            )
          else
            PixelButton(
              label: m.done
                  ? tr('missions.claimRewards', 'Riscuoti +{n}', {
                      'n': m.reward,
                    })
                  : '+${m.reward}',
              icon: 'like',
              width: 120,
              height: 38,
              fontSize: 13,
              color: m.done ? PixelColor.yellow : PixelColor.grey,
              onPressed: m.done ? () => onClaim(m) : null,
            ),
        ],
      ),
    );
  }
}
