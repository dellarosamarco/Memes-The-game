import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';

/// Version shown in the app (keep in sync with pubspec.yaml).
const kAppVersion = '1.0.0';

/// Info, credits, privacy and "delete my data".
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _body = TextStyle(
    fontFamily: kPixelFont,
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
              const PixelText(
                'Cancellare tutto?',
                size: 22,
                color: Color(0xFFFF82B4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Perderai livelli sbloccati, stelle, like, cappelli e trofei. '
                'Anche i tuoi punteggi nella classifica online verranno '
                'eliminati. Non si può annullare.',
                textAlign: TextAlign.center,
                style: _body,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  PixelButton(
                    label: 'Annulla',
                    color: PixelColor.grey,
                    height: 46,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  PixelButton(
                    label: 'Cancella',
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
    final online = await FirebaseService.instance.deleteMyData();
    await LocalStore.instance.clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FirebaseService.instance.available && !online
              ? 'Dati locali cancellati. Classifica online non raggiungibile: '
                    'riprova quando sei connesso.'
              : 'Fatto: tutti i tuoi dati sono stati cancellati.',
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
                    const Expanded(
                      child: PixelText('Info e crediti', size: 24),
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
                            'Memes: the game  v$kAppVersion',
                            'Un platform 2D in pixel art con i meme più '
                                'iconici di internet. 24 personaggi, 500 '
                                'livelli, 10 mondi e L\'Algoritmo da battere.',
                          ),
                          _section(
                            'I meme',
                            'Gli sprite dei personaggi sono ricavati da '
                                'immagini diventate meme su internet. Questo '
                                'è un gioco parodistico e non è affiliato né '
                                'approvato dagli autori delle immagini o dai '
                                'titolari dei personaggi citati.',
                          ),
                          _section(
                            'Crediti',
                            '• Decorazioni dei livelli: Pixel Platformer di '
                                'Kenney (kenney.nl), licenza CC0.\n'
                                '• Font Pixelify Sans, licenza SIL Open Font '
                                'License.\n'
                                '• Fatto con Flutter e Flame.\n'
                                '• Musica, effetti sonori, nemici, mondi e '
                                'interfaccia creati per il gioco.',
                          ),
                          _section(
                            'Privacy',
                            'Il gioco non mostra pubblicità e non usa '
                                'tracciamento. Progressi e impostazioni '
                                'restano sul tuo dispositivo. Se la classifica '
                                'online è attiva, quando finisci un livello '
                                'vengono inviati: il nome che hai scelto, il '
                                'punteggio, il livello e il personaggio, '
                                'legati a un account anonimo. Puoi cancellare '
                                'tutto qui sotto.',
                          ),
                          Center(
                            child: PixelButton(
                              label: 'Cancella i miei dati',
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
