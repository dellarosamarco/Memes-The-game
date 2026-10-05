import 'package:flutter/material.dart';

/// How a character auto-attacks.
enum AttackType { hairFan, laserEyes, knifeSlash, smileAura }

/// The character's signature special move (manual, on cooldown).
enum SpecialType { manager, stare, heist, cursedSmile }

/// A playable meme. Every field here is meant to stay faithful to the
/// original meme's "identity": look, attitude and the joke it is known for.
class MemeCharacter {
  const MemeCharacter({
    required this.id,
    required this.name,
    required this.memeAlias,
    required this.tagline,
    required this.lore,
    required this.color,
    required this.maxHp,
    required this.speed,
    required this.damage,
    required this.attackCooldown,
    required this.attackType,
    required this.attackName,
    required this.attackDescription,
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

  final double maxHp;
  final double speed;
  final double damage;
  final double attackCooldown;

  final AttackType attackType;
  final String attackName;
  final String attackDescription;

  final SpecialType specialType;
  final String specialName;
  final String specialDescription;
  final double specialCooldown;

  /// Big caption shown on screen when the special is used.
  final String specialShout;

  /// Random lines shown when the character gets hit.
  final List<String> hurtLines;

  /// Path used by Flame's image cache (relative to assets/images/).
  String get spritePath => 'characters/$id.png';

  /// Full Flutter asset path of the portrait shown in menus.
  String get portraitAsset => 'assets/images/portraits/$id.jpg';

  static MemeCharacter byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static const all = [wigDog, stareCat, robberDog, smileDog];

  static const wigDog = MemeCharacter(
    id: 'wig_dog',
    name: 'Wig Dog',
    memeAlias: 'Il chihuahua con la parrucca',
    tagline: 'Caschetto perfetto. Sguardo giudicante. Vuole il manager.',
    lore:
        'Il chihuahua con il caschetto castano e lo sguardo di chi sta per '
        'lasciare una recensione da una stella. Non ha mai torto, '
        'e se ce l\'ha vuole comunque parlare col responsabile.',
    color: Color(0xFFB5651D),
    maxHp: 100,
    speed: 170,
    damage: 12,
    attackCooldown: 0.75,
    attackType: AttackType.hairFan,
    attackName: 'Colpo di Frangia',
    attackDescription: 'Lancia ciocche di capelli a ventaglio verso i nemici.',
    specialType: SpecialType.manager,
    specialName: 'Voglio il Manager!',
    specialDescription:
        'Un\'onda d\'urto di indignazione respinge e danneggia tutti i '
        'nemici vicini.',
    specialCooldown: 10,
    specialShout: 'VOGLIO PARLARE COL MANAGER!',
    hurtLines: ['Inaccettabile.', 'Lo segnalo.', 'La parrucca NO!'],
  );

  static const stareCat = MemeCharacter(
    id: 'stare_cat',
    name: 'Stare Cat',
    memeAlias: 'Il gatto che ti fissa',
    tagline: 'Occhi enormi. Zero battiti di ciglia. Ti sta giudicando.',
    lore:
        'Il gatto rosso a pochi centimetri dalla fotocamera, con gli occhi '
        'sgranati e l\'espressione di chi ha visto la tua cronologia. '
        'Non dice niente. Non serve.',
    color: Color(0xFFF2994A),
    maxHp: 80,
    speed: 190,
    damage: 9,
    attackCooldown: 0.42,
    attackType: AttackType.laserEyes,
    attackName: 'Sguardo Laser',
    attackDescription:
        'Raggi laser dagli occhi che trapassano più nemici in fila.',
    specialType: SpecialType.stare,
    specialName: 'Il Fissatore',
    specialDescription:
        'Fissa tutti. I nemici si paralizzano dal disagio e subiscono '
        'danni aumentati.',
    specialCooldown: 14,
    specialShout: '*TI FISSA INTENSAMENTE*',
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
    maxHp: 90,
    speed: 215,
    damage: 22,
    attackCooldown: 0.6,
    attackType: AttackType.knifeSlash,
    attackName: 'Fendente',
    attackDescription: 'Colpi di coltello ravvicinati a 360°: brutali.',
    specialType: SpecialType.heist,
    specialName: 'La Rapina',
    specialDescription:
        'Scatto invulnerabile che trafigge i nemici e ruba TUTTA l\'XP '
        'presente sulla mappa.',
    specialCooldown: 8,
    specialShout: 'QUESTA È UNA RAPINA!',
    hurtLines: ['Ehi!', 'Mi hai visto?', 'Non sono stato io.'],
  );

  static const smileDog = MemeCharacter(
    id: 'smile_dog',
    name: 'Smile Dog',
    memeAlias: 'Il cane che sorride (troppo)',
    tagline: 'Un sorriso sfocato che non dimenticherai mai.',
    lore:
        'Il pinscher nero che sorride alla fotocamera mostrando tutti i '
        'denti, in una foto sfocatissima. Sembra felice. Forse troppo. '
        'Nessuno regge quel sorriso a lungo.',
    color: Color(0xFF8E44AD),
    maxHp: 140,
    speed: 150,
    damage: 8,
    attackCooldown: 0.5,
    attackType: AttackType.smileAura,
    attackName: 'Aura Inquietante',
    attackDescription:
        'Chi gli sta vicino subisce danni continui da puro disagio.',
    specialType: SpecialType.cursedSmile,
    specialName: 'Sorriso Maledetto',
    specialDescription:
        'Sorride. Tutti i nemici in vista subiscono danni enormi e '
        'scappano terrorizzati. Recupera un po\' di vita.',
    specialCooldown: 15,
    specialShout: 'SORRIDI :)',
    hurtLines: [':)', ':))', ':)))'],
  );
}
