import 'package:flutter/material.dart';

import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';
import '../l10n/l10n.dart';
import '../models/meme_character.dart';

/// Version shown in the app (keep in sync with pubspec.yaml).
const kAppVersion = '1.0.0';

/// Info, credits, privacy and "delete my data".
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static TextStyle get _body => TextStyle(
    fontFamily: kPixelFont,
    fontFamilyFallback: fontFallback,
    fontSize: 13,
    height: 1.3,
    color: Color(0xFF6B5A78),
  );

  Widget _section(String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixelText(
          title,
          size: 16,
          color: const Color(0xFFFF82B4),
          align: TextAlign.left,
        ),
        const SizedBox(height: 3),
        Text(text, style: _body),
      ],
    ),
  );

  Future<void> _deleteData(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: PixelPanel(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelText(
                tr('about.eraseTitle', 'Cancellare tutto?'),
                size: 22,
                color: Color(0xFFFF82B4),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'about.eraseText',
                  'Perderai like, cappelli, trofei, record Arcade e '
                      'statistiche. Non si può annullare.',
                ),
                textAlign: TextAlign.center,
                style: _body,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  PixelButton(
                    label: tr('common.cancel', 'Annulla'),
                    color: PixelColor.grey,
                    height: 46,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  PixelButton(
                    label: tr('about.erase', 'Cancella'),
                    color: PixelColor.pink,
                    height: 46,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    await LocalStore.instance.clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('about.erased', 'Fatto: tutti i tuoi dati sono stati cancellati.'),
        ),
      ),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
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
                        tr('about.title', 'Info e crediti'),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PixelPanel(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section(
                            'Memes: The fight  v$kAppVersion',
                            tr(
                              'about.intro',
                              'Un picchiaduro in pixel art alla Smash con i '
                                  'meme più iconici di internet: {n} lottatori, '
                                  '10 arene, lotta libera e Arcade contro la CPU.',
                              {'n': MemeCharacter.all.length},
                            ),
                          ),
                          _section(
                            tr('about.memesTitle', 'I meme'),
                            tr(
                              'about.memesText',
                              'Gli sprite dei personaggi sono ricavati da '
                                  'immagini diventate meme su internet. Questo '
                                  'è un gioco parodistico e non è affiliato né '
                                  'approvato dagli autori delle immagini o dai '
                                  'titolari dei personaggi citati.',
                            ),
                          ),
                          _section(
                            tr('about.creditsTitle', 'Crediti'),
                            '${tr('about.creditsText', '• Decorazioni delle arene: Pixel Platformer di '
                                'Kenney (kenney.nl), licenza CC0.\n'
                                '• Font Pixelify Sans, licenza SIL Open Font '
                                'License.\n'
                                '• Fatto con Flutter e Flame.\n'
                                '• Musica, effetti sonori, arene e interfaccia '
                                'creati per il gioco.')}\n'
                            '• DotGothic16, Noto Sans KR, Noto Sans SC: '
                            'SIL Open Font License.',
                          ),
                          _section(
                            tr('about.privacyTitle', 'Privacy'),
                            tr(
                              'about.privacyText',
                              'Il gioco funziona offline, non mostra '
                                  'pubblicità, non usa tracciamento e non invia '
                                  'dati a nessuno: progressi e impostazioni '
                                  'restano sul tuo dispositivo. Puoi cancellare '
                                  'tutto qui sotto.',
                            ),
                          ),
                          Center(
                            child: PixelButton(
                              label: tr(
                                'about.eraseButton',
                                'Cancella i miei dati',
                              ),
                              color: PixelColor.grey,
                              height: 46,
                              fontSize: 15,
                              onPressed: () => _deleteData(context),
                            ),
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
