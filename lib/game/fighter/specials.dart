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

  double get _specialPower =>
      (character.passive == Passive.drip ? 1.2 : 1.0) *
      (stonks > 0 ? 1.5 : 1.0);

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
    if (!specialReady || !alive || stunned || charmed > 0) return;
    specialTimer = character.specialCooldown;
    if (input.x.abs() < .3) _faceNearest(320);
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
        for (final o in _near(300).toList()) {
          o.frozen = 1.4;
          _hit(o, damage: 5, base: 60, growth: 0);
          o.frozen = 1.4;
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
          o.scared = 1.4;
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
              damage: 11,
              angle: 35,
              base: 280,
              growth: 7.5,
              right: facingRight,
            );
          }
        }

      case SpecialType.kachow:
        turbo = 2.5;

      case SpecialType.balloon:
        balloon = 1.4;
        usedRecovery = true;
        // Puffing up the cheeks shoves away whoever is too close.
        game.world.add(
          ShockwaveEffect(
            position: c,
            maxRadius: 75,
            color: const Color(0xFFFFB3C7),
          ),
        );
        for (final o in _near(75).toList()) {
          _hit(o, damage: 9, angle: 60, base: 270, growth: 5.5);
        }

      case SpecialType.lullaby:
        percent = max(0, percent - 5);
        game.world.add(
          ShockwaveEffect(
            position: c,
            maxRadius: 180,
            color: const Color(0xFFB39DDB),
            duration: .7,
          ),
        );
        for (final o in _near(180)) {
          o.asleep = .85;
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
        for (final o in _near(280).toList()) {
          o.frozen = .9;
          _hit(o, damage: 6, base: 60, growth: 0);
          o.frozen = .9;
        }

      case SpecialType.airpods:
        armor = 5;

      case SpecialType.chickArmy:
        for (var i = 0; i < 3; i++) {
          game.world.add(FightProjectile.chick(this, delay: i * .18));
        }

      case SpecialType.flight:
        flight = 2.5;
        usedRecovery = true;
        // Take-off: a wing gust.
        game.world.add(PoofEffect(position: c));
        for (final o in _near(80).toList()) {
          _hit(o, damage: 8, angle: 40, base: 280, growth: 4.5);
        }

      case SpecialType.phoneCall:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x5540E070), duration: .4),
        );
        for (final o in opponents.toList()) {
          _hit(o, damage: 4, base: 60, growth: 0);
          o.frozen = 1.5;
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
          _hit(o, damage: 10, angle: 70, base: 250, growth: 5.5);
        }

      case SpecialType.rockRoll:
        rolling = 1.1;
        _hitThisMove.clear();

      case SpecialType.waterJet:
        game.world.add(FightProjectile.waterJet(this));

      case SpecialType.rockThrow:
        game.world.add(FightProjectile.rock(this));

      case SpecialType.omg:
        game.world.add(
          ShockwaveEffect(
            position: c,
            maxRadius: 100,
            color: const Color(0xFFFFF3A0),
          ),
        );
        game.shake(.2);
        for (final o in _near(100).toList()) {
          _hit(o, damage: 7, angle: 50, base: 160, growth: 2);
          o.dizzy = max(o.dizzy, .7);
        }

      case SpecialType.skyBeam:
        final target = opponents.firstOrNull;
        if (target != null) game.world.add(FightProjectile.beam(this, target));

      case SpecialType.timeOut:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x66FFFFFF), duration: .5),
        );
        percent = max(0, percent - 4);
        for (final o in opponents.toList()) {
          o.frozen = max(o.frozen, .8);
          o.velocity.x = 0;
          game.world.add(
            FloatingText(
              position: o.mid - Vector2(0, 40),
              text: 'PAUSA',
              fontSize: 10,
              color: const Color(0xFF9AD0FF),
              duration: 1.1,
            ),
          );
        }

      case SpecialType.lecture:
        game.world.add(FightProjectile.lecture(this));

      case SpecialType.tongueGrab:
        game.world.add(FightProjectile.tongue(this));

      case SpecialType.charm:
        game.world.add(
          ShockwaveEffect(
            position: c,
            maxRadius: 240,
            color: const Color(0xFFFF9ECF),
            duration: .6,
          ),
        );
        for (final o in _near(240)) {
          o.charmed = 1.2;
        }

      case SpecialType.pounce:
        final target = opponents.firstOrNull;
        if (target != null && target.position.x != position.x) {
          facingRight = target.position.x > position.x;
        }
        final d = facingRight ? 1.0 : -1.0;
        // Aimed: about .6 s in the air, so it lands on the opponent.
        final gap = target == null
            ? 200.0
            : (target.position.x - position.x).abs();
        velocity.setValues(d * (gap / .55).clamp(150.0, 480.0), -430);
        invincible = max(invincible, .2);
        onGround = false;
        pounce = .9;
        _hitThisMove.clear();

      case SpecialType.vacation:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x5540C4FF), duration: .5),
        );
        for (final o in opponents) {
          o.slowed = 2.2;
        }
    }
  }

  /// Dash-like specials (heist, rolling rock): fast, invulnerable rush.
  void _dashUpdate(double dt) {
    final dir = facingRight ? 1 : -1;
    if (pounce > 0) {
      // A leap in an arc: the bite lands on whoever it touches.
      pounce -= dt;
      applyGravity(dt);
      if (onGround && pounce < .5) pounce = 0;
    } else if (dash > 0) {
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
        damage: pounce > 0 ? 12 : (dash > 0 ? 10 : 12),
        angle: 38,
        base: 260,
        growth: 7,
        right: facingRight,
      );
    }
    if (dash <= 0 && rolling <= 0 && pounce <= 0) {
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
        _hit(o, damage: 7, angle: 50, base: 230, growth: 4.5);
      }
    }
    if (turbo > 0 && _turboHit <= 0) {
      for (final o in opponents.toList()) {
        if (o.hurtbox.overlaps(hurtbox.inflate(4)) && velocity.x.abs() > 120) {
          // One big ram per turbo, then the engine cools down.
          _turboHit = .5;
          _hit(
            o,
            damage: 10,
            angle: 40,
            base: 270,
            growth: 7,
            right: velocity.x > 0,
          );
          turbo = min(turbo, .2);
        }
      }
      if (_t % .06 < dt) {
        game.world.add(
          Dust(position: position.clone(), dx: -velocity.x.sign * 20),
        );
      }
    }
    // Floating and flying stop well below the top blast line.
    final ceiling = -Stage.blastTop * kTile + kTile * 5;
    if (balloon > 0) {
      balloon -= dt;
      velocity.y = balloon > 0 && position.y > ceiling
          ? -150
          : min(velocity.y, 0);
    }
    if (flight > 0) {
      flight -= dt;
      velocity.y = (input.jump || input.up) && position.y > ceiling ? -220 : 60;
      if (_t % .2 < dt) game.world.add(PoofEffect(position: position.clone()));
    }
    if (slamming) velocity.y = 760;
    // Bouncy belly: landing on someone's head hurts them.
    // (Once in a while: no stomp chains.)
    if (character.passive == Passive.bouncy &&
        velocity.y > 120 &&
        _stompCd <= 0) {
      for (final o in opponents.toList()) {
        final top = o.position.y - o.bodyHeight;
        if ((o.position.x - position.x).abs() < 22 &&
            position.y > top - 4 &&
            position.y < top + 14) {
          _hit(o, damage: 4, angle: 80, base: 150, growth: 2.5);
          velocity.y = -520;
          _stompCd = 3;
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
        _hit(o, damage: 9, angle: 75, base: 250, growth: 6);
      }
    }
  }
}
