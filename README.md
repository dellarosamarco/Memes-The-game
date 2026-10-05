# Memes: the game

Arena survivor in stile *Vampire Survivors* fatto con **Flutter + Flame + Firebase**.
Scegli un meme, sopravvivi all'orda infinita di **Normie 🤓, Cringe 😬, Hater 😡 e Boomer 👴**,
raccogli i like ❤️, sali di livello, sconfiggi **L'Algoritmo 🤖** (boss ogni 2 minuti)
e scala la classifica globale.

## I personaggi

Ogni personaggio è costruito sull'identità del meme originale: aspetto, atteggiamento e battuta.

| Meme | Attacco automatico | Mossa speciale |
|---|---|---|
| **Wig Dog**: il chihuahua con la parrucca | *Colpo di Frangia*: ciocche di capelli a ventaglio | *Voglio il Manager!*: onda d'urto che respinge e danneggia |
| **Stare Cat**: il gatto che ti fissa | *Sguardo Laser*: laser dagli occhi che trapassano | *Il Fissatore*: congela tutti i nemici, che subiscono +50% danni |
| **Robber Chihuahua**: passamontagna e coltello | *Fendente*: colpi di coltello a 360° | *La Rapina*: scatto invulnerabile e furto di tutta l'XP sulla mappa |
| **Smile Dog**: il cane che sorride (troppo) | *Aura Inquietante*: danno continuo a chi è vicino | *Sorriso Maledetto*: danno enorme e nemici in fuga dal terrore |

Per aggiungere un meme: inserisci le immagini in `assets/images/characters/<id>.png` (faccia quadrata)
e `assets/images/portraits/<id>.jpg`, poi aggiungi una voce in `lib/models/meme_character.dart`
(con un nuovo `AttackType`/`SpecialType` se serve, implementato in `lib/game/components/player.dart`).

## Comandi

- **Mobile**: joystick in basso a sinistra, pulsante speciale in basso a destra.
- **Desktop/Web**: `WASD` o frecce per muoverti, `SPAZIO` per la speciale, `ESC` per la pausa.

## Avvio

```bash
flutter pub get
flutter run            # Android / iOS / web (chrome)
```

Senza Firebase il gioco funziona **offline** (record personali salvati in locale).

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

I punteggi vanno nella collezione `scores` (`uid`, `name`, `characterId`, `score`, `kills`,
`seconds`, `level`, `createdAt`). Le regole permettono a tutti di leggerli e a ogni giocatore
(anonimo) di aggiungere solo i propri, senza modificarli o cancellarli.

## Struttura

```
lib/
  main.dart                    bootstrap (LocalStore + Firebase)
  models/meme_character.dart   i personaggi e la loro identità
  services/                    Firebase (auth anonima + classifica) e salvataggi locali
  screens/                     home, selezione personaggio, partita, classifica
  game/
    memes_game.dart            FlameGame: spawn, ondate, XP, level up, game over
    upgrades.dart              statistiche e potenziamenti
    components/                player, nemici, proiettili, like, arena, effetti
    overlays/                  HUD, level up, pausa, game over (widget Flutter)
```
