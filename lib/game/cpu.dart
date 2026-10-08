import 'dart:math';

import '../models/meme_character.dart';
import 'fighter/fighter.dart';
import 'level.dart';
import 'memes_game.dart';

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
  double _shieldHold = 0;
  double _downHold = 0;
  double _wander = 0;
  double _wanderDir = 0;

  double get _reaction => switch (difficulty) {
    Difficulty.easy => .42,
    Difficulty.normal => .2,
    Difficulty.hard => .07,
  };

  double get _aggression => switch (difficulty) {
    Difficulty.easy => .45,
    Difficulty.normal => .75,
    Difficulty.hard => .95,
  };

  double get _shieldChance => switch (difficulty) {
    Difficulty.easy => .05,
    Difficulty.normal => .25,
    Difficulty.hard => .5,
  };

  double get _specialChance => switch (difficulty) {
    Difficulty.easy => .15,
    Difficulty.normal => .3,
    Difficulty.hard => .45,
  };

  MemesGame get _game => me.game;

  void think(double dt) {
    final i = me.input;
    if (!me.alive) {
      i.clear();
      return;
    }
    // Held buttons keep being held between decisions.
    if (_attackHold > 0) {
      _attackHold -= dt;
      i.attack = _attackHold > 0;
    }
    if (_shieldHold > 0) {
      _shieldHold -= dt;
      i.shield = _shieldHold > 0;
    }
    if (_downHold > 0) {
      _downHold -= dt;
      i.down = _downHold > 0;
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
          me.position.y > _stageTop + 30);

  void _recover() {
    final i = me.input;
    final center = (_stageLeft + _stageRight) / 2;
    i.x = (center - me.position.x).sign;
    i.up = false;
    i.down = false;
    i.attack = false;
    i.shield = false;
    if (me.state == FighterState.hitstun) return;
    final y = me.position.y;
    final falling = me.velocity.y > -60;
    // Horizontal gap to the nearest edge of the main island.
    final gap = me.position.x < _stageLeft
        ? _stageLeft - me.position.x
        : me.position.x - _stageRight;
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
        falling &&
        me.airJumps == 0 &&
        (y > _stageTop - 20 || gap > 150)) {
      i.up = true;
      i.specialPressed = true;
    }
    if (me.flight > 0) i.jump = y > _stageTop - 60;
  }

  /// Don't walk off the stage by accident.
  void _guardEdges() {
    final i = me.input;
    if (!me.onGround) return;
    final x = me.position.x;
    final nearLeft = x < _stageLeft + kTile * 1.2;
    final nearRight = x > _stageRight - kTile * 1.2;
    final onMain = (me.position.y - _stageTop).abs() < 4;
    if (!onMain) return;
    if ((nearLeft && i.x < 0) || (nearRight && i.x > 0)) i.x = 0;
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
    if (target.attacking && dist < 80 && _rnd.nextDouble() < _shieldChance) {
      if (me.onGround) {
        if (_rnd.nextDouble() < .35) {
          i.shield = true;
          i.x = -toward;
          _shieldHold = .05;
        } else {
          i.shield = true;
          _shieldHold = .3;
        }
        return;
      }
    }

    // Specials.
    if (me.specialReady && _rnd.nextDouble() < _specialChance) {
      if (_trySpecial(dx, dy, dist)) return;
    }

    // In range: attack.
    final inRange = dx.abs() < 54 && dy.abs() < 50;
    if (inRange && _rnd.nextDouble() < _aggression) {
      _attack(dx, dy);
      return;
    }

    // Approach.
    if (dx.abs() > 40) i.x = toward * (.6 + .4 * _aggression);
    if (me.onGround && me.hitWall) {
      // Something in the way: hop over it.
      i.jumpPressed = true;
      i.jump = true;
    } else if (me.onGround && dy < -60 && dx.abs() < 160) {
      i.jumpPressed = true;
      i.jump = true;
    } else if (!me.onGround && dy < -40 && me.airJumps > 0 &&
        me.velocity.y > 0) {
      i.jumpPressed = true;
      i.jump = true;
    }
    if (me.onGround && dy > 60 && dx.abs() < 120) {
      _downHold = .2; // drop through the platform
      i.down = true;
    }
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
        go = false; // saved for recovery
    }
    if (!go) return false;
    // Turn first (facing applies on the next frame), then fire.
    if (!facing) me.facingRight = dx > 0;
    i.specialPressed = true;
    i.special = true;
    return true;
  }
}
