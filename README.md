# Memes: The fight

Picchiaduro **alla Super Smash Bros** in **pixel art cute**, fatto con **Flutter + Flame**.
Scegli uno dei 24 meme più iconici di internet e affronta la CPU su 10 arene sospese:
accumula danni sull'avversario e scaraventalo fuori dallo schermo.

## I lottatori

Gli sprite in pixel art sono ricavati **direttamente dalle foto originali dei meme**:
la figura viene scontornata, ridotta a pixel con una palette limitata e contornata;
vengono aggiunte solo le zampette animate. Tutti condividono lo stesso set di mosse;
a renderli unici sono **passiva**, **speciale** e statistiche (velocità, salto, peso).

| Meme | Passiva | Speciale |
|---|---|---|
| **Wig Dog** | *Parrucca-Paracadute*: plana tenendo premuto salto | *Voglio il Manager!*: onda d'urto (11%) |
| **Stare Cat** | *Riflessi Felini*: due salti in aria | *Il Fissatore*: paralizza l'avversario vicino |
| **Robber Chihuahua** | *Fuga Rapida*: il più veloce | *La Rapina*: scatto invulnerabile (10%) |
| **Smile Dog** | *Pelle Dura*: pesante, difficile da scagliare | *Sorriso Maledetto*: l'avversario scappa terrorizzato |
| **Puffer Pinscher** | *Piumino Imbottito*: il primo colpo di ogni vita è assorbito | *Frullatore di Treccine*: trottola (9%) |
| **Lady Terrier** | *Like di Lusso*: like di fine lotta doppi | *Borsettata*: colpo potentissimo (13%) |
| **Ka-Chow Bassotto** | *Crocs Corazzate*: -15% di danni subiti | *Ka-Chow!*: turbo che investe (8%) |
| **Bassotto Criceto** | *Guance Capienti*: ogni colpo a segno cura 1% | *Gonfia Guance*: risale fluttuando |
| **Bebè Pupazzo** | *Pancino Gommoso*: rimbalza sulla testa dell'avversario (6%) | *Ninna Nanna*: si cura e addormenta |
| **Scimmietta Rosa** | *Agilità da Scimmia*: tre salti in aria | *Lancio del Peluche*: proiettile (7%) |
| **Baby Orco** | *Strati di Cipolla*: si rigenera se non colpito | *Esci dalla mia Palude!*: schianto (13%) |
| **Orecchione** | *Orecchie a Molla*: salto più alto | *Dentiera Smagliante*: acceca e blocca (5%) |
| **Maiale Drip** | *Catena d'Oro*: speciali +20% danni | *Cancellazione del Rumore*: 4 s senza contraccolpo |
| **Pulcino Caschetto** | *Pulcino Leggero*: salti lunghi, ma vola via facilmente | *Cip Cip!*: tre pulcini (5% l'uno) |
| **Piccione Casco** | *Casco Protettivo*: immune ai proiettili | *Volo Urbano*: vola per 2,5 secondi |
| **Pietro** | *Converse ai Piedi*: accelera e frena all'istante | *Pietro is calling...*: l'avversario si ferma a rispondere |
| **Cane in Bici** | *Pedalata*: accelera pedalando | *POLIS!*: la volante investe (14%) |
| **Gallina Hypebeast** | *Hustler*: like ×1,5 | *Uovo Bomba*: esplosione (12%) |
| **Mr. San Andreas** | *Respawn all'Ospedale*: 4 s di invincibilità dopo ogni KO | *HESOYAM*: -25% di danni |
| **Masha Baffuta** | *Mani Pesanti*: smash +25% di spinta | *Salto di Masha*: salto enorme (8%) |
| **Patrick Roccia** | *Testa di Roccia*: attacco in alto doppio | *Roccia Rotolante*: rotola travolgendo (11%) |
| **Patrick Boccione** | *Sempre Idratato*: speciale che si ricarica al doppio | *Spruzzo d'Acqua*: spinge via |
| **Scimmia col Sasso** | *Presa Salda*: i colpi deboli non lo smuovono | *Tiro del Sasso*: sasso a parabola (10%) |
| **Chihuahua Relax** | *Relax Totale*: fermo recupera 1% al secondo | *Modalità Ferie*: avversario al rallentatore |

## Come si combatte

- **Percentuale di danno**: ogni colpo aggiunge %, e più è alta più voli lontano.
  Si va KO uscendo dalle **zone di esplosione** ai lati, in alto o in basso. 3 vite a testa.
- **Attacchi** (un tasto + direzione): jab, laterale, in alto, in basso, in corsa;
  **smash caricato** tenendo premuto attacco; aerei neutro, avanti, su e giù
  (quello in giù schiaccia verso il basso).
- **Congelato, addormentato o stordito?** Premi i tasti a raffica per liberarti prima.
- **Scudo** (si consuma e può rompersi), **schivata rotolando** (scudo + direzione) e
  **schivata in aria**.
- **Recupero**: su + speciale in aria ti rilancia verso l'arena (una volta per salto,
  ritorna quando vieni colpito o tocchi terra). Doppio salto per tutti.
- Piattaforme attraversabili dal basso, giù per scendere; giù in aria per cadere veloce.

### Modalità

- **Lotta libera**: scegli il tuo meme, l'avversario (o casuale), l'arena (o casuale) e la
  difficoltà della CPU (Facile, Normale, Difficile).
- **Arcade**: 8 avversari di fila, sempre più forti, e l'ultimo è una sorpresa. Il record
  di round vinti viene salvato per ogni meme.

### Oggetti

Ogni tanto piove un oggetto sull'arena (si possono disattivare in Lotta libera):
gli **occhiali Deal With It** rendono invincibili per 6 secondi, **Stonks** fa fare il
50% di danni in più per 10 secondi, la **pizza** cura il 20%, il **caffè** fa correre
e saltare di più. Attenti alla **bomba**: quando tocca terra parte la miccia e poi
esplode scagliando chiunque sia vicino. Anche la CPU va a prendere gli oggetti e scappa
dalle bombe.

### La CPU

Si avvicina, sceglie l'attacco in base alla posizione, carica lo smash quando sei ad alta
percentuale, para e rotola, usa la propria speciale con criterio (i proiettili da lontano,
gli scatti in linea, il volo per tornare) e recupera verso l'arena. Le tre difficoltà
cambiano tempi di reazione, aggressività e uso di scudo e speciali.

### 10 arene

Campo del Feed, Sezione Commenti, Spiaggia Finale, Duna dei Like, Iceberg Cringe,
Torta dei Trend, Radura dei Meme, Cratere Flame, Nuvole Virali e Data Center (con una
piattaforma mobile): isole sospese con piattaforme, ognuna con il suo tema e le sue
decorazioni animate.

### Game feel

Micro-pausa sugli impatti (hit-stop), tremolio dello schermo, scintille, rallentatore
sul KO decisivo, esplosione colorata dal bordo dello schermo a ogni KO, camera dinamica
che inquadra entrambi i lottatori, percentuali che tremano e cambiano colore, frasi
buffe dei meme quando incassano un colpo forte.

## Negozio e trofei

- Ogni lotta fa guadagnare **like** (di più vincendo, con i KO e a difficoltà alta; il
  meme del giorno li raddoppia): nel **Negozio** li spendi in 16 cappellini pixel che il
  tuo meme indossa in lotta e nei menu.
- **16 trofei** (prima vittoria, vittoria senza perdere vite, KO con uno smash, Arcade,
  100 KO, tutti i meme...), con una notifica pixel su qualsiasi schermata. Dopo una
  sconfitta puoi **premere F per rendere omaggio**.

## Comandi

- **Mobile** (orizzontale): joystick a sinistra; **Salto**, **Attacco**, **Speciale**
  (con l'indicatore di ricarica) e **Scudo** a destra, con vibrazione.
- **Tastiera**: frecce o `WASD` per muoverti e mirare, `Z`/`SPAZIO` salto, `X`/`J`
  attacco (tieni premuto per lo smash), `C`/`K` speciale, `V`/`L`/`Shift` scudo,
  `ESC`/`P` pausa.

## Pubblicazione

Il gioco è pronto per Play Store, App Store e web: icona, schermata di avvio, solo
orizzontale, firma Android, pausa automatica in background, info e crediti,
cancellazione dei dati e materiale per gli store (`store/`). Funziona **completamente
offline** e non raccoglie dati. Passi e checklist in **[PUBLISHING.md](PUBLISHING.md)**,
informativa in **[PRIVACY.md](PRIVACY.md)**. La CI su GitHub esegue analisi, test e
build web a ogni push.

## Avvio

```bash
flutter pub get
flutter run
```

Opzioni utili durante lo sviluppo:

```bash
flutter run --dart-define=MEMES_RICH=true   # +2000 like da spendere nel negozio
flutter run --dart-define=MEMES_STOCKS=1    # lotte libere a una vita
```

Test: `flutter test` (modello del knockback, arene, Arcade, salvataggi e partite vere
CPU contro CPU con tutti i 24 meme, per scovare errori e controllare che le lotte finiscano).

## Grafica

Tutta la grafica è pixel art in palette pastello con contorno color prugna, generata da script:

- `tool/generate_sprites.py`: personaggi dalle foto in `tool/sprite_sources/` (scontornate con
  [rembg](https://github.com/danielgatis/rembg), modello `birefnet-general`), più tutto il resto.
- `tool/pixel_world.py`: 10 temi (tile, piattaforme mobili, sfondi parallax con colline
  e nuvole con le faccine), oggetti e il kit dell'interfaccia (icone, pannelli e pulsanti
  9-slice in `assets/images/ui/`).
- `tool/pixel_details.py`: bordi arrotondati del terreno (auto-tiling) e varianti,
  8 decorazioni animate per ogni arena (fiori, funghi, cespugli con la faccina, pinguini,
  granchi, cupcake...), un livello di parallasse intermedio, la polvere e i cappellini.

In gioco ci sono anche: sole/luna sorridente, particelle d'ambiente per ogni arena (petali,
neve, foglie, braci, bit...), ombre, squash & stretch, polvere, scintille e coriandoli.
- Font: [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans) (licenza OFL, in `assets/fonts/`).

Rigenera tutto con `python3 tool/generate_sprites.py` (servono `pillow` e `numpy`).

## Audio

Effetti sonori e musiche chiptune sono **sintetizzati da zero** da `tool/generate_audio.py`
(onde quadre/triangolari + rumore, nessun file di terzi) in `assets/audio/`: salto, like,
colpo leggero e forte, smash caricato, attacco a vuoto, scudo rotto, KO con esplosione, mossa speciale, vittoria, sconfitta e tre musiche in loop
(menu, lotta, lotta finale). Si riproducono con `flame_audio`; musica, effetti
e vibrazione si attivano/disattivano dalle impostazioni (ingranaggio nella home o pausa).

**Aggiungere un meme:** scontorna la foto con rembg, salvala in `tool/sprite_sources/<id>.png`,
aggiungi una voce in `FIGURES` dentro `generate_sprites.py` e in `lib/models/meme_character.dart`,
poi rilancia lo script.

## Struttura

```
lib/
  main.dart                   bootstrap (orizzontale, salvataggi, audio)
  models/                     i meme e i cappellini
  services/                   salvataggi locali, trofei, audio
  screens/                    home, scelta del meme, lotta libera, Arcade, lotta, negozio, trofei
  widgets/                    kit UI pixel (testo, icone, pannelli, pulsanti), anteprima sprite
  game/
    memes_game.dart           FlameGame: regole della lotta, KO, camera, input
    fighter/                  il lottatore: mosse, knockback, scudo, speciali e passive
    cpu.dart                  l'avversario controllato dal computer
    arcade.dart               la scala degli 8 avversari
    stages.dart               le 10 arene
    physics.dart              fisica a tile
    components/               arena, proiettili, sfondo, effetti
    overlays/                 HUD con comandi touch, conto alla rovescia, pausa, risultati
tool/                         generatori della grafica e dell'audio
```

## Crediti

- Decorazioni delle arene (girasoli, grano, pini, pupazzi di neve, cartelli,
  ciambelle, gelati, sirene...) dai pacchetti **Pixel Platformer** di
  [Kenney](https://kenney.nl) (base, Farm, Food e Industrial expansion), licenza
  **CC0**. I file usati sono in `tool/kenney/`, ricolorati col contorno prugna del gioco.
  Lo stile dei tile (contorno spesso, puntini 2x2) è ispirato agli stessi pacchetti.
- Font **Pixelify Sans** (licenza OFL), con le legature disattivate (la "fi" di "fight" restava illeggibile).
- Tutto il resto (sprite dei meme dalle foto, tile, UI, musica ed effetti) è
  generato dagli script in `tool/`.
