import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/hats.dart';
import '../../models/meme_character.dart';
import '../../services/sound.dart';
import '../components/body.dart';
import '../components/effects.dart';
import '../components/projectiles.dart';
import '../components/stage_render.dart';
import '../level.dart';
import '../memes_game.dart';
import '../physics.dart';
import '../pixel.dart';
import 'moves.dart';

part 'specials.dart';

/// Buttons a fighter reads each frame, from the human or from the CPU.
class FighterInput {
  /// Stick: -1 (left) .. 1 (right).
  double x = 0;
  bool up = false;
  bool down = false;
  bool jump = false;
  bool attack = false;
  bool special = false;
  bool shield = false;

  // Edges, cleared after every frame.
  bool jumpPressed = false;
  bool attackPressed = false;
  bool specialPressed = false;

  void pressJump() {
    jump = true;
    jumpPressed = true;
  }

  void pressAttack() {
    attack = true;
    attackPressed = true;
  }

  void pressSpecial() {
    special = true;
    specialPressed = true;
  }

  void endFrame() {
    jumpPressed = attackPressed = specialPressed = false;
  }

  void clear() {
    x = 0;
    up = down = jump = attack = special = shield = false;
    endFrame();
  }
}

enum FighterState {
  normal,
  attack,
  charge,
  hitstun,
  shield,
  roll,
  helpless,
  ko,
}

/// A meme in the arena.
class Fighter extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  Fighter({
    required this.character,
    required this.slot,
    required this.isCpu,
    required super.position,
    this.stocks = 3,
  }) : super(priority: 20) {
    bodyWidth = 24;
    bodyHeight = 44;
    facingRight = slot == 0;
  }

  final MemeCharacter character;

  /// 0 = player 1, 1 = CPU.
  final int slot;
  final bool isCpu;
  final FighterInput input = FighterInput();

  int stocks;
  double percent = 0;
  bool facingRight = true;
  FighterState state = FighterState.normal;

  // Stats for the results screen.
  double damageDealt = 0;
  int kos = 0;
  int falls = 0;
  int specialsUsed = 0;
  int smashKos = 0;

  // Movement.
  int airJumps = 0;
  bool usedRecovery = false;
  bool usedAirDodge = false;
  double _coyote = 0;
  double _dropTimer = 0;
  double _downHeld = 0;

  // Attacks.
  Move? move;
  double moveT = 0;
  double charge = 0;
  double _attackHeld = 0;
  bool _pendingTap = false;
  final Set<Fighter> _hitThisMove = {};
  int _hitsDone = 0;
  double _lag = 0;

  // Being hit.
  double hitstun = 0;
  double invincible = 0;
  bool tumbling = false;
  Fighter? lastHitBy;
  double lastHitByMove = 0;
  bool lastHitWasSmash = false;

  // Defence.
  double shieldHp = 50;
  double dizzy = 0;
  double _rollT = 0;
  double _dodgeT = 0;
  int _rollDir = 1;

  // Status effects from specials.
  double frozen = 0;
  double asleep = 0;
  double scared = 0;
  double slowed = 0;
  double armor = 0;
  double turbo = 0;
  double balloon = 0;
  double flight = 0;
  double spin = 0;
  double rolling = 0;
  double dash = 0;
  bool slamming = false;
  double specialTimer = 0;
  late bool puffer = character.passive == Passive.puffy;
  double _calm = 0;
  double _regen = 0;
  double _pedal = 0;
  int _pedalDir = 0;
  double _turboHit = 0;

  // Respawn.
  double koTimer = 0;
  Vector2 respawnAt = Vector2.zero();

  // Rendering.
  late final Strip _strip;
  late final Strip _hats;
  Strip? _altStrip;
  double _t = 0;
  double _squash = 1;
  double _spinAngle = 0;
  bool _wasOnGround = true;
  static final _rnd = Random();

  bool get alive => state != FighterState.ko && stocks > 0;
  bool get stunned => frozen > 0 || asleep > 0 || dizzy > 0;
  bool get intangible =>
      invincible > 0 ||
      state == FighterState.ko ||
      (state == FighterState.roll && _rollT > .08);
  bool get attacking => state == FighterState.attack;
  bool get shielding => state == FighterState.shield;
  bool get specialReady => specialTimer <= 0;
  double get specialProgress =>
      1 - (specialTimer / character.specialCooldown).clamp(0.0, 1.0);

  Vector2 get mid => position - Vector2(0, bodyHeight / 2);

  Iterable<Fighter> get opponents =>
      game.fighters.where((f) => f != this && f.alive);

  // ------------------------------------------------------------ stats

  double get weight => weightOf(character);

  /// How hard a meme is to launch (1 = average).
  static double weightOf(MemeCharacter c) =>
      switch (c.passive) {
        Passive.tough => 1.25,
        Passive.featherweight => .85,
        _ => 1.0,
      } *
      (c.hearts >= 4 ? 1.12 : 1);

  /// 0..1 ratings for the character select screen.
  static double speedRating(MemeCharacter c) =>
      ((c.runSpeed * (c.passive == Passive.sprint ? 1.1 : 1) +
              (c.passive == Passive.momentum ? 25 : 0) +
              (c.passive == Passive.sneakers ? 12 : 0)) -
          125) /
      70;

  static double jumpRating(MemeCharacter c) =>
      (c.jumpSpeed * (c.passive == Passive.highJump ? 1.06 : 1) - 495) / 80 +
      switch (c.passive) {
        Passive.doubleJump => .3,
        Passive.tripleJump => .6,
        Passive.glide || Passive.featherweight => .25,
        _ => 0,
      };

  static double weightRating(MemeCharacter c) => (weightOf(c) - .8) / .5;

  double get _runSpeed {
    var s = character.runSpeed * 1.2;
    if (character.passive == Passive.sprint) s *= 1.1;
    if (character.passive == Passive.momentum) {
      s *= 1 + .45 * min(1.0, _pedal / 1.5);
    }
    if (turbo > 0) s *= 1.7;
    if (scared > 0) s *= 1.15;
    return s;
  }

  double get _jumpSpeed {
    var s = character.jumpSpeed * 1.05;
    if (character.passive == Passive.highJump) s *= 1.06;
    return s;
  }

  int get _maxAirJumps => switch (character.passive) {
    Passive.doubleJump => 2,
    Passive.tripleJump => 3,
    _ => 1,
  };

  double get _timeScale => slowed > 0 ? .45 : 1;

  // ------------------------------------------------------------ loading

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache(character.spriteSheet), 60, 60);
    _hats = Strip(game.images.fromCache(Hat.sheet), Hat.width, Hat.height);
    final alt = character.afterSpecialSheet;
    if (alt != null) _altStrip = Strip(game.images.fromCache(alt), 60, 60);
    if (character.passive == Passive.featherweight)
      gravity = Phys.gravity * .82;
    respawnAt = position.clone();
    airJumps = _maxAirJumps;
  }

  @override
  Iterable<Surface> get extraPlatforms => game.platforms;

  // ------------------------------------------------------------ update

  @override
  void update(double dt) {
    super.update(dt);
    dt *= _timeScale;
    _t += dt;
    _timers(dt);

    if (state == FighterState.ko) {
      koTimer -= dt;
      if (koTimer <= 0 && stocks > 0) _respawn();
      return;
    }
    if (game.frozenFighters) {
      applyGravity(dt);
      moveAndCollide(dt);
      return;
    }

    final ride = standingOn;
    if (ride is MovingPlatform) position.x += ride.lastDx;

    if (stunned) {
      if (move != null || state == FighterState.charge) {
        move = null;
        state = FighterState.normal;
      }
      velocity.x *= pow(0.02, dt).toDouble();
      _airPhysics(dt, control: false);
    } else if (state == FighterState.hitstun) {
      _hitstunUpdate(dt);
    } else if (dash > 0 || rolling > 0) {
      _dashUpdate(dt);
    } else {
      switch (state) {
        case FighterState.shield:
          _shieldUpdate(dt);
        case FighterState.roll:
          _rollUpdate(dt);
        case FighterState.attack:
          _attackUpdate(dt);
        case FighterState.charge:
          _chargeUpdate(dt);
        case FighterState.helpless:
          _move(dt, airControl: .5);
        default:
          _normalUpdate(dt);
      }
    }

    final fallSpeed = velocity.y;
    moveAndCollide(dt);
    _ledgeClimb();
    _landing(fallSpeed, dt);
    _specialsAfterMove(dt);
  }

  void _timers(double dt) {
    // Stuns wear off faster in the air, so they can't force a fall.
    final stunDecay = onGround ? dt : dt * 3;
    if (frozen > 0) frozen -= stunDecay;
    if (_dodgeT > 0) {
      _dodgeT -= dt;
      // The dodge itself doesn't leave you helpless.
      if (_dodgeT <= 0 && state == FighterState.helpless && !usedRecovery) {
        state = FighterState.normal;
      }
    }
    if (hitstun > 0) hitstun -= dt;
    if (invincible > 0) invincible -= dt;
    if (asleep > 0) asleep -= stunDecay;
    if (scared > 0) scared -= dt;
    if (slowed > 0) slowed -= dt;
    if (armor > 0) armor -= dt;
    if (turbo > 0) turbo -= dt;
    if (dizzy > 0) dizzy -= dt;
    if (_lag > 0) _lag -= dt;
    if (_dropTimer > 0) {
      _dropTimer -= dt;
      dropThrough = _dropTimer > 0;
    }
    if (_turboHit > 0) _turboHit -= dt;
    if (specialTimer > 0) {
      specialTimer -= dt * (character.passive == Passive.refill ? 2 : 1);
    }
    if (state != FighterState.shield) {
      shieldHp = min(50, shieldHp + dt * 9);
    }
    // Passive healing: onion layers, total relax.
    _calm += dt;
    if (character.passive == Passive.onion && _calm > 3) {
      _regen += dt;
      if (_regen >= 2) {
        _regen = 0;
        percent = max(0, percent - 1);
      }
    }
    if (character.passive == Passive.chill &&
        onGround &&
        velocity.x.abs() < 5 &&
        _calm > 2) {
      _regen += dt;
      if (_regen >= 1) {
        _regen = 0;
        percent = max(0, percent - 1);
      }
    }
  }

  // ------------------------------------------------------------ movement

  void _airPhysics(double dt, {bool control = true}) {
    final fastFall =
        control && input.down && !onGround && velocity.y > 0 && move == null;
    maxFall = fastFall ? 980 : Phys.maxFall;
    if (fastFall && velocity.y < 700) velocity.y = 700;
    applyGravity(dt);
    if (character.passive == Passive.glide &&
        control &&
        input.jump &&
        velocity.y > 70 &&
        !onGround) {
      velocity.y = 70;
    }
  }

  void _move(double dt, {double airControl = 1}) {
    var x = input.x;
    if (scared > 0 && onGround) {
      // Run away from the scary smile... but not off a cliff.
      final o = opponents.firstOrNull;
      if (o != null) x = (position.x - o.position.x).sign;
      final ahead = ((position.x + x * 20) / kTile).floor();
      final row = (position.y / kTile).floor();
      if (!game.level.isStandable(ahead, row)) x = 0;
    }
    if (character.passive == Passive.momentum) {
      final dir = x.abs() > .3 ? x.sign.toInt() : 0;
      _pedal = dir != 0 && dir == _pedalDir && !hitWall ? _pedal + dt : 0;
      _pedalDir = dir;
    }
    final target = x * _runSpeed * (onGround ? 1 : .85);
    final sneakers = character.passive == Passive.sneakers ? 2.5 : 1.0;
    final accel = (onGround ? 2400.0 : 1500.0 * airControl) * sneakers;
    final reversing = target * velocity.x < 0 || (x.abs() < .2 && onGround);
    final a = accel * (reversing ? 1.6 : 1);
    velocity.x += (target - velocity.x).clamp(-a * dt, a * dt);
    if (x.abs() > .3 && onGround) facingRight = x > 0;
    if (x.abs() > .3 && !onGround && move == null) facingRight = x > 0;
    _airPhysics(dt);
  }

  void _normalUpdate(double dt) {
    if (onGround) {
      _coyote = .08;
      airJumps = _maxAirJumps;
      usedRecovery = false;
      usedAirDodge = false;
    } else {
      _coyote -= dt;
    }
    // Drop through one-way platforms by holding down.
    _downHeld = input.down ? _downHeld + dt : 0;
    if (onGround && _downHeld > .1 && _onOneWay) {
      _dropTimer = .22;
      dropThrough = true;
      position.y += 2;
      onGround = false;
    }

    if (input.specialPressed) {
      if (input.up) {
        _recovery();
      } else {
        useSpecial();
      }
      return;
    }
    if (input.shield) {
      if (onGround && _lag <= 0) {
        state = FighterState.shield;
        velocity.x = 0;
        return;
      } else if (!onGround && !usedAirDodge) {
        _airDodge();
        return;
      }
    }
    if (input.attackPressed && _lag <= 0 && scared <= 0) {
      if (onGround) {
        _pendingTap = true;
        _attackHeld = 0;
      } else {
        _startAerial();
        return;
      }
    }
    if (_pendingTap) {
      _attackHeld += dt;
      if (!input.attack) {
        _pendingTap = false;
        _startGroundAttack();
        return;
      }
      if (_attackHeld > .17) {
        _pendingTap = false;
        if (onGround) {
          state = FighterState.charge;
          charge = 0;
          velocity.x = 0;
          return;
        }
      }
    }
    if (input.jumpPressed && _lag <= 0) {
      if (_coyote > 0) {
        _jump(_jumpSpeed);
        Sound.play('jump', volume: .4);
      } else if (airJumps > 0) {
        airJumps--;
        _jump(_jumpSpeed * .95);
        _spinAngle = 2 * pi;
        Sound.play('double_jump', volume: .4);
        game.world.add(PoofEffect(position: position.clone()));
      }
    }
    if (!input.jump && velocity.y < -Phys.jumpCut && _jumpCuttable) {
      velocity.y = -Phys.jumpCut;
    }
    if (onGround) _jumpCuttable = false;
    _move(dt);
  }

  bool _jumpCuttable = false;

  void _jump(double speed) {
    velocity.y = -speed;
    _jumpCuttable = true;
    _coyote = 0;
    onGround = false;
    _squash = 1.18;
  }

  /// Falling just past the corner of an island: climb onto it (a forgiving
  /// take on Smash's ledge grab, friendlier on a touch screen).
  void _ledgeClimb() {
    if (onGround ||
        velocity.y <= 0 ||
        state == FighterState.hitstun ||
        input.down ||
        stunned) {
      return;
    }
    final level = game.level;
    for (final side in [-1, 1]) {
      final c = ((position.x + side * (bodyWidth / 2 + 8)) / kTile).floor();
      final r = (position.y / kTile).floor();
      // A solid tile whose top is just above our feet, with room on it.
      if (!level.isSolid(c, r) || level.isSolid(c, r - 1)) continue;
      if (level.isSolid(c, r - 2)) continue;
      final top = r * kTile.toDouble();
      if (position.y - top > 20) continue;
      position.y = top;
      position.x = side > 0 ? c * kTile + 10.0 : (c + 1) * kTile - 10.0;
      velocity.setZero();
      onGround = true;
      _wasOnGround = true;
      if (state == FighterState.helpless) state = FighterState.normal;
      if (state == FighterState.attack) _endMove();
      _lag = .12;
      airJumps = _maxAirJumps;
      usedRecovery = false;
      usedAirDodge = false;
      game.world.add(Dust(position: position.clone(), dx: -side * 18.0));
      Sound.play('land', volume: .3);
      return;
    }
  }

  bool get _onOneWay {
    final r = (position.y / kTile).floor();
    final c = (position.x / kTile).floor();
    return game.level.isOneWay(c, r) ||
        (standingOn != null && standingOn is MovingPlatform);
  }

  void _landing(double fallSpeed, double dt) {
    if (onGround && !_wasOnGround) {
      _squash = fallSpeed > 600 ? .66 : .8;
      game.world.add(Dust(position: position + Vector2(-8, 0), dx: -18));
      game.world.add(Dust(position: position + Vector2(8, 0), dx: 18));
      if (fallSpeed > 600) Sound.play('land', volume: .4);
      if (state == FighterState.helpless) state = FighterState.normal;
      // Landing in the middle of an aerial: a little lag.
      if (state == FighterState.attack && (move?.aerial ?? false)) {
        _lag = move!.landingLag;
        _endMove();
      }
      if (slamming) _slamImpact();
      tumbling = false;
    }
    _wasOnGround = onGround;
    _squash += (1 - _squash) * min(1.0, dt * 12);
    if (_spinAngle > 0) _spinAngle = max(0, _spinAngle - dt * 18);
    if (onGround) _spinAngle = 0;
  }

  // ------------------------------------------------------------ attacks

  void _startGroundAttack() {
    final x = input.x;
    Move m;
    if (velocity.x.abs() > _runSpeed * .75 && x.abs() > .5) {
      m = Moves.dash;
    } else if (input.up) {
      m = Moves.up;
    } else if (input.down) {
      m = Moves.down;
    } else if (x.abs() > .5) {
      facingRight = x > 0;
      m = Moves.forward;
    } else {
      m = Moves.jab;
    }
    _startMove(m);
  }

  void _startAerial() {
    Move m;
    if (input.up) {
      m = Moves.uair;
    } else if (input.down) {
      m = Moves.dair;
    } else if (input.x.abs() > .5) {
      facingRight = input.x > 0;
      m = Moves.fair;
    } else {
      m = Moves.nair;
    }
    _startMove(m);
  }

  void _startMove(Move m, {double chargeFactor = 1}) {
    move = m;
    moveT = 0;
    charge = chargeFactor;
    _hitThisMove.clear();
    _hitsDone = 0;
    state = FighterState.attack;
    if (m.lunge > 0) velocity.x = (facingRight ? 1 : -1) * m.lunge;
    Sound.play('jump', volume: .15);
  }

  void _endMove() {
    final wasRecovery = move == Moves.recovery;
    move = null;
    state = wasRecovery && !onGround
        ? FighterState.helpless
        : FighterState.normal;
  }

  void _attackUpdate(double dt) {
    final m = move!;
    moveT += dt;
    if (m.aerial) {
      _move(dt, airControl: .7);
    } else {
      final f = pow(0.004, dt).toDouble();
      velocity.x *= f;
      _airPhysics(dt, control: false);
    }
    // Multi-hit moves forget who they hit between hits.
    if (m.hits > 1) {
      final per = m.active / m.hits;
      final k = ((moveT - m.startup) / per).floor();
      if (k > _hitsDone && k < m.hits) {
        _hitsDone = k;
        _hitThisMove.clear();
      }
    }
    if (moveT >= m.total) _endMove();
  }

  void _chargeUpdate(double dt) {
    charge = min(1.2, charge + dt);
    velocity.x *= pow(0.001, dt).toDouble();
    if (input.x.abs() > .5) facingRight = input.x > 0;
    _airPhysics(dt, control: false);
    if (_t % .1 < dt) {
      game.world.add(
        Sparkles(position: mid + Vector2((_rnd.nextDouble() - .5) * 30, -10)),
      );
    }
    if (!input.attack || charge >= 1.2 || !onGround) {
      _startMove(Moves.smash, chargeFactor: 1 + .5 * min(1.0, charge));
      Sound.play('special', volume: .3);
    }
  }

  /// The current hitbox in world coordinates, if the move is active.
  Rect? get hitbox {
    final m = move;
    if (m == null || state != FighterState.attack) return null;
    if (moveT < m.startup || moveT > m.startup + m.active) return null;
    final b = m.box;
    final x = facingRight ? b.left : -b.right;
    return Rect.fromLTWH(position.x + x, position.y + b.top, b.width, b.height);
  }

  Rect get hurtbox => Rect.fromLTWH(
    position.x - bodyWidth / 2,
    position.y - bodyHeight,
    bodyWidth,
    bodyHeight,
  );

  /// Called by the game when [hitbox] overlaps [target].
  void tryHit(Fighter target) {
    final m = move;
    if (m == null || _hitThisMove.contains(target)) return;
    _hitThisMove.add(target);
    var dmg = m.damage * charge;
    var base = m.baseKb;
    var growth = m.kbGrowth;
    if (m.smash && character.passive == Passive.bossBrawler) growth *= 1.25;
    if (m.name == 'up' && character.passive == Passive.rockHead) dmg *= 2;
    // Centered moves send the target away from us; directional ones
    // follow our facing.
    final centered = m.box.left < 0;
    final right = centered ? target.position.x >= position.x : facingRight;
    target.receiveHit(
      attacker: this,
      damage: dmg,
      angle: m.angle,
      baseKb: base,
      kbGrowth: growth,
      towardsRight: right,
      smash: m.smash,
    );
  }

  /// Applies a hit (from a move, a special or a projectile).
  void receiveHit({
    required Fighter? attacker,
    required double damage,
    required double angle,
    required double baseKb,
    required double kbGrowth,
    required bool towardsRight,
    bool smash = false,
    bool projectile = false,
  }) {
    if (!alive || intangible) return;
    if (projectile && character.passive == Passive.helmet) {
      game.world.add(
        FloatingText(position: mid - Vector2(0, 30), text: 'TOC!', fontSize: 9),
      );
      return;
    }
    _calm = 0;
    if (shielding) {
      shieldHp -= damage * 1.5;
      velocity.x = (towardsRight ? 1 : -1) * (60 + damage * 12);
      Sound.play('block', volume: .6);
      game.hitStop(.03);
      if (shieldHp <= 0) _shieldBreak();
      return;
    }
    if (puffer) {
      // The puffer jacket takes the first hit of each life.
      puffer = false;
      invincible = .5;
      Sound.play('block');
      game.world.add(Confetti(position: mid, count: 14));
      game.world.add(
        FloatingText(
          position: mid - Vector2(0, 34),
          text: 'Piumino KO!',
          color: const Color(0xFF8CC8FF),
        ),
      );
      return;
    }
    if (character.passive == Passive.spikeProof) damage *= .85;
    percent = min(999, percent + damage);
    if (attacker != null) {
      attacker.damageDealt += damage;
      if (attacker.character.passive == Passive.magnet) {
        attacker.percent = max(0, attacker.percent - 1);
      }
      lastHitBy = attacker;
      lastHitWasSmash = smash;
    }
    asleep = 0;
    frozen = 0;
    final speed = Move.launchSpeed(
      base: baseKb,
      growth: kbGrowth,
      damage: damage,
      targetPercent: percent,
      weight: weight,
    );
    final heavy = speed > 650;
    final armored =
        armor > 0 ||
        (character.passive == Passive.rockSolid && damage < 6) ||
        slamming;
    // Feedback.
    game.hitStop((.03 + damage * .004).clamp(.03, .12));
    if (heavy) game.shake(.18, intensity: 3 + damage / 4);
    Sound.play(heavy ? 'boss_hit' : 'stomp', volume: heavy ? .7 : .5);
    game.world.add(HitSpark(position: mid.clone(), big: heavy));
    if (heavy && character.hurtLines.isNotEmpty && _rnd.nextDouble() < .4) {
      game.world.add(
        FloatingText(
          position: mid - Vector2(0, 46),
          text: character.hurtLines[_rnd.nextInt(character.hurtLines.length)],
          fontSize: 9,
          duration: 1,
        ),
      );
    }
    if (armored) {
      game.world.add(
        FloatingText(
          position: mid - Vector2(0, 30),
          text: 'ARMOR',
          fontSize: 8,
        ),
      );
      return;
    }
    final dir = Move.direction(angle, towardsRight);
    velocity.setValues(dir.dx * speed, dir.dy * speed);
    if (onGround && velocity.y > 0) velocity.y = -velocity.y * .6;
    hitstun = .12 + speed * .00055;
    tumbling = speed > 700;
    state = FighterState.hitstun;
    move = null;
    charge = 0;
    _pendingTap = false;
    dash = 0;
    rolling = 0;
    balloon = 0;
    flight = 0;
    onGround = false;
    // Getting hit gives your recovery back (like in Smash).
    usedRecovery = false;
    usedAirDodge = false;
  }

  void _hitstunUpdate(double dt) {
    // Knockback decays (air drag), gravity keeps pulling.
    velocity.x *= pow(0.12, dt).toDouble();
    applyGravity(dt);
    if (tumbling) _spinAngle = (_spinAngle + dt * 14) % (2 * pi);
    if (tumbling && _t % .05 < dt) {
      game.world.add(PoofEffect(position: mid.clone()));
    }
    if (hitstun <= 0) {
      state = FighterState.normal;
      tumbling = false;
      _spinAngle = 0;
      airJumps = max(airJumps, 1);
    }
  }

  // ------------------------------------------------------------ defence

  void _shieldUpdate(double dt) {
    shieldHp -= dt * 12;
    velocity.x *= pow(0.001, dt).toDouble();
    _airPhysics(dt, control: false);
    if (shieldHp <= 0) {
      _shieldBreak();
      return;
    }
    if (input.x.abs() > .7 && onGround) {
      _rollDir = input.x > 0 ? 1 : -1;
      _rollT = .32;
      state = FighterState.roll;
      Sound.play('skid', volume: .5);
      return;
    }
    if (input.jumpPressed) {
      state = FighterState.normal;
      _jump(_jumpSpeed);
      return;
    }
    if (!input.shield || !onGround) state = FighterState.normal;
  }

  void _rollUpdate(double dt) {
    _rollT -= dt;
    velocity.x = _rollDir * 430 * (_rollT / .32 + .2);
    _airPhysics(dt, control: false);
    if (_rollT <= 0) {
      state = FighterState.normal;
      facingRight = _rollDir < 0;
      _lag = .08;
    }
  }

  void _airDodge() {
    usedAirDodge = true;
    _dodgeT = .3;
    invincible = max(invincible, .26);
    velocity.x = input.x * 260;
    velocity.y = input.up ? -260 : (input.down ? 260 : velocity.y * .3);
    state = FighterState.helpless;
    Sound.play('skid', volume: .4);
    game.world.add(PoofEffect(position: mid.clone()));
  }

  void _shieldBreak() {
    shieldHp = 30;
    state = FighterState.normal;
    dizzy = 2.0;
    velocity.y = -380;
    Sound.play('gameover', volume: .4);
    game.world.add(
      FloatingText(
        position: mid - Vector2(0, 40),
        text: 'SCUDO ROTTO!',
        fontSize: 11,
        color: const Color(0xFFFFD86A),
      ),
    );
  }

  // ------------------------------------------------------------ recovery

  void _recovery() {
    if (usedRecovery) return;
    usedRecovery = true;
    if (input.x.abs() > .3) facingRight = input.x > 0;
    _startMove(Moves.recovery);
    velocity.y = -780;
    velocity.x = input.x * 240;
    _spinAngle = 2 * pi;
    Sound.play('spring', volume: .5);
    game.world.add(
      ShockwaveEffect(
        position: position.clone(),
        maxRadius: 30,
        color: character.color,
        duration: .25,
      ),
    );
  }

  // ------------------------------------------------------------ KO

  /// Blasted off the arena.
  void blastOff() {
    if (state == FighterState.ko) return;
    stocks--;
    falls++;
    final by = lastHitBy;
    if (by != null && by != this) {
      by.kos++;
      if (lastHitWasSmash) by.smashKos++;
    }
    state = FighterState.ko;
    koTimer = 1.4;
    velocity.setZero();
    move = null;
    lastHitBy = null;
  }

  void _respawn() {
    state = FighterState.normal;
    position.setFrom(respawnAt);
    velocity.setZero();
    percent = 0;
    invincible = character.passive == Passive.respawnCheat ? 4 : 2.2;
    airJumps = _maxAirJumps;
    usedRecovery = false;
    puffer = character.passive == Passive.puffy;
    frozen = asleep = scared = slowed = armor = turbo = 0;
    balloon = flight = spin = rolling = dash = 0;
    slamming = false;
    hitstun = 0;
    tumbling = false;
    shieldHp = 50;
    dizzy = 0;
    game.world.add(Sparkles(position: mid.clone()));
  }

  // ------------------------------------------------------------ render

  static const _idle = [0, 1];
  static const _run = [2, 3, 4, 5];

  int get _frame {
    if (state == FighterState.hitstun) return 7;
    if (!onGround) return velocity.y < 0 ? 6 : 7;
    if (velocity.x.abs() > 15) return _run[(_t * 12).floor() % 4];
    return _idle[(_t * 2.5).floor() % 2];
  }

  Strip get _sheet =>
      _altStrip != null && specialTimer > character.specialCooldown - .9
      ? _altStrip!
      : _strip;

  @override
  void render(Canvas canvas) {
    if (state == FighterState.ko) return;
    // Shadow.
    if (onGround) {
      canvas.drawOval(
        const Rect.fromLTRB(-14, -3, 14, 3),
        Paint()..color = const Color(0x333A2440),
      );
    }
    canvas.save();
    // Attack pose: lean into the swing.
    var lean = 0.0;
    var push = 0.0;
    final m = move;
    if (m != null && state == FighterState.attack) {
      final p = (moveT / m.total).clamp(0.0, 1.0);
      final swing = sin(p * pi);
      lean = (m.name == 'up' || m.name == 'uair')
          ? -0.0
          : (facingRight ? 1 : -1) * .35 * swing;
      push = (facingRight ? 1 : -1) * 6 * swing;
      if (m.name == 'nair' || m.name == 'recovery') {
        lean = (facingRight ? 1 : -1) * p * 2 * pi;
      }
    }
    if (state == FighterState.charge) {
      push = sin(_t * 60) * 1.5;
    }
    canvas.translate(push, 0);
    final sx = 1 + (1 - _squash) * .7;
    canvas.scale(sx, _squash);
    if (lean != 0 || _spinAngle > 0) {
      canvas.translate(0, -bodyHeight / 2);
      canvas.rotate(lean + (facingRight ? 1 : -1) * _spinAngle);
      canvas.translate(0, bodyHeight / 2);
    }
    final faceRight = spin > 0 ? (_t * 20).floor().isEven : facingRight;
    Paint? paint;
    if (state == FighterState.charge) {
      final a = .25 + .25 * sin(_t * 30);
      paint = Paint()
        ..colorFilter = ColorFilter.mode(
          Color.fromRGBO(255, 230, 120, a),
          BlendMode.srcATop,
        );
    } else if (frozen > 0) {
      paint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0x8840C4FF),
          BlendMode.srcATop,
        );
    } else if (armor > 0 || turbo > 0) {
      final hue = (_t * 540) % 360;
      paint = Paint()
        ..colorFilter = ColorFilter.mode(
          HSVColor.fromAHSV(.25, hue, .6, 1).toColor(),
          BlendMode.srcATop,
        );
    } else if (invincible > 0 && (_t * 14).floor().isEven) {
      paint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0x88FFFFFF),
          BlendMode.srcATop,
        );
    }
    _sheet.draw(
      canvas,
      _frame,
      const Offset(-30, -58),
      flip: !faceRight,
      paint: paint,
    );
    final hat = slot == 0 ? game.hat : null;
    if (hat != null) {
      final a = character.hatAnchor;
      final x = faceRight ? a.x : -a.x;
      _hats.draw(
        canvas,
        hat.index,
        Offset(
          x - Hat.width / 2,
          a.y - Hat.height + 3 + (_frame.isOdd ? 1 : 0),
        ),
        flip: !faceRight,
      );
    }
    canvas.restore();

    _renderSwoosh(canvas);
    if (shielding) _renderShield(canvas);
    if (stunned) _renderStars(canvas);
    _renderTag(canvas);
  }

  void _renderSwoosh(Canvas canvas) {
    final b = hitbox;
    if (b == null) return;
    final local = b.shift(Offset(-position.x, -position.y));
    final paint = Paint()
      ..color = (move!.smash ? const Color(0xFFFFE07A) : Colors.white)
          .withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = move!.smash ? 4 : 3;
    final m = move!;
    if (m.name == 'nair' || m.name == 'recovery' || m.name == 'down') {
      canvas.drawOval(local.deflate(2), paint);
    } else {
      // A front-facing arc, mirrored when facing left.
      final start = facingRight ? -pi * .45 : pi * .55;
      canvas.drawArc(local, start, pi * .9, false, paint);
    }
  }

  void _renderShield(Canvas canvas) {
    final r = 16 + 18 * (shieldHp / 50).clamp(0.0, 1.0);
    final c = slot == 0 ? const Color(0xFFFF82B4) : const Color(0xFF7CC8FF);
    canvas.drawCircle(
      Offset(0, -bodyHeight / 2),
      r,
      Paint()..color = c.withValues(alpha: .35),
    );
    canvas.drawCircle(
      Offset(0, -bodyHeight / 2),
      r,
      Paint()
        ..color = c.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderStars(Canvas canvas) {
    final p = Paint()..color = const Color(0xFFFFE07A);
    for (var i = 0; i < 3; i++) {
      final a = _t * 5 + i * 2 * pi / 3;
      canvas.drawCircle(Offset(cos(a) * 14, -62 + sin(a) * 4), 2.5, p);
    }
    if (asleep > 0 && _t % .6 < .02) {
      game.world.add(
        FloatingText(
          position: position - Vector2(-10, 64),
          text: 'z',
          fontSize: 9,
          color: const Color(0xFFB4C8FF),
          duration: .9,
        ),
      );
    }
  }

  void _renderTag(Canvas canvas) {
    // Little arrow over the head: pink for the player, blue for the CPU.
    final c = slot == 0 ? const Color(0xFFFF4F8E) : const Color(0xFF4FA8FF);
    final y = -66.0 - (_frame.isOdd ? 1 : 0);
    final path = Path()
      ..moveTo(-5, y)
      ..lineTo(5, y)
      ..lineTo(0, y + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF3A2440));
    canvas.drawPath(path.shift(const Offset(0, -1.5)), Paint()..color = c);
  }
}
