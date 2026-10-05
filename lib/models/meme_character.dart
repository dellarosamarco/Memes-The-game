import 'package:flutter/material.dart';

/// Movement perk every meme has all the time.
enum Passive { glide, doubleJump, sprint, tough }

/// Signature move, on a cooldown.
enum SpecialType { manager, stare, heist, cursedSmile }

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

  static const all = [wigDog, stareCat, robberDog, smileDog];

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
}
