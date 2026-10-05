import 'package:flutter/material.dart';

import '../services/achievements.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';

class TrophiesScreen extends StatelessWidget {
  const TrophiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final got = LocalStore.instance.trophies;
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
                        'Trofei  ${got.length}/${Achievements.all.length}',
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
                          childAspectRatio: 3.2,
                        ),
                    itemCount: Achievements.all.length,
                    itemBuilder: (_, i) {
                      final t = Achievements.all[i];
                      final on = got.contains(t.id);
                      return Opacity(
                        opacity: on ? 1 : .55,
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
