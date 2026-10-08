import 'dart:math';

import 'package:flutter/painting.dart';

/// One attack: timings, damage, knockback and where it hits.
///
/// Hitboxes are relative to the fighter's feet, with x pointing the way the
/// fighter faces. Knockback follows a Smash-like rule: the more damage (%)
/// the target has, the further it flies (see [Move.launchSpeed]).
class Move {
  const Move({
    required this.name,
    required this.startup,
    required this.active,
    required this.recovery,
    required this.damage,
    required this.angle,
    required this.baseKb,
    required this.kbGrowth,
    required this.box,
    this.lunge = 0,
    this.hits = 1,
    this.smash = false,
    this.aerial = false,
    this.landingLag = 0.08,
  });

  final String name;

  /// Seconds before the hitbox comes out / it stays out / after it.
  final double startup;
  final double active;
  final double recovery;

  /// Damage in % (multiplied by the charge for smash attacks).
  final double damage;

  /// Launch angle in degrees: 0 = forward, 90 = straight up, -90 = down.
  final double angle;
  final double baseKb;
  final double kbGrowth;

  /// Hitbox (left, top, width, height) relative to the feet, facing right.
  final Rect box;

  /// Forward speed added when the move starts.
  final double lunge;

  /// Multi-hit moves hit this many times during [active].
  final int hits;

  /// Can be charged by holding the attack button.
  final bool smash;
  final bool aerial;
  final double landingLag;

  double get total => startup + active + recovery;

  /// Speed (px/s) a target is launched at, given its damage after the hit.
  static double launchSpeed({
    required double base,
    required double growth,
    required double damage,
    required double targetPercent,
    double weight = 1,
  }) {
    final v = base + growth * targetPercent * (0.55 + damage / 22);
    return v / weight;
  }

  /// Launch direction for [facingRight] (y grows downwards).
  static Offset direction(double angleDeg, bool facingRight) {
    final a = angleDeg * pi / 180;
    return Offset(cos(a) * (facingRight ? 1 : -1), -sin(a));
  }
}

/// The moveset every meme shares (their specials make them unique).
class Moves {
  Moves._();

  static const jab = Move(
    name: 'jab',
    startup: .05,
    active: .06,
    recovery: .12,
    damage: 3,
    angle: 35,
    baseKb: 150,
    kbGrowth: 2,
    box: Rect.fromLTWH(4, -34, 30, 22),
  );

  static const forward = Move(
    name: 'forward',
    startup: .09,
    active: .08,
    recovery: .2,
    damage: 8,
    angle: 32,
    baseKb: 230,
    kbGrowth: 6.5,
    box: Rect.fromLTWH(6, -36, 38, 26),
    lunge: 120,
  );

  static const up = Move(
    name: 'up',
    startup: .07,
    active: .1,
    recovery: .18,
    damage: 7,
    angle: 88,
    baseKb: 250,
    kbGrowth: 6,
    box: Rect.fromLTWH(-22, -70, 44, 34),
  );

  static const down = Move(
    name: 'down',
    startup: .06,
    active: .08,
    recovery: .16,
    damage: 6,
    angle: 22,
    baseKb: 170,
    kbGrowth: 5,
    box: Rect.fromLTWH(-34, -14, 68, 14),
  );

  static const dash = Move(
    name: 'dash',
    startup: .07,
    active: .14,
    recovery: .26,
    damage: 9,
    angle: 48,
    baseKb: 230,
    kbGrowth: 6.5,
    box: Rect.fromLTWH(0, -38, 36, 32),
    lunge: 280,
  );

  static const smash = Move(
    name: 'smash',
    startup: .14,
    active: .1,
    recovery: .34,
    damage: 15,
    angle: 38,
    baseKb: 290,
    kbGrowth: 11,
    box: Rect.fromLTWH(8, -40, 46, 32),
    lunge: 90,
    smash: true,
  );

  static const nair = Move(
    name: 'nair',
    startup: .05,
    active: .2,
    recovery: .12,
    damage: 7,
    angle: 45,
    baseKb: 200,
    kbGrowth: 5.5,
    box: Rect.fromLTWH(-28, -46, 56, 46),
    aerial: true,
  );

  static const fair = Move(
    name: 'fair',
    startup: .08,
    active: .08,
    recovery: .18,
    damage: 9,
    angle: 38,
    baseKb: 230,
    kbGrowth: 7,
    box: Rect.fromLTWH(6, -40, 38, 30),
    aerial: true,
  );

  static const uair = Move(
    name: 'uair',
    startup: .06,
    active: .1,
    recovery: .15,
    damage: 8,
    angle: 85,
    baseKb: 230,
    kbGrowth: 6.5,
    box: Rect.fromLTWH(-24, -76, 48, 32),
    aerial: true,
  );

  static const dair = Move(
    name: 'dair',
    startup: .1,
    active: .1,
    recovery: .22,
    damage: 10,
    angle: -75,
    baseKb: 190,
    kbGrowth: 6,
    box: Rect.fromLTWH(-18, -8, 36, 26),
    aerial: true,
    landingLag: .18,
  );

  /// Universal recovery (special + up): a big spinning jump.
  static const recovery = Move(
    name: 'recovery',
    startup: .04,
    active: .3,
    recovery: .1,
    damage: 4,
    angle: 80,
    baseKb: 180,
    kbGrowth: 3,
    box: Rect.fromLTWH(-22, -54, 44, 54),
    hits: 2,
    aerial: true,
  );
}
