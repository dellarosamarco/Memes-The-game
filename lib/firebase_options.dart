// PLACEHOLDER — sostituisci questo file eseguendo:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Finché il file non viene rigenerato il gioco funziona offline:
// la classifica online è disabilitata e i record restano solo in locale.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase non è configurato: esegui `flutterfire configure`.',
  );
}
