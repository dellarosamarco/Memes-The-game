# Pubblicare Memes: The fight

Il gioco è pronto per Android (Play Store), iOS (App Store) e web. Questa guida
elenca cosa fare, nell'ordine, per la prima pubblicazione.

## 0. Prima di tutto: diritti sulle immagini (importante)

Gli sprite dei personaggi sono ricavati da foto e immagini diventate meme. Alcuni
richiamano personaggi protetti da copyright o marchi (Shrek, Patrick di SpongeBob,
Masha e Orso, Mr. Bean/GTA, Saetta McQueen di Cars) e prodotti con marchio citati
nei testi (Converse, Nike Dunk, AirPods). Le foto di animali appartengono a chi le
ha scattate.

Google Play e App Store possono **rifiutare o rimuovere** un'app per violazione di
proprietà intellettuale, anche se è una parodia. Prima di pubblicare valuta:

- di rimuovere o sostituire i personaggi basati su personaggi di film/cartoni
  (`shrek_kid`, `rock_patrick`, `bottle_patrick`, `masha_man`, `gta_bean`,
  `suit_dachshund`) — basta toglierli da `MemeCharacter.all`;
- di togliere i nomi dei marchi dalle descrizioni dei personaggi;
- dove possibile, di chiedere il permesso agli autori delle foto originali.

Il gioco mostra già una nota "gioco parodistico, non affiliato" in Info e crediti
e nella descrizione dello store, ma non sostituisce una licenza.

## 1. Dati da completare

- `PRIVACY.md`: nome dello sviluppatore ed email di contatto (campi tra `[ ]`).
  Pubblicala a un URL pubblico (es. GitHub Pages o il README del repo): gli store
  chiedono il link.
- `lib/screens/about_screen.dart`: `kAppVersion` deve combaciare con `version`
  in `pubspec.yaml` a ogni release.

## 2. Android (Google Play)

1. Crea la chiave di firma (una volta sola, **conservala**: senza non puoi
   aggiornare l'app):
   ```bash
   keytool -genkey -v -keystore ~/memes-upload.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias upload
   ```
2. Crea `android/key.properties` (è in `.gitignore`, non va su git):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/percorso/memes-upload.jks
   ```
3. Build: `flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`
4. Play Console › Crea app › carica l'AAB in un test interno, poi produzione.
   - ID applicazione: `com.dellarosamarco.memes_the_fight` (non si può cambiare dopo).
   - Scheda: testi in `store/listing_it.md` / `store/listing_en.md`, icona
     `store/icon_512.png`, grafica `store/feature_graphic_1024x500.png`,
     screenshot `store/screenshots/play/`.
   - **Sicurezza dei dati**: "Nessun dato raccolto né condiviso" (il gioco è
     offline; tutto resta sul dispositivo).
   - **Classificazione dei contenuti**: questionario IARC → violenza cartoon
     lieve (personaggi che si colpiscono e vengono sbalzati fuori dall'arena,
     nessun sangue), nessun acquisto, nessun contenuto generato dagli utenti
     condiviso. Risultato atteso PEGI 7.
   - Pubblico target: 13+ consigliato (i personaggi parodiano meme e personaggi
     di cartoni; evita i requisiti aggiuntivi del programma "Famiglie").

## 3. iOS (App Store) — serve un Mac con Xcode

1. Apri `ios/Runner.xcworkspace`, imposta il tuo Team in *Signing &
   Capabilities* (bundle ID `com.dellarosamarco.memesTheFight`).
2. `flutter build ipa --release` e carica con Transporter o Xcode Organizer.
3. App Store Connect: testi da `store/`, screenshot `store/screenshots/iphone/`
   (6,7", 2796×1290) e `store/screenshots/ipad/` (13", 2752×2064).
   - Privacy "nutrition label": "Data Not Collected".
   - Il gioco dichiara `ITSAppUsesNonExemptEncryption = false`.

## 4. Web

`flutter build web --release --no-web-resources-cdn` e pubblica `build/web` su
qualsiasi hosting statico (GitHub Pages, Netlify, Firebase Hosting, itch.io come
"HTML game" zippando la cartella). Se lo pubblichi in una sottocartella, aggiungi
`--base-href /nome-cartella/`.

## 5. Prima di ogni release

- `flutter analyze` e `flutter test` (anche la CI su GitHub li esegue).
- Aumenta `version` in `pubspec.yaml` (es. `1.0.1+2`: il numero dopo `+` deve
  sempre crescere) e `kAppVersion`.
- Se cambi grafica/icone: `python3 tool/generate_sprites.py`,
  `python3 tool/generate_icons.py`,
  `cd tool && python3 generate_store_art.py <cartella screenshot grezzi>`.
