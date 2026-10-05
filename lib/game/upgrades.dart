import 'dart:math';

import '../models/meme_character.dart';

/// Mutable run-time stats, modified by level-up upgrades.
class PlayerStats {
  PlayerStats(this.character) : maxHp = character.maxHp;

  final MemeCharacter character;
  double maxHp;
  double damageMult = 1;
  double cooldownMult = 1;
  double speedMult = 1;
  double areaMult = 1;
  double specialCooldownMult = 1;
  double magnetRadius = 90;
  int extraProjectiles = 0;
  double regenPerSecond = 0;

  double get damage => character.damage * damageMult;
  double get attackCooldown => character.attackCooldown * cooldownMult;
  double get speed => character.speed * speedMult;
  double get specialCooldown => character.specialCooldown * specialCooldownMult;
}

class Upgrade {
  const Upgrade({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.apply,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;

  /// Applies the upgrade. Receives stats and a heal callback.
  final void Function(PlayerStats stats, void Function(double) heal) apply;

  static List<Upgrade> pool(MemeCharacter c) {
    final multiLabel = switch (c.attackType) {
      AttackType.hairFan => ('💇', 'Più Ciocche', '+1 ciocca per ventaglio'),
      AttackType.laserEyes => ('👀', 'Multi-Sguardo', '+1 bersaglio laser'),
      AttackType.knifeSlash => ('🔪', 'Coltelli Extra', '+1 coltello lanciato'),
      AttackType.smileAura => ('😁', 'Più Denti', 'Aura più ampia (+18%)'),
    };
    return [
      Upgrade(
        id: 'dmg',
        emoji: '💪',
        title: 'Big Brain',
        description: 'Danno +20%',
        apply: (s, _) => s.damageMult += 0.2,
      ),
      Upgrade(
        id: 'rate',
        emoji: '⚡',
        title: 'Spam',
        description: 'Attacchi più rapidi (+15%)',
        apply: (s, _) => s.cooldownMult *= 0.85,
      ),
      Upgrade(
        id: 'speed',
        emoji: '🏃',
        title: 'Zoomies',
        description: 'Velocità di movimento +12%',
        apply: (s, _) => s.speedMult += 0.12,
      ),
      Upgrade(
        id: 'hp',
        emoji: '❤️',
        title: 'Thicc',
        description: 'Vita massima +25 e cura 25',
        apply: (s, heal) {
          s.maxHp += 25;
          heal(25);
        },
      ),
      Upgrade(
        id: 'heal',
        emoji: '🍕',
        title: 'Pizza',
        description: 'Recupera il 50% della vita',
        apply: (s, heal) => heal(s.maxHp * .5),
      ),
      Upgrade(
        id: 'magnet',
        emoji: '🧲',
        title: 'Attira Like',
        description: 'Raggio di raccolta +40%',
        apply: (s, _) => s.magnetRadius *= 1.4,
      ),
      Upgrade(
        id: 'special',
        emoji: '🔥',
        title: 'Virale',
        description: '${c.specialName}: ricarica -15%',
        apply: (s, _) => s.specialCooldownMult *= 0.85,
      ),
      Upgrade(
        id: 'area',
        emoji: '🌀',
        title: 'Hype',
        description: 'Area degli attacchi +15%',
        apply: (s, _) => s.areaMult += 0.15,
      ),
      Upgrade(
        id: 'regen',
        emoji: '🧃',
        title: 'Succo di Mela',
        description: 'Rigenera 1 HP al secondo',
        apply: (s, _) => s.regenPerSecond += 1,
      ),
      Upgrade(
        id: 'multi',
        emoji: multiLabel.$1,
        title: multiLabel.$2,
        description: multiLabel.$3,
        apply: (s, _) {
          if (c.attackType == AttackType.smileAura) {
            s.areaMult += 0.18;
          } else {
            s.extraProjectiles++;
          }
        },
      ),
    ];
  }

  static List<Upgrade> roll(MemeCharacter c, Random rnd, {int count = 3}) {
    final p = pool(c)..shuffle(rnd);
    return p.take(count).toList();
  }
}
