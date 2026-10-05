# Memes: the game

Platform 2D a scorrimento laterale in **pixel art cute**, fatto con **Flutter + Flame + Firebase**.
Scegli un meme, attraversa 500 livelli in 10 mondi saltando sulla testa di **Normie,
Cringe, Hater e Boomer**, raccogli i like (anche dai blocchi), arriva alla bandiera e
sconfiggi **L'Algoritmo** alla fine di ogni mondo. Punteggi nella classifica globale per livello.

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

## 500 livelli, 10 mondi

| Mondo | Tema | Mondo | Tema |
|---|---|---|---|
| 1 | Il Feed | 6 | Città dei Trend |
| 2 | Sezione Commenti | 7 | Foresta dei Meme |
| 3 | Spiaggia dei Reel | 8 | Vulcano dei Flame |
| 4 | Deserto dei Like | 9 | Nuvole Virali |
| 5 | Ghiacciaio Cringe | 10 | Il Server |

Ogni mondo ha 50 livelli; il 50° è lo scontro con **L'Algoritmo** (più resistente a ogni
mondo), e il cancello verso la bandiera si apre solo dopo averlo battuto.

I livelli sono **generati proceduralmente** da un seed fisso (`lib/game/level_gen.dart`),
quindi sono uguali per tutti i giocatori. La difficoltà cresce gradualmente: i primi
livelli fanno da tutorial, poi arrivano buche, piattaforme sospese, spine, **molle**,
**piattaforme mobili**, tunnel e gruppi di nemici. Ogni livello viene verificato da
`lib/game/level_solver.dart`: simula il personaggio più lento, senza doppio salto né
mosse speciali e con la stessa fisica del gioco, e dimostra che il livello si può finire
(se un layout fallisce, viene rigenerato). Il test `test/levels_test.dart` controlla tutti
e 500 i livelli.

Stelle: 1 per finire il livello, 2 con metà dei like, 3 con il 90%.
Il punteggio somma like, nemici, bonus tempo e cuori rimasti.

## Elementi divertenti

- **Power-up** dai blocchi arcobaleno `!`:
  - occhiali **Deal With It** (invincibile per 8 s, i nemici volano via con un "BONK!");
  - **Stonks** (punti doppi per 12 s);
  - **Pizza** (+1 cuore);
  - **Caffè** (più veloce e salti più alti, con scia).
- **Combo**: schiaccia più nemici senza toccare terra per "Double kill!", "Triple kill!"...
  fino a "M-M-M-MONSTER KILL!" (con punti bonus).
- I nemici **parlano**: "Buongiornissimo! Kaffè?", "L + ratio", "uwu", "Ma è un meme?"...
- Se resti fermo troppo a lungo il tuo meme **si addormenta** (zZz).
- Al traguardo il personaggio **saltella di gioia**.
- Al game over puoi **premere F per rendere omaggio**.

## Negozio e trofei

- I like raccolti finiscono in un **portafoglio**: nel **Negozio** li spendi in 10 cappellini
  pixel (festa, fiocco, berretto, fiori, elica, chef, cowboy, strega, aureola, corona) che i
  tuoi meme indossano in gioco e nei menu.
- **17 trofei** da sbloccare (primo livello, 3 stelle, senza danni, speedrun, boss, combo,
  100 nemici, 1000 like, Deal with it, Stonks, pisolino, F, collezionista...), con una
  notifica pixel che compare su qualsiasi schermata.

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
flutter run --dart-define=MEMES_UNLOCK_ALL=true --dart-define=MEMES_START_COL=40 \
  --dart-define=MEMES_RICH=true   # +2000 like da spendere nel negozio
```

Test: `flutter test` (risolve tutti i 500 livelli e avvia il gioco vero su alcuni livelli
con un pilota automatico).

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

## Grafica

Tutta la grafica è pixel art in palette pastello con contorno color prugna, generata da script:

- `tool/generate_sprites.py`: personaggi dalle foto in `tool/sprite_sources/` (scontornate con
  [rembg](https://github.com/danielgatis/rembg), modello `birefnet-general`), più tutto il resto.
- `tool/pixel_world.py`: nemici, 10 temi (tile, piattaforme mobili, sfondi parallax con colline
  e nuvole con le faccine), oggetti e il kit dell'interfaccia (icone, pannelli e pulsanti
  9-slice in `assets/images/ui/`).
- `tool/pixel_details.py`: bordi arrotondati del terreno (auto-tiling) e varianti, liquidi
  animati nelle buche (acqua, lava, sciroppo...), 8 decorazioni animate per ogni mondo
  (fiori, funghi, cespugli con la faccina, pinguini, granchi, cupcake...), un livello di
  parallasse intermedio e la polvere.

In gioco ci sono anche: sole/luna sorridente, particelle d'ambiente per ogni mondo (petali,
neve, foglie, braci, bit...), ombre, squash & stretch del personaggio, polvere, coriandoli
a checkpoint e traguardo, schizzi quando si cade in una buca e punteggi fluttuanti.
- Font: [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans) (licenza OFL, in `assets/fonts/`).

Rigenera tutto con `python3 tool/generate_sprites.py` (servono `pillow` e `numpy`).

## Audio

Effetti sonori e musiche chiptune sono **sintetizzati da zero** da `tool/generate_audio.py`
(onde quadre/triangolari + rumore, nessun file di terzi) in `assets/audio/`: salto, like,
schiacciata, danno, molla, mossa speciale, checkpoint, traguardo, game over, boss, e tre
musiche in loop (menu, livello, boss). Si riproducono con `flame_audio`; musica, effetti
e vibrazione si attivano/disattivano dalle impostazioni (ingranaggio nella home o pausa).

**Aggiungere un meme:** scontorna la foto con rembg, salvala in `tool/sprite_sources/<id>.png`,
aggiungi una voce in `FIGURES` dentro `generate_sprites.py` e in `lib/models/meme_character.dart`,
poi rilancia lo script.

## Struttura

```
lib/
  main.dart                   bootstrap (orizzontale, LocalStore, Firebase)
  models/meme_character.dart  i personaggi e la loro identità
  services/                   Firebase (auth anonima + classifica) e salvataggi locali
  screens/                    home, personaggi, mappa dei mondi + griglia livelli, partita, classifica
  widgets/                    kit UI pixel (testo, icone, pannelli, pulsanti), anteprima sprite
  game/
    memes_game.dart           FlameGame: input, eventi del livello, camera
    level.dart                formato ASCII dei livelli e temi dei mondi
    level_gen.dart            generatore procedurale dei 500 livelli
    level_solver.dart         risolutore che verifica che ogni livello sia finibile
    physics.dart              fisica a tile condivisa da gioco e risolutore
    components/               player, nemici, oggetti, piattaforme mobili, sfondo, effetti
    overlays/                 HUD con comandi touch, pausa, fine livello, game over
tool/                         generatori della grafica
```
