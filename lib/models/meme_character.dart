import 'package:flutter/material.dart';

/// Movement perk every meme has all the time.
enum Passive {
  glide,
  doubleJump,
  sprint,
  tough,
  puffy,
  jewels,
  spikeProof,
  magnet,
  bouncy,
  tripleJump,
  onion,
  highJump,
  drip,
  featherweight,
  helmet,
  sneakers,
  momentum,
  hustle,
  respawnCheat,
  bossBrawler,
  rockHead,
  refill,
}

/// Signature move, on a cooldown.
enum SpecialType {
  manager,
  stare,
  heist,
  cursedSmile,
  braidSpin,
  purse,
  kachow,
  balloon,
  lullaby,
  plushThrow,
  swampSlam,
  teethFlash,
  airpods,
  chickArmy,
  flight,
  phoneCall,
  police,
  eggBomb,
  hesoyam,
  superJump,
  rockRoll,
  waterJet,
}

/// A playable meme. Every field is meant to stay faithful to the original
/// meme's identity: look (sprites come from the real photo), attitude and
/// the joke it is known for.
class MemeCharacter {
  const MemeCharacter({
    required this.id,
    required this.name,
    required this.memeAlias,
    required this.tagline,
    required this.lore,
    required this.color,
    required this.hearts,
    required this.runSpeed,
    required this.jumpSpeed,
    required this.passive,
    required this.passiveName,
    required this.passiveDescription,
    required this.specialType,
    required this.specialName,
    required this.specialDescription,
    required this.specialCooldown,
    required this.specialShout,
    required this.hurtLines,
  });

  final String id;
  final String name;
  final String memeAlias;
  final String tagline;
  final String lore;
  final Color color;

  final int hearts;
  final double runSpeed;
  final double jumpSpeed;

  final Passive passive;
  final String passiveName;
  final String passiveDescription;

  final SpecialType specialType;
  final String specialName;
  final String specialDescription;
  final double specialCooldown;

  /// Big caption shown on screen when the special is used.
  final String specialShout;

  /// Random lines shown when the character gets hit.
  final List<String> hurtLines;

  /// Where hats sit, relative to the feet (sprite frame: feet at y=58,
  /// centered at x=30), facing right.
  ({double x, double y}) get hatAnchor => switch (id) {
    'wig_dog' => (x: 0.5, y: -51),
    'stare_cat' => (x: 0.5, y: -44),
    'robber_dog' => (x: -11, y: -54),
    'pigtail_dog' => (x: 1, y: -50),
    'pearl_terrier' => (x: -1, y: -52),
    'suit_dachshund' => (x: 5.5, y: -46),
    'cheeks_dachshund' => (x: -3, y: -52),
    'snow_baby' => (x: 2.5, y: -50),
    'pink_monkey' => (x: -7, y: -49),
    'shrek_kid' => (x: 0, y: -50),
    'ears_dog' => (x: 0, y: -46),
    'drip_pig' => (x: 2, y: -50),
    'bowl_chick' => (x: 4.5, y: -45),
    'helmet_pigeon' => (x: -1, y: -51),
    'pietro_pigeon' => (x: -1.5, y: -51),
    'bike_dog' => (x: -7, y: -48),
    'sneaker_hen' => (x: 12, y: -44),
    'gta_bean' => (x: -0.5, y: -43),
    'masha_man' => (x: -0.5, y: -50),
    'rock_patrick' => (x: -4, y: -53),
    'bottle_patrick' => (x: 2, y: -55),
    _ => (x: -4.5, y: -52),
  };

  /// Animation strip, relative to assets/images/ (Flame's image prefix).
  String get spriteSheet => 'sprites/$id.png';

  /// Pixel-art portrait for menus (full asset path).
  String get portraitAsset => 'assets/images/sprites/${id}_portrait.png';

  /// The original meme photo.
  String get photoAsset => 'assets/images/portraits/$id.jpg';

  static MemeCharacter byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static const all = [
    wigDog,
    stareCat,
    robberDog,
    smileDog,
    pigtailDog,
    pearlTerrier,
    suitDachshund,
    cheeksDachshund,
    snowBaby,
    pinkMonkey,
    shrekKid,
    earsDog,
    dripPig,
    bowlChick,
    helmetPigeon,
    pietroPigeon,
    bikeDog,
    sneakerHen,
    gtaBean,
    mashaMan,
    rockPatrick,
    bottlePatrick,
  ];

  static const wigDog = MemeCharacter(
    id: 'wig_dog',
    name: 'Wig Dog',
    memeAlias: 'Il chihuahua con la parrucca',
    tagline: 'Caschetto perfetto. Sguardo giudicante.',
    lore:
        'Il chihuahua con il caschetto castano e lo sguardo di chi sta per '
        'lasciare una recensione da una stella. Non ha mai torto, '
        'e se ce l\'ha vuole comunque parlare col responsabile.',
    color: Color(0xFFB5651D),
    hearts: 3,
    runSpeed: 150,
    jumpSpeed: 520,
    passive: Passive.glide,
    passiveName: 'Parrucca-Paracadute',
    passiveDescription: 'Tieni premuto SALTO in aria per planare.',
    specialType: SpecialType.manager,
    specialName: 'Voglio il Manager!',
    specialDescription:
        'Un urlo di indignazione che spazza via i nemici vicini.',
    specialCooldown: 6,
    specialShout: 'VOGLIO PARLARE COL MANAGER!',
    hurtLines: ['Inaccettabile.', 'Lo segnalo.', 'La parrucca NO!'],
  );

  static const stareCat = MemeCharacter(
    id: 'stare_cat',
    name: 'Stare Cat',
    memeAlias: 'Il gatto che ti fissa',
    tagline: 'Occhi sgranati. Zero battiti di ciglia.',
    lore:
        'Il gatto rosso a pochi centimetri dalla fotocamera, con gli occhi '
        'sgranati e l\'espressione di chi ha visto la tua cronologia. '
        'Non dice niente. Non serve.',
    color: Color(0xFFF2994A),
    hearts: 3,
    runSpeed: 155,
    jumpSpeed: 500,
    passive: Passive.doubleJump,
    passiveName: 'Riflessi Felini',
    passiveDescription: 'Doppio salto.',
    specialType: SpecialType.stare,
    specialName: 'Il Fissatore',
    specialDescription:
        'Fissa tutti: i nemici si congelano dal disagio e diventano '
        'piattaforme su cui saltare.',
    specialCooldown: 9,
    specialShout: '*TI FISSA*',
    hurtLines: ['...', 'mrrp?!', '👁️👄👁️'],
  );

  static const robberDog = MemeCharacter(
    id: 'robber_dog',
    name: 'Robber Chihuahua',
    memeAlias: 'Il chihuahua col passamontagna',
    tagline: 'Passamontagna, coltello e nessun rimorso.',
    lore:
        'Seduto sul divano con il passamontagna nero e un coltello in '
        'zampa, ti guarda di lato. Non è chiaro cosa voglia, ma lo '
        'otterrà.',
    color: Color(0xFF3A3A3A),
    hearts: 3,
    runSpeed: 185,
    jumpSpeed: 510,
    passive: Passive.sprint,
    passiveName: 'Fuga Rapida',
    passiveDescription: 'È il più veloce di tutti.',
    specialType: SpecialType.heist,
    specialName: 'La Rapina',
    specialDescription:
        'Scatto in avanti invulnerabile (anche in aria) che trafigge i '
        'nemici e arraffa i like.',
    specialCooldown: 2.5,
    specialShout: 'QUESTA È UNA RAPINA!',
    hurtLines: ['Ehi!', 'Mi hai visto?', 'Non sono stato io.'],
  );

  static const smileDog = MemeCharacter(
    id: 'smile_dog',
    name: 'Smile Dog',
    memeAlias: 'Il cane che sorride (troppo)',
    tagline: 'Un sorriso sfocato che non dimenticherai.',
    lore:
        'Il pinscher nero che sorride alla fotocamera mostrando tutti i '
        'denti, in una foto sfocatissima. Sembra felice. Forse troppo. '
        'Nessuno regge quel sorriso a lungo.',
    color: Color(0xFF8E44AD),
    hearts: 4,
    runSpeed: 140,
    jumpSpeed: 515,
    passive: Passive.tough,
    passiveName: 'Pelle Dura',
    passiveDescription:
        '4 cuori invece di 3; schiaccia i Boomer al primo colpo.',
    specialType: SpecialType.cursedSmile,
    specialName: 'Sorriso Maledetto',
    specialDescription:
        'Sorride. I nemici vicini scappano terrorizzati e muoiono al '
        'primo contatto.',
    specialCooldown: 9,
    specialShout: 'SORRIDI :)',
    hurtLines: [':)', ':))', ':)))'],
  );

  static const pigtailDog = MemeCharacter(
    id: 'pigtail_dog',
    name: 'Puffer Pinscher',
    memeAlias: 'Il pinscher col piumino e le treccine',
    tagline: 'Treccine, piumino e scarpe della domenica.',
    lore:
        'Il pinscher in piedi come una persona, con le treccine nere, il '
        'piumino blu, i calzini bianchi e le scarpe di vernice. Ha '
        'l\'aria di chi sta andando a scuola e non ha fatto i compiti.',
    color: Color(0xFF2F5BD3),
    hearts: 3,
    runSpeed: 150,
    jumpSpeed: 510,
    passive: Passive.puffy,
    passiveName: 'Piumino Imbottito',
    passiveDescription: 'Il primo colpo di ogni livello lo assorbe il piumino.',
    specialType: SpecialType.braidSpin,
    specialName: 'Frullatore di Treccine',
    specialDescription:
        'Gira su se stessa frustando i nemici vicini con le treccine '
        '(e in aria fa un saltino).',
    specialCooldown: 3,
    specialShout: 'TRECCINE AL VENTO!',
    hurtLines: ['Il piumino!', 'Mi hai spettinata!', 'Le treccine NO!'],
  );

  static const pearlTerrier = MemeCharacter(
    id: 'pearl_terrier',
    name: 'Lady Terrier',
    memeAlias: 'Il bull terrier con caschetto e perle',
    tagline: 'Caschetto, perle e maglioncino. Una signora.',
    lore:
        'Il bull terrier con la parrucca a caschetto, la collana di perle '
        'e il maglioncino verde. Ti guarda come una zia al pranzo di '
        'Natale che ti chiede quando ti sposi.',
    color: Color(0xFF5E7A4E),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 505,
    passive: Passive.jewels,
    passiveName: 'Like di Lusso',
    passiveDescription: 'Ogni like vale il doppio dei punti.',
    specialType: SpecialType.purse,
    specialName: 'Borsettata',
    specialDescription:
        'Un colpo di borsetta a chi le sta davanti. Si ricarica in un '
        'attimo.',
    specialCooldown: 1.2,
    specialShout: 'MA COME SI PERMETTE?!',
    hurtLines: ['Che maleducato!', 'Le mie perle!', 'Ai miei tempi...'],
  );

  static const suitDachshund = MemeCharacter(
    id: 'suit_dachshund',
    name: 'Ka-Chow Bassotto',
    memeAlias: 'Il bassotto in giacca e crocs di Saetta McQueen',
    tagline: 'Elegante sopra, Ka-chow sotto.',
    lore:
        'Il cucciolo di bassotto in completo nero, camicia bianca e '
        'cravatta... con ai piedi le crocs rosse di Saetta McQueen. '
        'Pronto per un matrimonio e per la Piston Cup.',
    color: Color(0xFFD62822),
    hearts: 3,
    runSpeed: 160,
    jumpSpeed: 500,
    passive: Passive.spikeProof,
    passiveName: 'Crocs Corazzate',
    passiveDescription: 'Cammina sulle spine senza farsi niente.',
    specialType: SpecialType.kachow,
    specialName: 'Ka-Chow!',
    specialDescription:
        'Turbo per 3 secondi: velocissimo, e chi tocca vola via.',
    specialCooldown: 8,
    specialShout: 'KA-CHOW!',
    hurtLines: ['La cravatta!', 'Ka-ouch!', 'Le crocs no!'],
  );

  static const cheeksDachshund = MemeCharacter(
    id: 'cheeks_dachshund',
    name: 'Bassotto Criceto',
    memeAlias: 'Il bassotto con le guance piene',
    tagline: 'Ha nascosto qualcosa nelle guance. Tutto.',
    lore:
        'Il bassotto con le guance gonfie come un criceto e lo sguardo '
        'innocente. Nessuno sa cosa ci sia dentro. Lui non parla: '
        'non può.',
    color: Color(0xFF8B5A2B),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 505,
    passive: Passive.magnet,
    passiveName: 'Guance Capienti',
    passiveDescription: 'Risucchia i like vicini.',
    specialType: SpecialType.balloon,
    specialName: 'Gonfia Guance',
    specialDescription:
        'Si gonfia come un palloncino e vola verso l\'alto per un po\'.',
    specialCooldown: 7,
    specialShout: '*PFFFFF*',
    hurtLines: ['Mmmf!', '*sputa un like*', 'Mmh-mmh!'],
  );

  static const snowBaby = MemeCharacter(
    id: 'snow_baby',
    name: 'Bebè Pupazzo',
    memeAlias: 'Il bambolotto paffuto col pupazzo di neve',
    tagline: 'Paffuto, morbido e con un amico di neve.',
    lore:
        'Il bambolotto cicciottello con la tutina lilla che stringe il '
        'suo pupazzo di neve e lo morde un pochino. Non lo lascia mai. '
        'Mai.',
    color: Color(0xFFB39DDB),
    hearts: 3,
    runSpeed: 140,
    jumpSpeed: 500,
    passive: Passive.bouncy,
    passiveName: 'Pancino Gommoso',
    passiveDescription: 'Rimbalza altissimo quando schiaccia i nemici.',
    specialType: SpecialType.lullaby,
    specialName: 'Ninna Nanna',
    specialDescription: 'Recupera un cuore e fa addormentare i nemici vicini.',
    specialCooldown: 15,
    specialShout: 'NINNA NANNA~',
    hurtLines: ['Uèèè!', 'Il mio pupazzo!', '*singhiozzo*'],
  );

  static const pinkMonkey = MemeCharacter(
    id: 'pink_monkey',
    name: 'Scimmietta Rosa',
    memeAlias: 'La scimmietta col cappellino rosa e il peluche',
    tagline: 'Un cappellino rosa e un peluche da difendere.',
    lore:
        'La scimmietta col cappellino e la magliettina rosa che abbraccia '
        'il suo peluche come se fosse l\'ultima cosa al mondo. Ha uno '
        'sguardo tenerissimo. E una mira infallibile.',
    color: Color(0xFFFF6FA8),
    hearts: 3,
    runSpeed: 150,
    jumpSpeed: 500,
    passive: Passive.tripleJump,
    passiveName: 'Agilità da Scimmia',
    passiveDescription: 'Salto triplo.',
    specialType: SpecialType.plushThrow,
    specialName: 'Lancio del Peluche',
    specialDescription:
        'Lancia il peluche: stende il primo nemico che colpisce e torna '
        'indietro.',
    specialCooldown: 2,
    specialShout: 'PRENDI!',
    hurtLines: ['Uh-uh-ah!', 'Il peluche!', '*broncio*'],
  );

  static const shrekKid = MemeCharacter(
    id: 'shrek_kid',
    name: 'Baby Orco',
    memeAlias: "L'orco verde col caschetto e la cravatta",
    tagline: 'Caschetto, camicia e cravatta: primo giorno di scuola.',
    lore:
        'Un orco verde dalle guance paffute, col caschetto nero a '
        'scodella, la camicia bianca e la cravatta blu. Ha la faccia di '
        'chi vuole solo tornare nella sua palude.',
    color: Color(0xFF8BC34A),
    hearts: 3,
    runSpeed: 140,
    jumpSpeed: 505,
    passive: Passive.onion,
    passiveName: 'Strati di Cipolla',
    passiveDescription:
        'Gli orchi sono come le cipolle: recupera un cuore a ogni '
        'checkpoint.',
    specialType: SpecialType.swampSlam,
    specialName: 'Esci dalla mia Palude!',
    specialDescription:
        'Si schianta a terra con un\'onda d\'urto che spazza via i nemici.',
    specialCooldown: 6,
    specialShout: 'ESCI DALLA MIA PALUDE!',
    hurtLines: ['Orco-ahi!', 'La cravatta!', 'Che cipolla!'],
  );

  static const earsDog = MemeCharacter(
    id: 'ears_dog',
    name: 'Orecchione',
    memeAlias: 'Il chihuahua con orecchie e denti umani',
    tagline: 'Orecchie umane. Denti umani. Perché?',
    lore:
        'Il chihuahua con due enormi orecchie umane e un sorriso a '
        'trentadue denti, decisamente umani. Ti sorride come un '
        'venditore di auto usate. Non comprare niente.',
    color: Color(0xFFE57373),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 560,
    passive: Passive.highJump,
    passiveName: 'Orecchie a Molla',
    passiveDescription: 'Salta più in alto di tutti.',
    specialType: SpecialType.teethFlash,
    specialName: 'Dentiera Smagliante',
    specialDescription:
        'Un sorriso così bianco che acceca e stende tutti i nemici sullo '
        'schermo.',
    specialCooldown: 14,
    specialShout: '*SORRISO SMAGLIANTE*',
    hurtLines: ['Ehm.', 'I miei denti!', '*sorriso tirato*'],
  );

  static const dripPig = MemeCharacter(
    id: 'drip_pig',
    name: 'Maiale Drip',
    memeAlias: 'Il maiale con la sfumatura, le AirPods e la catena',
    tagline: 'Sfumatura fresca, AirPods e catena d\'oro.',
    lore:
        'Un maiale con un taglio sfumato da barbiere, le AirPods nelle '
        'orecchie e una catena d\'oro grossa così. Ha più stile di te e lo '
        'sa benissimo.',
    color: Color(0xFFE0A93B),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 505,
    passive: Passive.drip,
    passiveName: 'Catena d\'Oro',
    passiveDescription: 'I nemici sconfitti valgono il triplo dei punti.',
    specialType: SpecialType.airpods,
    specialName: 'Cancellazione del Rumore',
    specialDescription:
        'Mette le AirPods: per 4 secondi non sente niente e niente lo '
        'ferisce.',
    specialCooldown: 12,
    specialShout: 'NON TI SENTO, HO LE AIRPODS',
    hurtLines: ['Oink?!', 'La catena!', 'Mi hai rovinato la sfumatura.'],
  );

  static const bowlChick = MemeCharacter(
    id: 'bowl_chick',
    name: 'Pulcino Caschetto',
    memeAlias: 'Il pulcino col caschetto nero',
    tagline: 'Un pulcino. Con il caschetto. Perfetto.',
    lore:
        'Un pulcino giallo con un caschetto nero a scodella tagliato col '
        'righello e uno sguardo di profilo pieno di dignità. Il suo '
        'barbiere è un genio.',
    color: Color(0xFFFFD23F),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 500,
    passive: Passive.featherweight,
    passiveName: 'Pulcino Leggero',
    passiveDescription: 'Pesa niente: salti lunghi e lenti.',
    specialType: SpecialType.chickArmy,
    specialName: 'Cip Cip!',
    specialDescription:
        'Chiama tre pulcini col caschetto che corrono avanti e '
        'travolgono i nemici.',
    specialCooldown: 6,
    specialShout: 'CIP CIP CIP!',
    hurtLines: ['Pio!', 'Il caschetto!', 'Cip?!'],
  );

  static const helmetPigeon = MemeCharacter(
    id: 'helmet_pigeon',
    name: 'Piccione Casco',
    memeAlias: 'Il piccione con lo strano casco in testa',
    tagline: 'Sicurezza prima di tutto.',
    lore:
        'Un piccione di città con in testa un cappuccio di gomma che '
        'nessuno sa come sia finito lì. Lui non fa una piega: cammina '
        'fiero come un cavaliere con l\'elmo.',
    color: Color(0xFF6A8CA0),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 500,
    passive: Passive.helmet,
    passiveName: 'Casco Protettivo',
    passiveDescription:
        'I commenti RATIO degli Hater gli rimbalzano sul casco.',
    specialType: SpecialType.flight,
    specialName: 'Volo Urbano',
    specialDescription: 'Vola per 2,5 secondi: tieni premuto SALTO per salire.',
    specialCooldown: 8,
    specialShout: 'TUBA TUBA!',
    hurtLines: ['Tru?!', 'Il casco!', 'Grrr-uu.'],
  );

  static const pietroPigeon = MemeCharacter(
    id: 'pietro_pigeon',
    name: 'Pietro',
    memeAlias: 'Pietro is calling... il piccione con le Converse',
    tagline: 'Ti sta chiamando. Rispondi.',
    lore:
        'Pietro è un piccione in piedi con un paio di Converse ai piedi '
        'che ti chiama in videochiamata. Non sai cosa voglia. Ma prima o '
        'poi dovrai rispondere.',
    color: Color(0xFF7A7A86),
    hearts: 3,
    runSpeed: 150,
    jumpSpeed: 500,
    passive: Passive.sneakers,
    passiveName: 'Converse ai Piedi',
    passiveDescription: 'Accelera e frena all\'istante.',
    specialType: SpecialType.phoneCall,
    specialName: 'Pietro is calling...',
    specialDescription:
        'Tutti i nemici sullo schermo si fermano a rispondere al '
        'telefono (e diventano piattaforme).',
    specialCooldown: 10,
    specialShout: 'PIETRO IS CALLING...',
    hurtLines: ['Chiamata persa.', 'Tuuu tuuu...', 'Le Converse!'],
  );

  static const bikeDog = MemeCharacter(
    id: 'bike_dog',
    name: 'Cane in Bici',
    memeAlias: 'Il cane in bici con lo zaino, inseguito dalla Polis',
    tagline: 'Zaino in spalla, e la polizia dietro.',
    lore:
        'Un cane che pedala in mezzo al traffico con lo zaino in spalla, '
        'come se andasse a scuola. Dietro di lui una macchina della '
        'POLIS. Nessuno sa chi stia inseguendo chi.',
    color: Color(0xFF2E5AA8),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 500,
    passive: Passive.momentum,
    passiveName: 'Pedalata',
    passiveDescription:
        'Più pedala nella stessa direzione, più va veloce (fino a +50%).',
    specialType: SpecialType.police,
    specialName: 'POLIS!',
    specialDescription:
        'Arriva la macchina della polizia a sirene spiegate e investe '
        'tutti i nemici sulla sua strada.',
    specialCooldown: 9,
    specialShout: 'NII-NOO NII-NOO!',
    hurtLines: ['La catena della bici!', 'Ahia!', 'Lo zaino!'],
  );

  static const sneakerHen = MemeCharacter(
    id: 'sneaker_hen',
    name: 'Gallina Hypebeast',
    memeAlias: 'La gallina sulle Dunk panda coi dollari',
    tagline: 'Dunk panda e cento dollari sotto l\'ala.',
    lore:
        'Una gallina accovacciata su un paio di Dunk panda nuove di zecca, '
        'con una banconota da cento dollari infilata tra le piume. Non cova '
        'uova: cova hype.',
    color: Color(0xFFB5562A),
    hearts: 3,
    runSpeed: 145,
    jumpSpeed: 505,
    passive: Passive.hustle,
    passiveName: 'Hustler',
    passiveDescription:
        'Ogni like raccolto vale una volta e mezza nel portafoglio del '
        'negozio.',
    specialType: SpecialType.eggBomb,
    specialName: 'Uovo Bomba',
    specialDescription:
        'Depone un uovo che cade ed esplode stendendo i nemici vicini.',
    specialCooldown: 2.5,
    specialShout: 'COCCODÈ!',
    hurtLines: ['Coccodè?!', 'Le mie Dunk!', 'I miei soldi!'],
  );

  static const gtaBean = MemeCharacter(
    id: 'gta_bean',
    name: 'Mr. San Andreas',
    memeAlias: 'Mr. Bean dentro GTA San Andreas',
    tagline: 'Sopracciglio alzato e grafica PS2.',
    lore:
        'L\'omino più goffo della TV finito per sbaglio nelle strade di '
        'San Andreas, con la giacca marrone, la cravatta rossa e la '
        'faccia di chi non ha capito come ci è arrivato.',
    color: Color(0xFF6B4A32),
    hearts: 3,
    runSpeed: 150,
    jumpSpeed: 500,
    passive: Passive.respawnCheat,
    passiveName: 'Respawn all\'Ospedale',
    passiveDescription:
        'Cadere in un burrone non toglie cuori: WASTED e si riparte.',
    specialType: SpecialType.hesoyam,
    specialName: 'HESOYAM',
    specialDescription:
        'Il trucco più famoso: tutti i cuori ricaricati e 250 punti.',
    specialCooldown: 30,
    specialShout: 'CHEAT ACTIVATED',
    hurtLines: ['Ah.', 'Mmh?!', 'Ah, non di nuovo.'],
  );

  static const mashaMan = MemeCharacter(
    id: 'masha_man',
    name: 'Masha Baffuta',
    memeAlias: 'Masha col faccione da uomo',
    tagline: 'Fazzoletto rosa, baffi, nessuna paura.',
    lore:
        'Ha il fazzoletto rosa e il vestitino di Masha, ma la faccia è '
        'quella di un uomo adulto con i baffi e lo sguardo stanco. '
        'Anche Orso ha paura di lei.',
    color: Color(0xFFE0218A),
    hearts: 4,
    runSpeed: 140,
    jumpSpeed: 500,
    passive: Passive.bossBrawler,
    passiveName: 'Mani Pesanti',
    passiveDescription: '4 cuori e doppio danno a L\'Algoritmo.',
    specialType: SpecialType.superJump,
    specialName: 'Salto di Masha',
    specialDescription:
        'Un salto altissimo che lascia un\'onda d\'urto a terra.',
    specialCooldown: 5,
    specialShout: 'CIAO CIAO!',
    hurtLines: ['Ehi!', 'Orso, aiuto!', 'Mmh.'],
  );

  static const rockPatrick = MemeCharacter(
    id: 'rock_patrick',
    name: 'Patrick Roccia',
    memeAlias: 'Patrick con l\'elmo di roccia e le alghe',
    tagline: 'Elmo di roccia, alghe e un sorriso sdentato.',
    lore:
        'La stella marina più felice del fondale, con un sasso in testa '
        'come elmo, due ciuffi di alghe e un sorriso pieno di denti '
        'storti. Non pensa. Rotola.',
    color: Color(0xFFF08C82),
    hearts: 3,
    runSpeed: 140,
    jumpSpeed: 500,
    passive: Passive.rockHead,
    passiveName: 'Testa di Roccia',
    passiveDescription: 'Rompe i mattoni colpendoli con la testa.',
    specialType: SpecialType.rockRoll,
    specialName: 'Roccia Rotolante',
    specialDescription:
        'Si appallottola e rotola in avanti travolgendo i nemici.',
    specialCooldown: 5,
    specialShout: 'SONO UNA ROCCIA!',
    hurtLines: ['Ahia la roccia!', 'Eh?', 'Dov\'è la mia roccia?'],
  );

  static const bottlePatrick = MemeCharacter(
    id: 'bottle_patrick',
    name: 'Patrick Boccione',
    memeAlias: 'Patrick con la testa nel boccione d\'acqua',
    tagline: 'Sempre idratato. Purtroppo.',
    lore:
        'Patrick con la punta della testa infilata in un boccione '
        'd\'acqua capovolto, felice come sempre. Nessuno gli ha detto '
        'che non funziona così.',
    color: Color(0xFF5FB4E8),
    hearts: 3,
    runSpeed: 140,
    jumpSpeed: 505,
    passive: Passive.refill,
    passiveName: 'Sempre Idratato',
    passiveDescription: 'La speciale si ricarica il doppio più in fretta.',
    specialType: SpecialType.waterJet,
    specialName: 'Spruzzo d\'Acqua',
    specialDescription:
        'Uno spruzzo dal boccione che stende i nemici davanti a lui.',
    specialCooldown: 4,
    specialShout: 'GLU GLU!',
    hurtLines: ['Glub!', 'Il boccione!', 'Ho sete.'],
  );
}
