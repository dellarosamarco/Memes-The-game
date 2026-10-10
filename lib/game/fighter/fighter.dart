import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/hats.dart';
import '../../models/meme_character.dart';
import '../../services/sound.dart';
import '../components/body.dart';
import '../components/fight_items.dart';
import '../components/effects.dart';
import '../components/projectiles.dart';
import '../components/stage_render.dart';
import '../level.dart';
import '../memes_game.dart';
import '../physics.dart';
import '../pixel.dart';
import '../stages.dart';
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
    up = down = jump = attack = special = false;
    endFrame();
  }
}

enum FighterState {
  normal,
  attack,
  charge,
  hitstun,
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

  // Input buffer: a press slightly too early (during an attack, lag or a
  // landing) is remembered for a moment instead of being lost.
  static const _buffer = .15;
  double _bufAttack = 0;
  double _bufJump = 0;
  double _bufSpecial = 0;

  // Being hit.
  double hitstun = 0;
  double invincible = 0;
  bool tumbling = false;
  Fighter? lastHitBy;
  double lastHitByMove = 0;
  bool lastHitWasSmash = false;

  double dizzy = 0;

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

  // Items.
  double stonks = 0;
  double coffee = 0;
  double deal = 0;
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
  late final Strip _items;
  Strip? _altStrip;
  double _t = 0;
  double _squash = 1;
  double _spinAngle = 0;
  bool _wasOnGround = true;
  double _hitFlash = 0;
  double _dustCd = 0;
  final List<String> _recentMoves = [];

  /// Hits taken in the current combo (resets once you're free again).
  int _comboHits = 0;
  double _freeFor = 0;
  double _lastWiggle = 0;
  double _mashShake = 0;
  static final _rnd = Random();

  bool get alive => state != FighterState.ko && stocks > 0;
  bool get stunned => frozen > 0 || asleep > 0 || dizzy > 0;
  bool get intangible => invincible > 0 || state == FighterState.ko;
  bool get attacking => state == FighterState.attack;
  bool get specialReady => specialTimer <= 0;
  double get specialProgress =>
      1 - (specialTimer / character.specialCooldown).clamp(0.0, 1.0);

  Vector2 get mid => position - Vector2(0, bodyHeight / 2);

  Iterable<Fighter> get opponents =>
      game.fighters.where((f) => f != this && f.alive);

  // ------------------------------------------------------------ stats

  double get weight => weightOf(character);

  /// How hard a meme is to launch (1 = average).
  static double weightOf(MemeCharacter c) => switch (c.passive) {
    Passive.tough => 1.2,
    Passive.featherweight => .97,
    // Burly memes (4 hearts) are a bit heavier.
    _ => c.hearts >= 4 ? 1.1 : 1.0,
  };

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
    var s = character.runSpeed * 1.3;
    if (character.passive == Passive.sprint) s *= 1.1;
    if (character.passive == Passive.momentum) {
      s *= 1 + .45 * min(1.0, _pedal / 1.5);
    }
    if (turbo > 0) s *= 1.7;
    if (coffee > 0) s *= 1.3;
    if (scared > 0) s *= 1.15;
    return s;
  }

  double get _jumpSpeed {
    var s = character.jumpSpeed * (coffee > 0 ? 1.12 : 1.05);
    if (character.passive == Passive.highJump) s *= 1.06;
    return s;
  }

  int get _maxAirJumps => switch (character.passive) {
    Passive.doubleJump => 2,
    Passive.tripleJump => 3,
    _ => 1,
  };

  double get _timeScale => slowed > 0 ? .55 : 1;

  // ------------------------------------------------------------ loading

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache(character.spriteSheet), 60, 60);
    _hats = Strip(game.images.fromCache(Hat.sheet), Hat.width, Hat.height);
    _items = Strip(game.images.fromCache(FightItem.sheet), 16, 16);
    final alt = character.afterSpecialSheet;
    if (alt != null) _altStrip = Strip(game.images.fromCache(alt), 60, 60);
    if (character.passive == Passive.featherweight) {
      gravity = Phys.gravity * .9;
    }
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
      // Mash any button (or wiggle the stick) to break free sooner.
      final wiggle = input.x.abs() > .5 && input.x.sign != _lastWiggle;
      if (input.x.abs() > .5) _lastWiggle = input.x.sign;
      if (input.attackPressed ||
          input.jumpPressed ||
          input.specialPressed ||
          wiggle) {
        const mash = .1;
        if (frozen > 0) frozen -= mash;
        if (asleep > 0) asleep -= mash;
        if (dizzy > 0) dizzy -= mash;
        _mashShake = .08;
      }
      velocity.x *= pow(0.02, dt).toDouble();
      _airPhysics(dt, control: false);
    } else if (state == FighterState.hitstun) {
      _hitstunUpdate(dt);
    } else if (dash > 0 || rolling > 0) {
      _dashUpdate(dt);
    } else {
      switch (state) {
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
    if (hitstun > 0) hitstun -= dt;
    if (invincible > 0) invincible -= dt;
    if (asleep > 0) asleep -= stunDecay;
    if (scared > 0) scared -= dt;
    if (slowed > 0) slowed -= dt;
    if (armor > 0) armor -= dt;
    if (turbo > 0) turbo -= dt;
    if (dizzy > 0) dizzy -= dt;
    if (_hitFlash > 0) _hitFlash -= dt;
    if (_dustCd > 0) _dustCd -= dt;
    if (_mashShake > 0) _mashShake -= dt;
    _freeFor = state == FighterState.hitstun ? 0 : _freeFor + dt;
    if (stonks > 0) stonks -= dt;
    if (coffee > 0) coffee -= dt;
    if (deal > 0) deal -= dt;
    if (_lag > 0) _lag -= dt;
    if (input.attackPressed) _bufAttack = _buffer;
    if (input.jumpPressed) _bufJump = _buffer;
    if (input.specialPressed) _bufSpecial = _buffer;
    if (_bufAttack > 0) _bufAttack -= dt;
    if (_bufJump > 0) _bufJump -= dt;
    if (_bufSpecial > 0) _bufSpecial -= dt;
    if (_dropTimer > 0) {
      _dropTimer -= dt;
      dropThrough = _dropTimer > 0;
    }
    if (_turboHit > 0) _turboHit -= dt;
    if (specialTimer > 0) {
      specialTimer -= dt * (character.passive == Passive.refill ? 2 : 1);
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
    // Feet on the ground: a puff when you dash off, a skid when you turn.
    if (onGround && _dustCd <= 0) {
      final behind = position + Vector2(-velocity.x.sign * 10, 0);
      if (target * velocity.x < 0 && velocity.x.abs() > 120) {
        game.world.add(Dust(position: behind, dx: velocity.x.sign * 30));
        Sound.play('skid', volume: .25);
        _dustCd = .25;
      } else if (x.abs() > .6 && velocity.x.abs() < 30) {
        game.world.add(
          Dust(position: position + Vector2(-x.sign * 10, 0), dx: -x.sign * 26),
        );
        _dustCd = .3;
      }
    }
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
    } else {
      _coyote -= dt;
    }
    // Drop through one-way platforms by holding down.
    // (Not right after an attack: a down tilt must not drop you through.)
    _downHeld = input.down && _bufAttack <= 0 && !input.attack
        ? _downHeld + dt
        : 0;
    if (onGround && _downHeld > .12 && _onOneWay) {
      _dropTimer = .22;
      dropThrough = true;
      position.y += 2;
      onGround = false;
    }

    if (_bufSpecial > 0) {
      _bufSpecial = 0;
      if (input.up) {
        _recovery();
      } else {
        useSpecial();
      }
      return;
    }
    if (_bufAttack > 0 && _lag <= 0 && scared <= 0) {
      _bufAttack = 0;
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
          if (input.x.abs() <= .5) _faceNearest(110);
          Sound.play('charge', volume: .5);
          velocity.x = 0;
          return;
        }
      }
    }
    // Out of air jumps: the jump button triggers the recovery, so players
    // who don't know "up + special" (or are on a touch screen) can still
    // make it back.
    if (_bufJump > 0 &&
        _lag <= 0 &&
        _coyote <= 0 &&
        airJumps == 0 &&
        !onGround &&
        !usedRecovery &&
        velocity.y > -100) {
      _bufJump = 0;
      _recovery();
      return;
    }
    if (_bufJump > 0 && _lag <= 0 && (_coyote > 0 || airJumps > 0)) {
      _bufJump = 0;
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
    if (onGround) {
      // Kick-off dust from both feet.
      game.world.add(Dust(position: position + Vector2(-7, 0), dx: -22));
      game.world.add(Dust(position: position + Vector2(7, 0), dx: 22));
    }
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
      if (position.y - top > 20 || position.y - top < 3) continue;
      // Only when heading back to it, not when stepping off on purpose.
      if (input.x * side < 0 || velocity.x * side < -20) continue;
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
    if (x.abs() <= .5) _faceNearest(90);
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

  /// Aim assist for neutral inputs (handy on a touch screen): turn toward
  /// an opponent within [range].
  void _faceNearest(double range) {
    Fighter? best;
    var bestD = range;
    for (final o in opponents) {
      final d = (o.position.x - position.x).abs();
      if (d < bestD && (o.position.y - position.y).abs() < 90) {
        bestD = d;
        best = o;
      }
    }
    if (best != null && best.position.x != position.x) {
      facingRight = best.position.x > position.x;
    }
  }

  void _startMove(Move m, {double chargeFactor = 1}) {
    move = m;
    moveT = 0;
    charge = chargeFactor;
    _hitThisMove.clear();
    _hitsDone = 0;
    state = FighterState.attack;
    if (m.lunge > 0) velocity.x = (facingRight ? 1 : -1) * m.lunge;
    Sound.play('whoosh', volume: m.smash ? .6 : .35);
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
    // Stale moves (as in Smash): the same move landed over and over in a
    // row loses up to 40% of its power, so spamming one button is weak.
    final repeats = _recentMoves.where((n) => n == m.name).length;
    _recentMoves.add(m.name);
    if (_recentMoves.length > 6) _recentMoves.removeAt(0);
    final fresh = 1 - .07 * repeats;
    var dmg = m.damage * charge * (stonks > 0 ? 1.5 : 1) * fresh;
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
    if (character.passive == Passive.helmet) damage *= .9;
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
    // The hit that is going to send them flying gets the Smash treatment:
    // a longer freeze, a camera punch-in and a flash.
    final finisher = !armored && _wouldKo(angle, towardsRight, speed);
    if (finisher) {
      game.hitStop(.2);
      game.punchIn(mid);
      game.shake(.35, intensity: 7);
      game.camera.viewport.add(
        ScreenFlash(color: const Color(0x88FFFFFF), duration: .25),
      );
    } else {
      game.hitStop((.025 + damage * .003).clamp(.025, .08));
      if (heavy) game.shake(.18, intensity: 3 + damage / 4);
    }
    Sound.play(
      heavy ? 'hit_heavy' : 'hit_light',
      volume: heavy ? .8 : .6,
      // Bigger hits sound deeper; a little randomness keeps it lively.
      pitch: (heavy ? .92 : 1.08) - damage * .006 + _rnd.nextDouble() * .1,
    );
    game.world.add(HitSpark(position: mid.clone(), big: heavy));
    // Feel it in the hand: a tap when you land a hit, a thump when hit.
    if (!isCpu) {
      Sound.haptic(strong: true);
    } else if (attacker != null && !attacker.isCpu) {
      Sound.haptic(strong: heavy);
    }
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
    var dir = Move.direction(angle, towardsRight);
    // DI: holding a direction bends the launch by up to 15 degrees.
    final ix = input.x, iy = input.up ? -1.0 : (input.down ? 1.0 : 0.0);
    if (ix != 0 || iy != 0) {
      final perp = ix * -dir.dy + iy * dir.dx; // input across the launch
      final rot = perp.clamp(-1.0, 1.0) * 15 * pi / 180;
      final c = cos(rot), sn = sin(rot);
      dir = Offset(dir.dx * c - dir.dy * sn, dir.dx * sn + dir.dy * c);
    }
    velocity.setValues(dir.dx * speed, dir.dy * speed);
    _hitFlash = .14;
    if (onGround && velocity.y > 0) velocity.y = -velocity.y * .6;
    // Weak hits on the ground: slide back instead of hopping in place, so
    // fighters don't end up stacked trading jabs.
    if (onGround && speed < 450) {
      velocity.y = 0;
      final away = dir.dx == 0 ? (towardsRight ? 1.0 : -1.0) : dir.dx.sign;
      velocity.x = away * max(velocity.x.abs(), 230);
    }
    // Combo protection: every extra hit of a combo stuns a bit less, so a
    // fast jab can't keep someone locked forever.
    final caught = state == FighterState.hitstun || _freeFor < .25;
    _comboHits = caught ? _comboHits + 1 : 1;
    hitstun = (.12 + speed * .00055) / (1 + .3 * (_comboHits - 1));
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
  }

  /// Rough prediction: will a launch at [speed] carry us past a blast line?
  bool _wouldKo(double angle, bool right, double speed) {
    final d = Move.direction(angle, right);
    final stun = .12 + speed * .00055;
    final travel = d.dx * speed / 2.12 * (1 - pow(.12, stun));
    final vy = d.dy * speed;
    final rise = vy < 0 ? vy * vy / (2 * gravity) : 0.0;
    final zone = game.blastZone;
    final x = position.x + travel;
    return x < zone.left || x > zone.right || mid.y - rise < zone.top;
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

  // ------------------------------------------------------------ items

  void useItem(ItemKind kind) {
    switch (kind) {
      case ItemKind.sunglasses:
        deal = 6;
        invincible = max(invincible, 6);
      case ItemKind.stonks:
        stonks = 10;
      case ItemKind.pizza:
        percent = max(0, percent - 20);
      case ItemKind.coffee:
        coffee = 10;
      case ItemKind.bomb:
        break;
    }
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
    stonks = coffee = deal = 0;
    balloon = flight = spin = rolling = dash = 0;
    slamming = false;
    hitstun = 0;
    tumbling = false;
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

  /// Dev only (perf experiments).
  static bool debugHidden = false;

  @override
  void render(Canvas canvas) {
    if (state == FighterState.ko || debugHidden) return;
    // Shadow.
    if (onGround) {
      canvas.drawOval(
        const Rect.fromLTRB(-14, -3, 14, 3),
        Paint()..color = const Color(0x333A2440),
      );
    }
    canvas.save();
    // Attack pose in three beats: wind-up, strike (stretched toward the
    // hit) and back to rest.
    var lean = 0.0;
    var push = 0.0;
    var pushY = 0.0;
    var stretchX = 1.0;
    var stretchY = 1.0;
    final m = move;
    final fwd = facingRight ? 1.0 : -1.0;
    if (m != null && state == FighterState.attack) {
      final double k; // -1 wind-up .. 1 strike .. 0 rest
      if (moveT < m.startup) {
        k = -moveT / m.startup * .5;
      } else if (moveT < m.startup + m.active) {
        k = 1;
      } else {
        final r = ((moveT - m.startup - m.active) / m.recovery).clamp(0.0, 1.0);
        k = 1 - r * r * (3 - 2 * r);
      }
      final big = m.smash ? 1.4 : 1.0;
      switch (m.name) {
        case 'nair' || 'recovery':
          lean = fwd * (moveT / m.total).clamp(0.0, 1.0) * 2 * pi;
        case 'up' || 'uair':
          pushY = -7 * k;
          stretchY = 1 + .18 * k;
          stretchX = 1 - .1 * k;
        case 'down' || 'dair':
          pushY = 2 * k;
          stretchY = 1 - .15 * k;
          stretchX = 1 + .15 * k;
        default:
          lean = fwd * .3 * k * big;
          push = fwd * 8 * k * big;
          stretchX = 1 + .14 * k.clamp(0.0, 1.0) * big;
          stretchY = 1 - .06 * k.clamp(0.0, 1.0);
      }
    }
    if (state == FighterState.charge) {
      push = sin(_t * 60) * 1.5;
    }
    // Procedural life on top of the few sprite frames: breathing at rest,
    // a bouncy lean when running, stretch and squash through a jump.
    if (state == FighterState.normal && m == null) {
      if (onGround && velocity.x.abs() < 15) {
        final b = sin(_t * 3.2) * .022;
        stretchY *= 1 + b;
        stretchX *= 1 - b * .6;
      } else if (onGround) {
        final speed = (velocity.x.abs() / _runSpeed).clamp(0.0, 1.0);
        pushY -= sin(_t * pi * 6).abs() * 2.2 * speed;
        lean += (velocity.x > 0 ? 1 : -1) * .07 * speed;
      } else {
        final vy = (velocity.y / 600).clamp(-1.0, 1.0);
        stretchY *= 1 - vy * .07;
        stretchX *= 1 + vy * .05;
      }
    }
    // Just hit: shake in place during the impact freeze.
    final jitter = (_hitFlash > 0 && game.hitStopping) || _mashShake > 0
        ? Offset((_rnd.nextDouble() - .5) * 6, (_rnd.nextDouble() - .5) * 3)
        : Offset.zero;
    canvas.translate(push + jitter.dx, pushY + jitter.dy);
    final sx = (1 + (1 - _squash) * .7) * stretchX;
    canvas.scale(sx, _squash * stretchY);
    if (lean != 0 || _spinAngle > 0) {
      canvas.translate(0, -bodyHeight / 2);
      canvas.rotate(lean + (facingRight ? 1 : -1) * _spinAngle);
      canvas.translate(0, bodyHeight / 2);
    }
    final faceRight = spin > 0 ? (_t * 20).floor().isEven : facingRight;
    Paint? paint;
    if (_hitFlash > .06) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0xDDFFFFFF),
          BlendMode.srcATop,
        );
    } else if (state == FighterState.charge) {
      final a = .25 + .25 * sin(_t * 30);
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = ColorFilter.mode(
          Color.fromRGBO(255, 230, 120, a),
          BlendMode.srcATop,
        );
    } else if (frozen > 0) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0x8840C4FF),
          BlendMode.srcATop,
        );
    } else if (armor > 0 || turbo > 0 || deal > 0) {
      final hue = (_t * 540) % 360;
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = ColorFilter.mode(
          HSVColor.fromAHSV(.25, hue, .6, 1).toColor(),
          BlendMode.srcATop,
        );
    } else if (invincible > 0 && deal <= 0 && (_t * 14).floor().isEven) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0x88FFFFFF),
          BlendMode.srcATop,
        );
    }
    // Motion trail on strong strikes.
    final mv = move;
    if (mv != null &&
        hitbox != null &&
        (mv.smash || mv.lunge > 0 || mv.name == 'fair')) {
      for (final (dx, a) in [(-14.0, .18), (-7.0, .32)]) {
        _sheet.draw(
          canvas,
          _frame,
          Offset(-30 + dx * fwd, -58),
          flip: !faceRight,
          paint: Paint()
            ..filterQuality = FilterQuality.none
            ..color = Color.fromRGBO(255, 255, 255, a),
        );
      }
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
    if (stunned) _renderStars(canvas);
    _renderTag(canvas);
    _renderBuffs(canvas);
  }

  static final _smearFill = Paint();
  static final _smearEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// Attacks drawn as filled "smears" in the fighter's colour, shaped by
  /// the move, plus a glint telegraphing where a hit is about to land.
  void _renderSwoosh(Canvas canvas) {
    final m = move;
    if (state == FighterState.charge) {
      _renderChargeRing(canvas);
      return;
    }
    if (m == null || state != FighterState.attack) return;
    final b = m.box;
    final x = facingRight ? b.left : -b.right;
    final box = Rect.fromLTWH(x, b.top, b.width, b.height);
    final tag = slot == 0 ? const Color(0xFFFF6FA5) : const Color(0xFF63B4FF);
    final color = m.smash ? const Color(0xFFFFC94A) : tag;

    // Wind-up: a glint where the hit will land.
    if (moveT < m.startup) {
      final k = moveT / m.startup;
      _glint(
        canvas,
        box.center,
        5 + 9 * k,
        Colors.white.withValues(alpha: .45 + .5 * k),
      );
      return;
    }
    final afterActive = moveT - m.startup - m.active;
    if (afterActive > .12) return;
    final alpha = afterActive <= 0 ? .85 : .85 * (1 - afterActive / .12);
    final outer = box.inflate(m.smash ? 11 : 8);
    final w = outer.width, h = outer.height;
    final f = facingRight ? 1.0 : -1.0;
    final path = Path();
    switch (m.name) {
      case 'nair' || 'recovery':
        final spin = moveT * 22 * f;
        path.addArc(outer, spin, pi * 1.5);
        path.arcTo(
          outer.deflate(min(w, h) * .22),
          spin + pi * 1.5,
          -pi * 1.5,
          false,
        );
      case 'up' || 'uair':
        final inner = Rect.fromLTRB(
          outer.left + w * .12,
          outer.top + h * .38,
          outer.right - w * .12,
          outer.bottom + h * .2,
        );
        path.addArc(outer, pi * 1.05, pi * .9);
        path.arcTo(inner, pi * 1.95, -pi * .9, false);
      case 'down' || 'dair':
        final inner = Rect.fromLTRB(
          outer.left + w * .12,
          outer.top - h * .2,
          outer.right - w * .12,
          outer.bottom - h * .38,
        );
        path.addArc(outer, pi * .05, pi * .9);
        path.arcTo(inner, pi * .95, -pi * .9, false);
      default:
        // A crescent hugging the front edge of the hitbox.
        final inner = facingRight
            ? Rect.fromLTRB(
                outer.left - w * .3,
                outer.top + h * .16,
                outer.right - w * .32,
                outer.bottom - h * .16,
              )
            : Rect.fromLTRB(
                outer.left + w * .32,
                outer.top + h * .16,
                outer.right + w * .3,
                outer.bottom - h * .16,
              );
        final start = facingRight ? -pi * .5 : pi * .5;
        path.addArc(outer, start, pi);
        path.arcTo(inner, start + pi, -pi, false);
    }
    path.close();
    _smearFill.color = color.withValues(alpha: alpha * .75);
    canvas.drawPath(path, _smearFill);
    _smearEdge
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = m.smash ? 4 : 3;
    canvas.drawPath(path, _smearEdge);
    if (m.smash && afterActive <= 0) {
      _glint(canvas, box.center + Offset(f * w * .3, 0), 10, Colors.white);
    }
  }

  void _renderChargeRing(Canvas canvas) {
    final k = (charge / 1.2).clamp(0.0, 1.0);
    final c = Offset((facingRight ? 1 : -1) * 22, -26);
    _smearEdge
      ..color = const Color(0xFFFFE07A).withValues(alpha: .5 + .5 * k)
      ..strokeWidth = 2 + 2 * k;
    // The ring closes in as the smash charges up.
    canvas.drawCircle(c, 26 - 16 * k, _smearEdge);
    if (k > .95 && (_t * 16).floor().isEven) {
      _glint(canvas, c, 9, Colors.white);
    }
  }

  static final _glintPaint = Paint();

  void _glint(Canvas canvas, Offset c, double r, Color color) {
    _glintPaint.color = color;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * .25, c.dy - r * .25)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * .25, c.dy + r * .25)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * .25, c.dy + r * .25)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * .25, c.dy - r * .25)
      ..close();
    canvas.drawPath(path, _glintPaint);
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

  /// Active item effects as little icons floating over the head.
  void _renderBuffs(Canvas canvas) {
    final icons = [
      if (deal > 0) (ItemKind.sunglasses, deal),
      if (stonks > 0) (ItemKind.stonks, stonks),
      if (coffee > 0) (ItemKind.coffee, coffee),
    ];
    if (icons.isEmpty) return;
    var x = -icons.length * 9.0;
    for (final (kind, left) in icons) {
      // Blink in the last two seconds.
      if (left > 2 || (_t * 8).floor().isEven) {
        _items.draw(canvas, kind.index, Offset(x, -92 + sin(_t * 5) * 1.5));
      }
      x += 18;
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
