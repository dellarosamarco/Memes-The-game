import 'package:flutter/material.dart';

import '../../widgets/pixel_ui.dart';
import '../memes_game.dart';
import '../../l10n/l10n.dart';

/// "How to fight": the controls in one card. Shown before the first fight
/// ever (holding the countdown) and from the pause menu.
class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key, required this.onClose});

  final VoidCallback onClose;

  static const _body = TextStyle(
    fontFamily: kPixelFont,
    fontSize: 13,
    height: 1.2,
    color: Color(0xFF6B5A78),
  );

  Widget _row(Widget icon, String title, String text) => Container(
    width: 272,
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(width: 44, child: Center(child: icon)),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title  ',
                  style: _body.copyWith(
                    color: kPlum,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
            style: _body,
          ),
        ),
      ],
    ),
  );

  Widget _button(String icon, String color) => Container(
    width: 38,
    height: 38,
    padding: const EdgeInsets.only(bottom: 4),
    decoration: pixelFrame('assets/images/ui/button_$color.png', px: 2),
    child: Center(child: PixelIcon(icon, scale: 1.6)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x993A2440),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: PixelPanel(
          width: 600,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelText(
                tr('howto.title', 'Come si combatte'),
                size: 20,
                color: Color(0xFFFF82B4),
              ),
              const SizedBox(height: 4),
              Text(
                tr(
                  'howto.intro',
                  'Più danni (%) ha l\'avversario, più vola lontano quando lo '
                      'colpisci: scaraventalo fuori dallo schermo!',
                ),
                textAlign: TextAlign.center,
                style: _body,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _row(
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x553A2440),
                        border: Border.all(color: kPlum, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: pixelFrame(
                            'assets/images/ui/button_blue.png',
                            px: 1,
                          ),
                        ),
                      ),
                    ),
                    tr('howto.joystick', 'Joystick'),
                    tr(
                      'howto.joystickText',
                      'muoviti; spingi in su per saltare. Giù su una '
                          'piattaforma: scendi.',
                    ),
                  ),
                  _row(
                    _button('fist', 'pink'),
                    tr('btn.attack', 'Attacco'),
                    tr(
                      'howto.attackText',
                      'tocca per colpire: il colpo giusto parte da solo verso '
                          "l'avversario. Tieni premuto per lo SMASH.",
                    ),
                  ),
                  _row(
                    _button('bolt', 'yellow'),
                    tr('btn.special', 'Speciale'),
                    tr(
                      'howto.specialText',
                      'la mossa del tuo meme. Fuori dall\'arena ti riporta '
                          'su da sola.',
                    ),
                  ),
                  _row(
                    _button('up', 'blue'),
                    tr('btn.jump', 'Salto'),
                    tr(
                      'howto.jumpText',
                      'puoi saltare ancora in aria; finiti i salti, ti rilancia '
                          'verso l\'arena.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr(
                  'howto.mash',
                  'Congelato, addormentato o stordito? Premi i tasti a raffica '
                      'per liberarti prima! (Comandi esperti: Impostazioni > '
                      'Assistito: No.)',
                ),
                textAlign: TextAlign.center,
                style: _body,
              ),
              const SizedBox(height: 10),
              PixelButton(
                label: tr('howto.ok', 'Ho capito!'),
                icon: 'play',
                color: PixelColor.mint,
                height: 48,
                fontSize: 16,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tutorial overlay of a fight.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({super.key, required this.game});

  final MemesGame game;

  @override
  Widget build(BuildContext context) => HowToPlay(onClose: game.closeTutorial);
}
