import 'package:flutter/material.dart';

import '../services/achievements.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';
import '../l10n/l10n.dart';

class TrophiesScreen extends StatelessWidget {
  const TrophiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final got = LocalStore.instance.trophies;
    // Earned ones first.
    final sorted = [
      ...Achievements.all.where((t) => got.contains(t.id)),
      ...Achievements.all.where((t) => !got.contains(t.id)),
    ];
    return Scaffold(
      body: PixelBackdrop(
        top: const Color(0xFFFFE08C),
        bottom: const Color(0xFFFFF6D8),
        theme: 'desert',
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
                        tr('trophies.title', 'Trofei  {n}/{total}', {
                          'n': got.length,
                          'total': Achievements.all.length,
                        }),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 270,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.7,
                        ),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final t = sorted[i];
                      final on = got.contains(t.id);
                      return Opacity(
                        opacity: on ? 1 : .8,
                        child: PixelPanel(
                          px: 2,
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                          child: Row(
                            children: [
                              PixelIcon(on ? 'trophy' : 'lock', scale: 2.5),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PixelText(
                                      t.name,
                                      size: 14,
                                      color: on
                                          ? const Color(0xFFFF82B4)
                                          : kPlum,
                                      outline: on,
                                      align: TextAlign.left,
                                    ),
                                    PixelText(
                                      t.description,
                                      size: 10,
                                      color: const Color(0xFF6B5A78),
                                      outline: false,
                                      bold: false,
                                      align: TextAlign.left,
                                      maxLines: 2,
                                    ),
                                    if (!on)
                                      if (Achievements.progress(t.id) case (
                                        final done,
                                        final target,
                                      ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 3,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: LinearProgressIndicator(
                                                  value: done / target,
                                                  minHeight: 5,
                                                  color: const Color(
                                                    0xFFFF82B4,
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFE6DCE8,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              PixelText(
                                                '$done/$target',
                                                size: 10,
                                                color: kPlum,
                                                outline: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
