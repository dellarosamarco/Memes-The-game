import 'package:flutter/material.dart';

import '../models/hats.dart';
import '../models/meme_character.dart';
import '../services/achievements.dart';
import '../services/local_store.dart';
import '../services/sound.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';

/// Spend the likes you collected on cute hats.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Hat? _preview =
      Hat.byId(LocalStore.instance.equippedHat) ?? Hat.all.first;

  Future<void> _act(Hat hat) async {
    final store = LocalStore.instance;
    if (store.ownedHats.contains(hat.id)) {
      final equipped = store.equippedHat == hat.id;
      await store.equipHat(equipped ? null : hat.id);
    } else if (await store.buyHat(hat.id, hat.price)) {
      await store.equipHat(hat.id);
      Sound.play('finish');
      Achievements.unlock('shopper');
    } else {
      Sound.play('hurt', volume: .4);
    }
    setState(() => _preview = hat);
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    return Scaffold(
      body: PixelBackdrop(
        top: const Color(0xFFFFC8E6),
        bottom: const Color(0xFFFFF0F8),
        theme: 'candy',
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
                    const Expanded(child: PixelText('Negozio', size: 26)),
                    PixelPanel(
                      px: 1.5,
                      padding: const EdgeInsets.fromLTRB(12, 6, 14, 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PixelIcon('like', scale: 2),
                          const SizedBox(width: 6),
                          PixelText(
                            '${store.wallet}',
                            size: 16,
                            color: kPlum,
                            outline: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      // All the memes trying on the hat.
                      SizedBox(
                        width: 300,
                        child: SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              for (final c in MemeCharacter.all)
                                CharacterSpriteView(
                                  character: c,
                                  scale: 1.2,
                                  hat: _preview,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 130,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: .82,
                              ),
                          itemCount: Hat.all.length,
                          itemBuilder: (_, i) => _HatCard(
                            hat: Hat.all[i],
                            selected: _preview?.id == Hat.all[i].id,
                            onPreview: () =>
                                setState(() => _preview = Hat.all[i]),
                            onAct: () => _act(Hat.all[i]),
                          ),
                        ),
                      ),
                    ],
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

class _HatCard extends StatelessWidget {
  const _HatCard({
    required this.hat,
    required this.selected,
    required this.onPreview,
    required this.onAct,
  });

  final Hat hat;
  final bool selected;
  final VoidCallback onPreview;
  final VoidCallback onAct;

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final owned = store.ownedHats.contains(hat.id);
    final equipped = store.equippedHat == hat.id;
    final affordable = store.wallet >= hat.price;
    return GestureDetector(
      onTap: onPreview,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
        decoration: pixelFrame(
          selected
              ? 'assets/images/ui/button_yellow.png'
              : 'assets/images/ui/panel.png',
          px: 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SheetIcon(
              asset: 'assets/images/${Hat.sheet}',
              index: hat.index,
              frames: Hat.all.length,
              size: Hat.width,
              height: Hat.height,
              scale: 2.4,
            ),
            PixelText(
              hat.name,
              size: 11,
              color: kPlum,
              outline: false,
              maxLines: 2,
            ),
            PixelButton(
              label: equipped
                  ? 'Togli'
                  : owned
                  ? 'Indossa'
                  : '${hat.price}',
              icon: owned ? null : 'like',
              height: 38,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: equipped
                  ? PixelColor.grey
                  : owned
                  ? PixelColor.mint
                  : (affordable ? PixelColor.pink : PixelColor.grey),
              onPressed: onAct,
            ),
          ],
        ),
      ),
    );
  }
}
