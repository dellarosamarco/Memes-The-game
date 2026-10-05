# Memes: the game

Platform 2D a scorrimento laterale fatto con **Flutter + Flame + Firebase**.
Scegli un meme, attraversa i livelli saltando sulla testa di **Normie, Cringe, Hater e
Boomer**, raccogli i like ❤️ (anche dai blocchi), arriva alla bandiera e sconfiggi
**L'Algoritmo** nell'ultimo livello. Punteggi nella classifica globale per livello.

## I personaggi

Gli sprite in pixel art sono ricavati **direttamente dalle foto originali dei meme**:
la figura viene scontornata, ridotta a pixel con una palette limitata e contornata;
vengono aggiunte solo le zampette animate.

| Meme | Passiva | Speciale |
|---|---|---|
| **Wig Dog**: il chihuahua con la parrucca | *Parrucca-Paracadute*: tieni premuto salto per planare | *Voglio il Manager!*: urlo che spazza via i nemici vicini |
| **Stare Cat**: il gatto che ti fissa | *Riflessi Felini*: doppio salto | *Il Fissatore*: congela i nemici, che diventano piattaforme |
| **Robber Chihuahua**: passamontagna e coltello | *Fuga Rapida*: il più veloce | *La Rapina*: scatto invulnerabile che trafigge i nemici |
| **Smile Dog**: il cane che sorride (troppo) | *Pelle Dura*: 4 cuori, schiaccia i Boomer al primo colpo | *Sorriso Maledetto*: i nemici scappano terrorizzati e muoiono al contatto |

## Livelli

1. **Il Feed**: tutorial, Normie e Cringe.
2. **Sezione Commenti**: arrivano Hater (lanciano commenti "RATIO -1"), Boomer e spine.
3. **Il Server**: tutto insieme e, alla fine, il boss **L'Algoritmo**: il cancello verso
   la bandiera si apre solo dopo averlo sconfitto.

Stelle: 1 per finire il livello, 2 con metà dei like, 3 con il 90%.
Il punteggio somma like, nemici, bonus tempo e cuori rimasti.

## Comandi

- **Mobile** (orizzontale): frecce a sinistra, salto e mossa speciale a destra.
- **Tastiera**: `←/→` o `A/D` per muoverti, `SPAZIO`/`↑`/`W` per saltare, `X`/`K`/`Shift` per la
  speciale, `ESC`/`P` per la pausa.

## Avvio

```bash
flutter pub get
flutter run
```

Senza Firebase il gioco funziona **offline** (record e livelli sbloccati salvati in locale).

Opzioni utili durante lo sviluppo:

```bash
flutter run --dart-define=MEMES_UNLOCK_ALL=true --dart-define=MEMES_START_COL=118
```

## Configurare Firebase (classifica online)

1. Crea un progetto su [Firebase console](https://console.firebase.google.com) e abilita
   **Authentication → Anonymous** e **Cloud Firestore**.
2. Genera `lib/firebase_options.dart` (sostituisce il placeholder):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. Pubblica regole e indici di Firestore:
   ```bash
   firebase deploy --only firestore
   ```

I punteggi stanno nella collezione `scores` (`uid`, `name`, `levelId`, `characterId`,
`score`, `likes`, `kills`, `seconds`, `createdAt`). Chiunque può leggerli; ogni giocatore
(anonimo) può solo aggiungere i propri.

## Grafica e livelli: come si rigenerano

- `tool/generate_sprites.py` genera tutti i PNG in `assets/images/sprites/` (personaggi dalle foto
  in `tool/sprite_sources/`, nemici, tile, oggetti, sfondi). Richiede `pip install pillow numpy`.
- Le foto scontornate in `tool/sprite_sources/` sono state create con
  [rembg](https://github.com/danielgatis/rembg) (modello `birefnet-general`).
- `tool/build_levels.py` genera `lib/game/levels.dart` a partire da una piccola DSL
  (`ground`, `row`, `likes`, `stairs`...). La legenda dell'ASCII è in `lib/game/level.dart`.

**Aggiungere un meme:** scontorna la foto con rembg, salvala in `tool/sprite_sources/<id>.png`,
aggiungi una voce in `FIGURES` dentro `generate_sprites.py` e in `lib/models/meme_character.dart`,
poi rilancia lo script.

## Struttura

```
lib/
  main.dart                   bootstrap (orizzontale, LocalStore, Firebase)
  models/meme_character.dart  i personaggi e la loro identità
  services/                   Firebase (auth anonima + classifica) e salvataggi locali
  screens/                    home, scelta personaggio, scelta livello, partita, classifica
  widgets/                    testo stile meme, anteprima animata degli sprite
  game/
    memes_game.dart           FlameGame: input, eventi del livello, camera
    level.dart / levels.dart  formato ASCII dei livelli e i livelli
    components/               player, nemici, fisica a tile, oggetti, sfondo, effetti
    overlays/                 HUD con comandi touch, pausa, fine livello, game over
tool/                         generatori di sprite e livelli
```
