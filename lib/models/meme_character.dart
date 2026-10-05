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
}
