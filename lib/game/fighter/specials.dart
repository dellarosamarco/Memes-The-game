part of 'fighter.dart';

/// Every meme's signature move, adapted to a 1v1 fight.
extension FighterSpecials on Fighter {
  void _hit(
    Fighter o, {
    required double damage,
    double angle = 40,
    double base = 220,
    double growth = 6,
    bool? right,
    bool projectile = false,
  }) {
    o.receiveHit(
      attacker: this,
      damage: damage * _specialPower,
      angle: angle,
      baseKb: base,
      kbGrowth: growth,
      towardsRight: right ?? o.position.x >= position.x,
      projectile: projectile,
    );
  }

  double get _specialPower => character.passive == Passive.drip ? 1.2 : 1.0;

  Iterable<Fighter> _near(double radius) =>
      opponents.where((o) => o.mid.distanceTo(mid) < radius);

  void _shout() {
    game.world.add(
      FloatingText(
        // The CPU's shout sits a line higher so two shouts don't overlap.
        position: position - Vector2(0, slot == 0 ? 76 : 96),
        text: character.specialShout,
        fontSize: 11,
        duration: 1.3,
      ),
    );
  }

  /// Special button (without up): the meme's own move.
  void useSpecial() {
    if (!specialReady || !alive || stunned) return;
    specialTimer = character.specialCooldown;
    specialsUsed++;
    Sound.play('special', volume: .6);
    _shout();
    _calm = 0;
    final c = mid;
    final dir = facingRight ? 1 : -1;
    switch (character.specialType) {
      case SpecialType.manager:
        game.world.add(
          ShockwaveEffect(
            position: c,
            maxRadius: 110,
            color: const Color(0xFFFF7043),
          ),
        );
        for (final o in _near(110).toList()) {
          _hit(o, damage: 11, angle: 42, base: 300, growth: 7);
        }
        game.shake(.25);

      case SpecialType.stare:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x6640C4FF), duration: .4),
        );
        for (final o in _near(280)) {
          o.frozen = 1.5;
          o.velocity.x = 0;
        }

      case SpecialType.heist:
        dash = .28;
        invincible = max(invincible, .3);
        _hitThisMove.clear();

      case SpecialType.cursedSmile:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0xAA000000), duration: .6),
        );
        for (final o in _near(320)) {
          o.scared = 2.5;
        }

      case SpecialType.braidSpin:
        spin = .45;
        _hitThisMove.clear();
        if (!onGround) velocity.y = min(velocity.y, -320);

      case SpecialType.purse:
        final at = c + Vector2(dir * 30, 0);
        game.world.add(PoofEffect(position: at));
        for (final o in opponents.toList()) {
          final d = o.mid - c;
          if (d.x * dir > -6 && d.x * dir < 66 && d.y.abs() < 40) {
            _hit(
              o,
              damage: 13,
              angle: 35,
              base: 280,
              growth: 9,
              right: facingRight,
            );
          }
        }

      case SpecialType.kachow:
        turbo = 3;

      case SpecialType.balloon:
        balloon = 1.4;
        usedRecovery = true;

      case SpecialType.lullaby:
        percent = max(0, percent - 12);
        game.world.add(
          ShockwaveEffect(
            position: c,
            maxRadius: 220,
            color: const Color(0xFFB39DDB),
            duration: .7,
          ),
        );
        for (final o in _near(220)) {
          o.asleep = 1.6;
        }

      case SpecialType.plushThrow:
        game.world.add(FightProjectile.plush(this));

      case SpecialType.swampSlam:
        if (onGround) {
          _slamImpact();
        } else {
          slamming = true;
          velocity.x = 0;
        }

      case SpecialType.teethFlash:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0xEEFFFFFF), duration: .5),
        );
        for (final o in opponents.toList()) {
          o.frozen = .8;
          _hit(o, damage: 5, base: 60, growth: 0);
          o.frozen = .8;
        }

      case SpecialType.airpods:
        armor = 4;

      case SpecialType.chickArmy:
        for (var i = 0; i < 3; i++) {
          game.world.add(FightProjectile.chick(this, delay: i * .18));
        }

      case SpecialType.flight:
        flight = 2.5;
        usedRecovery = true;

      case SpecialType.phoneCall:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x5540E070), duration: .4),
        );
        for (final o in opponents) {
          o.frozen = 1.3;
          game.world.add(
            FloatingText(
              position: o.mid - Vector2(0, 36),
              text: 'Pronto?',
              fontSize: 9,
              color: const Color(0xFF7CFFA0),
              duration: 1.3,
            ),
          );
        }

      case SpecialType.police:
        game.world.add(FightProjectile.police(this));

      case SpecialType.eggBomb:
        game.world.add(FightProjectile.egg(this));

      case SpecialType.hesoyam:
        percent = max(0, percent - 25);
        game.world.add(Confetti(position: c, count: 30));

      case SpecialType.superJump:
        _jump(900);
        usedRecovery = true;
        game.world.add(
          ShockwaveEffect(
            position: position.clone(),
            maxRadius: 90,
            color: const Color(0xFFE0218A),
          ),
        );
        for (final o in _near(90).toList()) {
          _hit(o, damage: 8, angle: 70, base: 240, growth: 5);
        }

      case SpecialType.rockRoll:
        rolling = 1.1;
        _hitThisMove.clear();

      case SpecialType.waterJet:
        game.world.add(FightProjectile.waterJet(this));

      case SpecialType.rockThrow:
        game.world.add(FightProjectile.rock(this));

      case SpecialType.vacation:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x5540C4FF), duration: .5),
        );
        for (final o in opponents) {
          o.slowed = 3;
        }
    }
  }

  /// Dash-like specials (heist, rolling rock): fast, invulnerable rush.
  void _dashUpdate(double dt) {
    final dir = facingRight ? 1 : -1;
    if (dash > 0) {
      dash -= dt;
      velocity.setValues(dir * 470, 0);
      if (_t % .05 < dt) game.world.add(PoofEffect(position: mid.clone()));
    } else {
      rolling -= dt;
      velocity.x = dir * 320;
      applyGravity(dt);
      _spinAngle = 0.01 + (_t * 16) % (2 * pi);
      if (hitWall) rolling = 0;
    }
    for (final o in opponents.toList()) {
      if (_hitThisMove.contains(o) || !o.hurtbox.overlaps(hurtbox.inflate(6))) {
        continue;
      }
      _hitThisMove.add(o);
      _hit(
        o,
        damage: dash > 0 ? 10 : 11,
        angle: 38,
        base: 260,
        growth: 7,
        right: facingRight,
      );
    }
    if (dash <= 0 && rolling <= 0) {
      _spinAngle = 0;
      state = FighterState.normal;
    }
  }

  void _specialsAfterMove(double dt) {
    if (spin > 0) {
      spin -= dt;
      for (final o in _near(52).toList()) {
        if (_hitThisMove.contains(o)) continue;
        _hitThisMove.add(o);
        _hit(o, damage: 9, angle: 50, base: 240, growth: 6);
      }
    }
    if (turbo > 0 && _turboHit <= 0) {
      for (final o in opponents.toList()) {
        if (o.hurtbox.overlaps(hurtbox.inflate(4)) && velocity.x.abs() > 120) {
          _turboHit = .5;
          _hit(
            o,
            damage: 8,
            angle: 40,
            base: 230,
            growth: 6,
            right: velocity.x > 0,
          );
        }
      }
      if (_t % .06 < dt) {
        game.world.add(
          Dust(position: position.clone(), dx: -velocity.x.sign * 20),
        );
      }
    }
    if (balloon > 0) {
      balloon -= dt;
      velocity.y = balloon > 0 ? -150 : min(velocity.y, 0);
    }
    if (flight > 0) {
      flight -= dt;
      velocity.y = input.jump || input.up ? -220 : 60;
      if (_t % .2 < dt) game.world.add(PoofEffect(position: position.clone()));
    }
    if (slamming) velocity.y = 760;
    // Bouncy belly: landing on someone's head hurts them.
    if (character.passive == Passive.bouncy && velocity.y > 120) {
      for (final o in opponents.toList()) {
        final top = o.position.y - o.bodyHeight;
        if ((o.position.x - position.x).abs() < 22 &&
            position.y > top - 4 &&
            position.y < top + 14) {
          _hit(o, damage: 6, angle: -60, base: 160, growth: 3);
          velocity.y = -520;
        }
      }
    }
  }

  void _slamImpact() {
    slamming = false;
    _squash = .6;
    game.shake(.35, intensity: 5);
    Sound.play('boss_hit', volume: .7);
    game.world.add(
      ShockwaveEffect(
        position: position.clone(),
        maxRadius: 150,
        color: const Color(0xFF8BC34A),
      ),
    );
    for (final o in opponents.toList()) {
      final d = o.position - position;
      if (d.x.abs() < 150 && d.y.abs() < 70) {
        _hit(o, damage: 13, angle: 75, base: 260, growth: 7);
      }
    }
  }
}
