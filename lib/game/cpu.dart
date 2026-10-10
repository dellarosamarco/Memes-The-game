import 'dart:math';

import '../models/meme_character.dart';
import 'components/fight_items.dart';
import 'fighter/fighter.dart';
import 'level.dart';
import 'memes_game.dart';
import 'stages.dart';

/// The CPU opponent: reads the situation every "reaction" tick and presses
/// buttons on its fighter's [FighterInput], like a player would.
class CpuBrain {
  CpuBrain(this.me, this.target, this.difficulty, {Random? random})
    : _rnd = random ?? Random();

  final Fighter me;
  final Fighter target;
  final Difficulty difficulty;
  final Random _rnd;

  double _tick = 0;
  double _attackHold = 0;
  double _downHold = 0;
  double _wander = 0;
  double _wanderDir = 0;
  bool _gapJump = false;

  /// How much the opponent has been swinging lately (decays): a CPU that
  /// sees the same attack coming again and again dodges and punishes it.
  double _threat = 0;
  bool _targetWasAttacking = false;
  bool _wasInHitstun = false;

  double get _reaction => switch (difficulty) {
    Difficulty.easy => .42,
    Difficulty.normal => .2,
    Difficulty.hard => .07,
  };

  double get _aggression => switch (difficulty) {
    Difficulty.easy => .45,
    Difficulty.normal => .65,
    Difficulty.hard => .95,
  };

  double get _evadeChance => switch (difficulty) {
    Difficulty.easy => .05,
    Difficulty.normal => .2,
    Difficulty.hard => .5,
  };

  double get _specialChance => switch (difficulty) {
    Difficulty.easy => .15,
    Difficulty.normal => .3,
    Difficulty.hard => .45,
  };

  MemesGame get _game => me.game;

  double get _adaptiveEvade => min(
    .8,
    _evadeChance + _threat * (difficulty == Difficulty.easy ? .03 : .12),
  );

  /// The opponent is stuck in the end lag of a move, right next to us.
  bool get _punishable {
    final m = target.move;
    if (m == null || !target.attacking) return false;
    if (target.moveT < m.startup + m.active) return false;
    final dx = target.position.x - me.position.x;
    final dy = target.mid.y - me.mid.y;
    return dx.abs() < 56 && dy.abs() < 34;
  }

  void think(double dt) {
    final i = me.input;
    if (!me.alive) {
      i.clear();
      return;
    }
    // Just got free from hitstun with the opponent on top of us: react at
    // once (jump away, back off or swing back), like a player escaping a
    // string of hits.
    final inHitstun = me.state == FighterState.hitstun;
    if (_wasInHitstun &&
        !inHitstun &&
        difficulty != Difficulty.easy &&
        me.onGround &&
        target.position.distanceTo(me.position) < 95) {
      _wasInHitstun = false;
      final away = (me.position.x - target.position.x).sign;
      final r = _rnd.nextDouble();
      if (r < .3) {
        i.x = away == 0 ? 1 : away;
        i.pressJump();
      } else if (r < .3 + _adaptiveEvade) {
        i.x = away == 0 ? 1 : away;
      } else {
        final dx = target.position.x - me.position.x;
        me.facingRight = dx > 0;
        i.x = 0;
        i.pressAttack();
        _attackHold = .02;
      }
      _tick = _reaction * .5;
      return;
    }
    _wasInHitstun = inHitstun;
    if (target.attacking && !_targetWasAttacking) _threat += 1;
    _targetWasAttacking = target.attacking;
    _threat *= pow(.5, dt).toDouble();
    // Punish end lag right away (no waiting for the next decision tick).
    if (difficulty != Difficulty.easy &&
        me.onGround &&
        !me.stunned &&
        me.state == FighterState.normal &&
        _punishable &&
        _rnd.nextDouble() < _aggression * dt * 12) {
      final dx = target.position.x - me.position.x;
      me.facingRight = dx > 0;
      _attack(dx, target.mid.y - me.mid.y);
      return;
    }
    // Held buttons keep being held between decisions.
    if (_attackHold > 0) {
      _attackHold -= dt;
      i.attack = _attackHold > 0;
    }
    if (_downHold > 0) {
      _downHold -= dt;
      i.down = _downHold > 0;
    }

    // Mid gap-jump: keep going, air jump at the top of the arc.
    if (_gapJump) {
      if (me.onGround || me.position.y > _stageTop + 4) {
        // Landed, or the jump fell short: the recovery takes over.
        _gapJump = false;
      } else {
        if (!me.onGround &&
            me.velocity.y > 0 &&
            me.airJumps > 0 &&
            !_groundBelow(me.position.x)) {
          i.jumpPressed = true;
        }
        i.jump = true;
        return;
      }
    }

    // Getting back to the stage can't wait for the next tick.
    if (_offstage) {
      _recover();
      return;
    }

    _tick -= dt;
    if (_tick > 0) {
      _guardEdges();
      return;
    }
    _tick = _reaction * (.7 + _rnd.nextDouble() * .6);
    _decide();
    _guardEdges();
  }

  double get _stageLeft => _game.stage.left * kTile;
  double get _stageRight => (_game.stage.right + 1) * kTile;
  double get _stageTop => _game.stage.mainTop * kTile;

  bool get _offstage =>
      !me.onGround &&
      (me.position.x < _stageLeft - 4 ||
          me.position.x > _stageRight + 4 ||
          me.position.y > _stageTop + 30 ||
          // Over a gap between islands, below the platforms.
          (me.position.y > _stageTop - 40 && !_groundBelow(me.position.x)));

  bool _standable(double x) =>
      _game.level.isStandable((x / kTile).floor(), _game.stage.mainTop);

  bool _groundBelow(double x) => _standable(x);

  /// X of the closest solid ground on the islands' top row.
  double _nearestGroundX() {
    final x = me.position.x;
    for (var d = 0.0; d < Stage.cols * kTile; d += kTile / 2) {
      if (_standable(x - d)) return x - d - kTile;
      if (_standable(x + d)) return x + d + kTile;
    }
    return (_stageLeft + _stageRight) / 2;
  }

  void _recover() {
    final i = me.input;
    var home = _nearestGroundX();
    // Under an island: slide out from underneath before going up, or
    // the recovery just bonks its head.
    final under = me.position.y > _stageTop + 8 && _standable(me.position.x);
    if (under) {
      for (var d = 0.0; d < Stage.cols * kTile; d += kTile / 2) {
        if (!_standable(me.position.x - d)) {
          home = me.position.x - d - kTile;
          break;
        }
        if (!_standable(me.position.x + d)) {
          home = me.position.x + d + kTile;
          break;
        }
      }
    }
    i.x = (home - me.position.x).sign;
    i.up = false;
    i.down = false;
    i.attack = false;
    if (me.state == FighterState.hitstun) return;
    final y = me.position.y;
    final falling = me.velocity.y > -60;
    // Horizontal gap to the nearest edge of the main island.
    final gap = (home - me.position.x).abs();
    final t = me.character.specialType;
    if ((t == SpecialType.balloon || t == SpecialType.flight) &&
        me.specialReady &&
        falling &&
        y > _stageTop - 80) {
      i.specialPressed = true;
    } else if (me.airJumps > 0 && falling && y > _stageTop - 110) {
      // Jump early, while there is still height to spare.
      i.jumpPressed = true;
      i.jump = true;
    } else if (!me.usedRecovery &&
        !under &&
        falling &&
        me.airJumps == 0 &&
        (y > _stageTop - 20 || gap > 150)) {
      i.up = true;
      i.specialPressed = true;
    }
    if (me.flight > 0) i.jump = y > _stageTop - 60;
  }

  /// Room behind us to hop back without falling off.
  bool _safeToRetreat(double dir) =>
      _standable(me.position.x + dir * kTile * 3);

  /// Don't walk off the stage by accident.
  void _guardEdges() {
    final i = me.input;
    if (!me.onGround || i.x.abs() < .1) return;
    final onMain = (me.position.y - _stageTop).abs() < 4;
    if (!onMain) return;
    final ahead = me.position.x + i.x.sign * kTile * 1.2;
    if (_standable(ahead)) return;
    // A gap: hop it if there's ground (and the target) on the other side,
    // otherwise stop at the edge.
    var across = false;
    for (var t = 2; t <= 8 && !across; t++) {
      across = _standable(me.position.x + i.x.sign * kTile * t);
    }
    final towardTarget = (target.position.x - me.position.x).sign == i.x.sign;
    if (across && towardTarget) {
      // Running jump; the approach logic adds the air jump if needed.
      i.jumpPressed = true;
      i.jump = true;
      _gapJump = true;
    } else {
      i.x = 0;
    }
  }

  void _decide() {
    final i = me.input;
    i.x = 0;
    i.up = false;
    if (_downHold <= 0) i.down = false;
    if (me.stunned || me.state == FighterState.hitstun) return;
    if (!target.alive) {
      // Wait near the middle for the opponent to come back.
      final center = (_stageLeft + _stageRight) / 2;
      i.x = (center - me.position.x).abs() > 40
          ? (center - me.position.x).sign * .6
          : 0;
      return;
    }

    final dx = target.position.x - me.position.x;
    final dy = target.mid.y - me.mid.y;
    final dist = sqrt(dx * dx + dy * dy);
    final toward = dx.sign;

    // Easy CPUs sometimes just mess around.
    if (difficulty == Difficulty.easy && _rnd.nextDouble() < .25) {
      if (_wander <= 0) {
        _wander = .6;
        _wanderDir = _rnd.nextBool() ? 1 : -1;
      }
      _wander -= _reaction;
      i.x = _wanderDir * .6;
      return;
    }

    // Defence: the player is swinging at us.
    if (target.attacking && dist < 80 && _rnd.nextDouble() < _adaptiveEvade) {
      if (me.onGround) {
        // Hop back out of reach, or just step away.
        i.x = -toward;
        if (_rnd.nextDouble() < .45 && _safeToRetreat(-toward)) {
          i.pressJump();
        }
        return;
      }
    }

    // Anti-air: someone dropping on us from above gets an up attack (or
    // a step aside), instead of free aerials.
    if (me.onGround &&
        !target.onGround &&
        dy < -15 &&
        dy > -110 &&
        dx.abs() < 70 &&
        difficulty != Difficulty.easy) {
      final r = _rnd.nextDouble();
      if (r < _aggression * .7) {
        i.up = true;
        i.pressAttack();
        _attackHold = .02;
        return;
      }
      if (r < _aggression * .7 + _evadeChance) {
        i.x = dx >= 0 ? -1 : 1;
        return;
      }
    }

    // Items: run from bombs, go for the goodies.
    if (_items(dist)) return;

    // Specials.
    if (me.specialReady && _rnd.nextDouble() < _specialChance) {
      if (_trySpecial(dx, dy, dist)) return;
    }

    // In range: attack.
    final inRange = dx.abs() < 54 && dy.abs() < 34;
    if (inRange && _rnd.nextDouble() < _aggression) {
      _attack(dx, dy);
      return;
    }

    // Approach.
    if (dx.abs() > 40) i.x = toward * (.6 + .4 * _aggression);
    // Target right below us (we're on a block or a ledge): step off.
    if (me.onGround && dy > 34 && dx.abs() <= 40) {
      i.x = dx.abs() > 4 ? toward : (me.facingRight ? 1 : -1);
    }
    if (me.onGround && me.hitWall) {
      // Something in the way: hop over it.
      i.jumpPressed = true;
      i.jump = true;
    } else if (me.onGround && dy < -40 && dx.abs() < 160) {
      i.jumpPressed = true;
      i.jump = true;
    } else if (!me.onGround &&
        dy < -40 &&
        me.airJumps > 0 &&
        me.velocity.y > 0) {
      i.jumpPressed = true;
      i.jump = true;
    }
    if (me.onGround &&
        dy > 60 &&
        dx.abs() < 120 &&
        _groundBelow(me.position.x)) {
      _downHold = .2; // drop through the platform
      i.down = true;
    }
  }

  bool _items(double targetDist) {
    final i = me.input;
    FightItem? best;
    var bestD = double.infinity;
    for (final it in _game.items) {
      final d = it.position.distanceTo(me.position);
      if (it.kind == ItemKind.bomb) {
        if (d < 120 && (it.ticking || it.onGround)) {
          i.x = (me.position.x - it.position.x).sign;
          if (i.x == 0) i.x = 1;
          return true;
        }
        continue;
      }
      if (!it.onGround) continue;
      if (d < bestD) {
        bestD = d;
        best = it;
      }
    }
    // Easy CPUs rarely notice items; harder ones grab them when they're
    // closer than the fight.
    final keen = switch (difficulty) {
      Difficulty.easy => .2,
      Difficulty.normal => .6,
      Difficulty.hard => .9,
    };
    if (best == null || bestD > 280 || _rnd.nextDouble() > keen) return false;
    if (bestD > targetDist && targetDist < 90) return false;
    final dx = best.position.x - me.position.x;
    i.x = dx.abs() < 6 ? 0 : dx.sign;
    if (me.onGround && best.position.y < me.position.y - 30) {
      i.jumpPressed = true;
      i.jump = true;
    }
    return true;
  }

  void _attack(double dx, double dy) {
    final i = me.input;
    final toward = dx.sign;
    if (me.onGround) {
      final kill = switch (difficulty) {
        Difficulty.easy => 140,
        Difficulty.normal => 95,
        Difficulty.hard => 80,
      };
      if (dy < -30) {
        i.up = true;
        i.pressAttack();
        _attackHold = .02;
      } else if (target.percent > kill && _rnd.nextDouble() < .6) {
        i.x = toward;
        i.pressAttack();
        _attackHold = .3 + _rnd.nextDouble() * .4; // charge a smash
      } else {
        final r = _rnd.nextDouble();
        if (r < .35) {
          i.x = 0;
          me.facingRight = toward > 0;
        } else if (r < .75) {
          i.x = toward;
        } else {
          i.down = true;
        }
        i.pressAttack();
        _attackHold = .02;
      }
    } else {
      if (dy < -20) {
        i.up = true;
      } else if (dy > 20) {
        i.down = true;
      } else {
        i.x = toward;
      }
      i.pressAttack();
      _attackHold = .02;
    }
  }

  bool _trySpecial(double dx, double dy, double dist) {
    final i = me.input;
    final t = me.character.specialType;
    final facing = (dx > 0) == me.facingRight;
    bool go;
    switch (t) {
      case SpecialType.plushThrow:
      case SpecialType.rockThrow:
      case SpecialType.waterJet:
      case SpecialType.chickArmy:
      case SpecialType.police:
      case SpecialType.eggBomb:
        go = dy.abs() < 40 && dx.abs() > 60 && dx.abs() < 320;
        if (go && !facing) i.x = dx.sign;
      case SpecialType.heist:
      case SpecialType.rockRoll:
      case SpecialType.kachow:
        go = dy.abs() < 30 && dx.abs() < 230 && me.onGround;
        if (go && !facing) i.x = dx.sign;
      case SpecialType.manager:
      case SpecialType.purse:
      case SpecialType.braidSpin:
      case SpecialType.swampSlam:
      case SpecialType.superJump:
        go = dist < 85;
      case SpecialType.stare:
      case SpecialType.cursedSmile:
      case SpecialType.lullaby:
        go = dist < 200 || (t == SpecialType.lullaby && me.percent > 60);
      case SpecialType.teethFlash:
      case SpecialType.phoneCall:
      case SpecialType.vacation:
        go = dist < 260;
      case SpecialType.hesoyam:
        go = me.percent > 70;
      case SpecialType.airpods:
        go = dist < 180;
      case SpecialType.balloon:
      case SpecialType.flight:
        // Mostly saved for recovery; on the ground, a point-blank shove.
        go = me.onGround && dist < 60 && _rnd.nextDouble() < .5;
    }
    if (!go) return false;
    // Turn first (facing applies on the next frame), then fire.
    if (!facing) me.facingRight = dx > 0;
    i.specialPressed = true;
    i.special = true;
    return true;
  }
}
