import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/hats.dart';
import '../../models/meme_character.dart';
import '../level.dart';
import '../memes_game.dart';
import '../pixel.dart';
import '../../services/achievements.dart';
import '../../services/sound.dart';
import '../physics.dart';
import 'body.dart';
import 'items.dart';
import 'minions.dart';
import 'effects.dart';
import 'projectile.dart';

class Player extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  Player({required this.character, required super.position})
    : super(priority: 20) {
    bodyWidth = 24;
    bodyHeight = 44;
    hearts = character.hearts;
  }

  final MemeCharacter character;
  late int hearts;
  late final Strip _strip;

  bool facingRight = true;
  double _t = 0;
  double _coyote = 0;
  int _airJumps = 0;
  double _invulnerable = 0;
  double specialTimer = 0;
  double _dash = 0;
  bool frozenInput = false;

  // Special/passive state of the newer memes.
  late bool _puffer = character.passive == Passive.puffy;
  double _spin = 0;
  double _turbo = 0;
  double _balloon = 0;
  bool _slamming = false;
  double _airpods = 0;
  double _flight = 0;
  double _roll = 0;
  double _pedal = 0;
  int _pedalDir = 0;
  bool get turbo => _turbo > 0;
  bool get rolling => _roll > 0;
  int get _maxAirJumps => switch (character.passive) {
    Passive.doubleJump => 1,
    Passive.tripleJump => 2,
    _ => 0,
  };

  bool get specialReady => specialTimer <= 0;
  double get specialProgress =>
      1 - (specialTimer / character.specialCooldown).clamp(0.0, 1.0);
  bool get dashing => _dash > 0;
  bool get invulnerable =>
      _invulnerable > 0 ||
      dashing ||
      starPower ||
      _slamming ||
      _airpods > 0 ||
      rolling;

  // Power-ups.
  PowerUpKind? power;
  double powerTime = 0;
  bool get starPower => power == PowerUpKind.sunglasses;
  double get _speedMult =>
      (power == PowerUpKind.coffee ? 1.35 : 1) *
      (turbo ? 1.7 : 1) *
      (1 + 0.5 * min(1.0, _pedal / 1.5));
  double get _jumpMult => power == PowerUpKind.coffee ? 1.1 : 1;
  final List<(Vector2, int, bool)> _trail = [];

  // Stomp combos and idle naps.
  int _combo = 0;
  double _idleTime = 0;
  double _relax = 0;
  double _zTimer = 0;
  static const _comboLines = [
    'Double kill!',
    'Triple kill!',
    'MEGA KILL!',
    'ULTRA KILL!',
    'M-M-M-MONSTER KILL!',
  ];

  /// Eye height (from the feet) for the sunglasses, per meme.
  double get _eyeY => switch (character.id) {
    'wig_dog' => -36,
    'stare_cat' => -34,
    'robber_dog' => -40,
    'pigtail_dog' => -40,
    'pearl_terrier' => -40,
    'suit_dachshund' => -34,
    'cheeks_dachshund' => -40,
    'snow_baby' => -38,
    'pink_monkey' => -38,
    'shrek_kid' => -36,
    'ears_dog' => -36,
    'drip_pig' => -34,
    'bowl_chick' => -30,
    'helmet_pigeon' => -36,
    'pietro_pigeon' => -40,
    'bike_dog' => -44,
    'sneaker_hen' => -34,
    'gta_bean' => -36,
    'masha_man' => -38,
    'rock_patrick' => -40,
    'bottle_patrick' => -36,
    'rock_monkey' => -38,
    'chill_dog' => -30,
    _ => -40,
  };

  void applyPowerUp(PowerUpKind kind) {
    if (kind == PowerUpKind.pizza) {
      if (hearts < character.hearts) {
        hearts++;
      } else {
        game.enemyScore += 100;
      }
      return;
    }
    power = kind;
    powerTime = kind.seconds;
  }

  static const _accelGround = 1500.0;
  static const _accelAir = 1000.0;

  // Strip frames (see tool/generate_sprites.py).
  static const _idle = [0, 1];
  static const _run = [2, 3, 4, 5];
  static const _jumpFrame = 6;
  static const _fallFrame = 7;

  late final Strip _hats;

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache(character.spriteSheet), 60, 60);
    _hats = Strip(game.images.fromCache(Hat.sheet), Hat.width, Hat.height);
    if (character.passive == Passive.featherweight) gravity = Phys.gravity * .8;
  }

  @override
  Iterable<Surface> get extraPlatforms => [
    ...game.platforms,
    ...game.enemies.where((e) => e.frozen && !e.dead),
  ];

  @override
  void onLandTile(int col, int row) {
    if (game.level.tileAt(col, row) != 'S') return;
    velocity.y = -Phys.springSpeed;
    onGround = false;
    _cuttable = false;
    game.springUsed(col, row);
    Sound.play('spring');
    game.world.add(
      Sparkles(position: Vector2((col + .5) * kTile, row * kTile)),
    );
  }

  /// Only jumps started by the player get shorter when the button is
  /// released; springs and stomps keep their full bounce.
  bool _cuttable = false;

  // Juice: squash & stretch (1 = normal height) and dust puffs.
  double _squash = 1;
  bool _wasOnGround = true;
  double _dustTimer = 0;
  bool _splashed = false;

  @override
  void onCeiling(int col, int row) {
    game.bumpBlock(col, row);
    // Rock helmet: bricks shatter.
    if (character.passive == Passive.rockHead &&
        game.level.tileAt(col, row) == 'B') {
      game.level.setTile(col, row, ' ');
      Sound.play('block');
      game.shake(0.1);
      final at = Vector2((col + .5) * kTile, (row + .5) * kTile);
      game.world.add(PoofEffect(position: at));
      game.world.add(Confetti(position: at, count: 10));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_invulnerable > 0) _invulnerable -= dt;
    if (specialTimer > 0) {
      specialTimer -= dt * (character.passive == Passive.refill ? 2 : 1);
    }
    if (_airpods > 0) {
      _airpods -= dt;
      if (_t % 0.35 < dt) {
        game.world.add(
          FloatingText(
            position: position + Vector2(facingRight ? -16 : 16, -50),
            text: '♪',
            fontSize: 12,
            color: const Color(0xFFFFD86A),
            duration: .8,
          ),
        );
      }
    }
    if (power != null) {
      powerTime -= dt;
      if (powerTime <= 0) power = null;
    }
    if (_turbo > 0) _turbo -= dt;
    if (_spin > 0) _spin -= dt;
    final trailing = power == PowerUpKind.coffee || turbo;
    if (trailing && _t % 0.06 < dt) {
      _trail.add((position.clone(), _frame, facingRight));
    }
    if (_trail.length > 5 || (!trailing && _trail.isNotEmpty)) {
      _trail.removeAt(0);
    }
    if (game.finished) {
      // Victory walk (with happy hops) towards the flag.
      velocity.x = 60;
      facingRight = true;
      if (onGround) velocity.y = -260;
      applyGravity(dt);
      moveAndCollide(dt);
      return;
    }

    final input = game.input;
    final prevBottom = bottom;
    // Ride moving platforms.
    final ride = standingOn;
    if (ride is MovingPlatform) position.x += ride.lastDx;

    if (_roll > 0) {
      _roll -= dt;
      velocity.x = (facingRight ? 1 : -1) * 300;
      applyGravity(dt);
      if (hitWall) _roll = 0;
    } else if (_dash > 0) {
      _dash -= dt;
      velocity
        ..x = (facingRight ? 1 : -1) * 460
        ..y = 0;
      if (_t % 0.05 < dt) {
        game.world.add(PoofEffect(position: position - Vector2(0, 20)));
      }
    } else {
      final dir = (input.right ? 1 : 0) - (input.left ? 1 : 0);
      if (dir != 0) facingRight = dir > 0;
      if (character.passive == Passive.momentum) {
        // Pedalling: speed builds up while going the same way.
        _pedal = dir != 0 && dir == _pedalDir && !hitWall ? _pedal + dt : 0;
        _pedalDir = dir;
      }
      final target = dir * character.runSpeed * _speedMult;
      _napCheck(dir, dt);
      final accel =
          (onGround ? _accelGround : _accelAir) *
          (character.passive == Passive.sneakers ? 3 : 1);
      final dv = target - velocity.x;
      velocity.x += dv.clamp(-accel * dt, accel * dt);

      // Jumping: coyote time + buffered presses + variable height.
      if (onGround) {
        _coyote = 0.1;
        _airJumps = _maxAirJumps;
      } else {
        _coyote -= dt;
      }
      if (input.jumpBuffer > 0) {
        if (_coyote > 0) {
          _jump(character.jumpSpeed * _jumpMult);
          Sound.play('jump', volume: .5);
          input.jumpBuffer = 0;
        } else if (_airJumps > 0) {
          _airJumps--;
          _jump(character.jumpSpeed * .9);
          Sound.play('double_jump', volume: .5);
          input.jumpBuffer = 0;
          game.world.add(PoofEffect(position: position.clone()));
        }
      }
      if (_cuttable && !input.jump && velocity.y < -Phys.jumpCut) {
        velocity.y = -Phys.jumpCut;
      }
      if (onGround) _cuttable = false;

      applyGravity(dt);
      // Wig glide: the wig works as a parachute.
      if (character.passive == Passive.glide && input.jump && velocity.y > 70) {
        velocity.y = 70;
      }
      // Puffed-up cheeks: floats up like a balloon.
      if (_balloon > 0) {
        _balloon -= dt;
        velocity.y = _balloon > 0 ? -120 : min(velocity.y, 0);
        _cuttable = false;
      }
      if (_slamming) velocity.y = 720;
      // Pigeon flight: hold jump to climb, otherwise drift down.
      if (_flight > 0) {
        _flight -= dt;
        velocity.y = input.jump ? -200 : 70;
        _cuttable = false;
        if (_t % 0.2 < dt) {
          game.world.add(PoofEffect(position: position - Vector2(0, 10)));
        }
      }
    }

    if (input.specialQueued) {
      input.specialQueued = false;
      useSpecial();
    }

    moveAndCollide(dt);
    if (_slamming && onGround) _slamImpact();
    if (_spin > 0) _spinHits();
    _juice(dt);
    _checkEnemies(prevBottom);
    _checkSpikes();
    if (!_splashed && position.y > game.level.height + 4) {
      _splashed = true;
      game.world.add(
        Confetti(
          position: Vector2(position.x, game.level.height),
          count: 18,
          splash: true,
        ),
      );
    }
    if (position.y < game.level.height) _splashed = false;
    if (position.y > game.level.height + 80) game.fellInPit();
  }

  void _juice(double dt) {
    if (onGround && !_wasOnGround) {
      _combo = 0;
      _squash = 0.78;
      game.world.add(Dust(position: position + Vector2(-8, 0), dx: -18));
      game.world.add(Dust(position: position + Vector2(8, 0), dx: 18));
    }
    _wasOnGround = onGround;
    _squash += (1 - _squash) * min(1.0, dt * 12);
    if (onGround && velocity.x.abs() > 90) {
      _dustTimer -= dt;
      if (_dustTimer <= 0) {
        _dustTimer = 0.16;
        game.world.add(
          Dust(
            position: position + Vector2(facingRight ? -10 : 10, 0),
            dx: facingRight ? -14 : 14,
          ),
        );
      }
    }
  }

  /// After a few seconds without moving, the meme takes a little nap.
  void _napCheck(int dir, double dt) {
    final idle = dir == 0 && onGround && game.input.jumpBuffer <= 0;
    _idleTime = idle ? _idleTime + dt : 0;
    // Total relax: a heart back every 4 seconds of doing nothing.
    _relax = idle ? _relax + dt : 0;
    if (character.passive == Passive.chill && _relax >= 4) {
      _relax = 0;
      if (hearts < character.hearts) {
        hearts++;
        game.world.add(
          FloatingText(
            position: position - Vector2(0, 66),
            text: '+1 cuore (relax)',
            fontSize: 10,
            color: const Color(0xFFFF82B4),
          ),
        );
      }
    }
    if (_idleTime > 5) {
      Achievements.unlock('nap');
      _zTimer -= dt;
      if (_zTimer <= 0) {
        _zTimer = 1.1;
        game.world.add(
          FloatingText(
            position: position + Vector2(facingRight ? 14 : -14, -56),
            text: _idleTime % 2 < 1 ? 'z' : 'Z',
            fontSize: 10,
            color: const Color(0xFFB4C8FF),
            duration: 1.3,
          ),
        );
      }
    }
  }

  void _jump(double speed) {
    _squash = 1.18;
    velocity.y = -speed;
    _cuttable = true;
    _coyote = 0;
    onGround = false;
  }

  void _checkEnemies(double prevBottom) {
    for (final e in game.enemies.toList()) {
      if (e.dead || !overlaps(e)) continue;
      if (e.frozen) continue;
      if (dashing || starPower || turbo || _slamming || rolling) {
        if (starPower && !e.kind.isBoss) {
          Sound.play('stomp');
          game.world.add(
            FloatingText(
              position: e.mid - Vector2(0, 16),
              text: 'BONK!',
              fontSize: 10,
              color: const Color(0xFFFF82B4),
              duration: .6,
            ),
          );
        }
        e.hit(heavy: true);
        continue;
      }
      if (e.scared) {
        e.hit(heavy: true);
        continue;
      }
      final stomp = velocity.y > 0 && prevBottom <= e.top + 10;
      if (stomp) {
        e.hit(heavy: character.passive == Passive.tough, stomp: true);
        final bounce = character.passive == Passive.bouncy ? 1.45 : 1.0;
        velocity.y = (game.input.jump ? -460 : -300) * bounce;
        Sound.play('stomp');
        Sound.haptic();
        _cuttable = false;
        game.world.add(Sparkles(position: e.mid));
        _combo++;
        if (_combo >= 3) Achievements.unlock('combo3');
        if (_combo >= 6) Achievements.unlock('combo6');
        if (_combo >= 2) {
          final line = _comboLines[min(_combo - 2, _comboLines.length - 1)];
          game.enemyScore += (_combo - 1) * 20;
          game.world.add(
            FloatingText(
              position: position - Vector2(0, 80),
              text: line,
              fontSize: 12 + min(_combo, 6).toDouble(),
              color: const Color(0xFFFFD86A),
              duration: 1.2,
            ),
          );
        }
        _airJumps = _maxAirJumps;
      } else {
        takeDamage(fromX: e.position.x);
      }
    }
  }

  void _checkSpikes() {
    // Lightning McQueen crocs: spikes do nothing.
    if (character.passive == Passive.spikeProof) return;
    final c0 = (left / kTile).floor();
    final c1 = ((right - .01) / kTile).floor();
    final r = ((bottom - 1) / kTile).floor();
    for (var c = c0; c <= c1; c++) {
      if (game.level.tileAt(c, r) == '^' && bottom > r * kTile + 12) {
        takeDamage(fromX: position.x - (facingRight ? 1 : -1));
        velocity.y = -380;
        return;
      }
    }
  }

  void takeDamage({required double fromX}) {
    if (invulnerable || game.finished || game.isOver) return;
    if (_puffer) {
      // The puffer jacket takes the first hit of the level.
      _puffer = false;
      _invulnerable = 1.2;
      velocity.y = -240;
      Sound.play('block');
      game.world.add(Confetti(position: position - Vector2(0, 24), count: 16));
      game.world.add(
        FloatingText(
          position: position - Vector2(0, 62),
          text: 'Piumino KO!',
          color: const Color(0xFF8CC8FF),
        ),
      );
      return;
    }
    hearts--;
    game.damageTaken = true;
    Sound.play('hurt');
    Sound.haptic(strong: true);
    _invulnerable = 1.3;
    if (character.passive != Passive.rockSolid) {
      velocity
        ..x = (position.x < fromX ? -1 : 1) * 170
        ..y = -260;
    }
    game.shake(0.25);
    final lines = character.hurtLines;
    game.world.add(
      FloatingText(
        position: position - Vector2(0, 62),
        text: lines[Random().nextInt(lines.length)],
      ),
    );
    if (hearts <= 0) game.gameOver();
  }

  /// Puts the player back on a checkpoint after a fall.
  void respawn(Vector2 at) {
    position.setFrom(at);
    velocity.setZero();
    _invulnerable = 1.5;
    _dash = 0;
    _balloon = 0;
    _slamming = false;
    _flight = 0;
    _roll = 0;
  }

  /// Onion layers: the ogre gets a heart back at every checkpoint.
  void onCheckpoint() {
    if (character.passive != Passive.onion || hearts >= character.hearts) {
      return;
    }
    hearts++;
    game.world.add(
      FloatingText(
        position: position - Vector2(0, 66),
        text: '+1 cuore (cipolla)',
        fontSize: 10,
        color: const Color(0xFF8BC34A),
      ),
    );
  }

  void _spinHits() {
    final center = position - Vector2(0, bodyHeight / 2);
    for (final e in game.enemies.toList()) {
      if (!e.dead && !e.kind.isBoss && e.mid.distanceTo(center) < 50) {
        e.hit(heavy: true);
      }
    }
  }

  void _slamImpact() {
    _slamming = false;
    _invulnerable = max(_invulnerable, 0.3);
    _squash = 0.6;
    game.shake(0.4);
    Sound.play('boss_hit', volume: .7);
    game.world.add(
      ShockwaveEffect(
        position: position.clone(),
        maxRadius: 170,
        color: const Color(0xFF8BC34A),
      ),
    );
    for (var i = -2; i <= 2; i++) {
      game.world.add(
        Dust(position: position + Vector2(i * 12.0, 0), dx: i * 30),
      );
    }
    for (final e in game.enemies.toList()) {
      final d = e.position - position;
      if (d.x.abs() < 170 && d.y.abs() < 70) e.hit(heavy: true);
    }
  }

  // ------------------------------------------------------------- specials

  void useSpecial() {
    if (!specialReady || game.finished || game.isOver) return;
    specialTimer = character.specialCooldown;
    Sound.play('special');
    game.world.add(
      FloatingText(
        position: position - Vector2(0, 70),
        text: character.specialShout,
        fontSize: 12,
        duration: 1.4,
      ),
    );
    final center = position - Vector2(0, bodyHeight / 2);
    switch (character.specialType) {
      case SpecialType.manager:
        game.world.add(
          ShockwaveEffect(
            position: center,
            maxRadius: 130,
            color: const Color(0xFFFF7043),
          ),
        );
        for (final e in game.enemies.toList()) {
          if (e.mid.distanceTo(center) < 130) e.hit(heavy: true);
        }
        game.shake(0.3);

      case SpecialType.stare:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x8840C4FF), duration: 0.5),
        );
        for (final e in game.enemies) {
          if (e.mid.distanceTo(center) < 330) e.freeze(4.5);
        }

      case SpecialType.heist:
        _dash = 0.25;
        _invulnerable = max(_invulnerable, 0.35);

      case SpecialType.cursedSmile:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0xCC000000), duration: 0.7),
        );
        game.world.add(
          ShockwaveEffect(
            position: center,
            maxRadius: 300,
            color: const Color(0xFFB388FF),
            duration: 0.6,
          ),
        );
        for (final e in game.enemies) {
          if (e.mid.distanceTo(center) < 300) e.scare(6);
        }
        game.shake(0.3);

      case SpecialType.braidSpin:
        _spin = 0.45;
        if (!onGround) {
          velocity.y = min(velocity.y, -300);
          _cuttable = false;
        }
        game.world.add(
          ShockwaveEffect(
            position: center,
            maxRadius: 50,
            color: const Color(0xFF2F5BD3),
            duration: 0.3,
          ),
        );

      case SpecialType.purse:
        final dir = facingRight ? 1.0 : -1.0;
        final hitAt = center + Vector2(dir * 30, 0);
        game.world.add(PoofEffect(position: hitAt + Vector2(0, 12)));
        game.world.add(
          FloatingText(
            position: hitAt - Vector2(0, 14),
            text: 'SBAM!',
            fontSize: 11,
            color: const Color(0xFFFF82B4),
            duration: .5,
          ),
        );
        for (final e in game.enemies.toList()) {
          final d = e.mid - center;
          if (d.x * dir > -6 && d.x * dir < 62 && d.y.abs() < 34) {
            e.hit(heavy: true);
          }
        }

      case SpecialType.kachow:
        _turbo = 3;
        game.world.add(Sparkles(position: center));

      case SpecialType.balloon:
        _balloon = 1.4;
        _cuttable = false;
        game.world.add(PoofEffect(position: position.clone()));

      case SpecialType.lullaby:
        if (hearts < character.hearts) {
          hearts++;
        } else {
          game.enemyScore += 50;
        }
        _invulnerable = max(_invulnerable, 1.5);
        game.world.add(
          ShockwaveEffect(
            position: center,
            maxRadius: 220,
            color: const Color(0xFFB39DDB),
            duration: 0.8,
          ),
        );
        for (final e in game.enemies) {
          if (!e.dead && e.mid.distanceTo(center) < 220) {
            e.freeze(5);
            game.world.add(
              FloatingText(
                position: e.mid - Vector2(0, 20),
                text: 'zZz',
                fontSize: 10,
                color: const Color(0xFFB4C8FF),
                duration: 1.5,
              ),
            );
          }
        }

      case SpecialType.plushThrow:
        game.world.add(
          PlushProjectile(
            position: center.clone(),
            direction: facingRight ? 1 : -1,
          ),
        );

      case SpecialType.swampSlam:
        if (onGround) {
          _slamImpact();
        } else {
          _slamming = true;
          velocity.x = 0;
        }

      case SpecialType.teethFlash:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0xEEFFFFFF), duration: 0.6),
        );
        game.shake(0.35);
        final view = game.camera.visibleWorldRect;
        for (final e in game.enemies.toList()) {
          if (!e.dead && view.contains(e.mid.toOffset())) e.hit(heavy: true);
        }

      case SpecialType.airpods:
        _airpods = 4;

      case SpecialType.chickArmy:
        final dir = facingRight ? 1 : -1;
        for (var i = 0; i < 3; i++) {
          game.world.add(
            ChickMinion(
              position: position + Vector2(dir * (10.0 + i * 4), -2),
              dir: dir,
              delay: i * 0.18,
            ),
          );
        }

      case SpecialType.flight:
        _flight = 2.5;

      case SpecialType.phoneCall:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x6640E070), duration: 0.5),
        );
        final view = game.camera.visibleWorldRect;
        for (final e in game.enemies) {
          if (e.dead || !view.contains(e.mid.toOffset())) continue;
          e.freeze(4);
          game.world.add(
            FloatingText(
              position: e.mid - Vector2(0, 24),
              text: 'Pronto?',
              fontSize: 9,
              color: const Color(0xFF7CFFA0),
              duration: 1.6,
            ),
          );
        }

      case SpecialType.police:
        final dir = facingRight ? 1 : -1;
        final view = game.camera.visibleWorldRect;
        game.world.add(
          PoliceCar(
            position: Vector2(
              dir > 0 ? view.left - 40 : view.right + 40,
              position.y,
            ),
            dir: dir,
          ),
        );

      case SpecialType.eggBomb:
        game.world.add(
          EggBomb(
            position: position - Vector2(0, 8),
            vx: (facingRight ? 1 : -1) * 90 + velocity.x * .3,
          ),
        );

      case SpecialType.hesoyam:
        hearts = character.hearts;
        game.enemyScore += 250;
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x66FFFFFF), duration: 0.4),
        );
        game.world.add(Confetti(position: center, count: 30));

      case SpecialType.superJump:
        _jump(900);
        _cuttable = false;
        game.world.add(
          ShockwaveEffect(
            position: position.clone(),
            maxRadius: 90,
            color: const Color(0xFFE0218A),
          ),
        );
        for (final e in game.enemies.toList()) {
          if (e.mid.distanceTo(position) < 90) e.hit(heavy: true);
        }

      case SpecialType.rockRoll:
        _roll = 1.2;

      case SpecialType.rockThrow:
        game.world.add(
          RockProjectile(
            position: center - Vector2(0, 14),
            dir: facingRight ? 1 : -1,
          ),
        );

      case SpecialType.vacation:
        game.slowMo = 5;
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x5540C4FF), duration: 0.6),
        );

      case SpecialType.waterJet:
        game.world.add(
          WaterJet(
            position: center + Vector2(facingRight ? 14 : -14, -6),
            dir: facingRight ? 1 : -1,
          ),
        );
    }
  }

  // --------------------------------------------------------------- render

  int get _frame {
    if (!onGround) return velocity.y < 0 ? _jumpFrame : _fallFrame;
    if (velocity.x.abs() > 15) return _run[(_t * 12).floor() % 4];
    return _idle[(_t * 2.5).floor() % 2];
  }

  @override
  void render(Canvas canvas) {
    // Coffee after-images.
    for (var i = 0; i < _trail.length; i++) {
      final (pos, frame, right) = _trail[i];
      final o = pos - position;
      _strip.draw(
        canvas,
        frame,
        Offset(o.x - 30, o.y - 58),
        flip: !right,
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..colorFilter = ColorFilter.mode(
            const Color(0xFF8CC8FF).withValues(alpha: 0.12 + i * 0.06),
            BlendMode.srcIn,
          ),
      );
    }
    if (onGround) {
      canvas.drawOval(
        const Rect.fromLTRB(-14, -3, 14, 3),
        Paint()..color = const Color(0x333A2440),
      );
    }
    final blink = _invulnerable > 0 && !dashing && (_t * 16).floor().isEven;
    if (blink) return;
    // Squash & stretch around the feet.
    canvas.save();
    final puff = _balloon > 0 ? 1.25 + sin(_t * 18) * 0.04 : 1.0;
    canvas.scale((1 + (1 - _squash) * 0.7) * puff, _squash * puff);
    // Braid spin: turns left/right really fast.
    final faceRight = _spin > 0 ? (_t * 20).floor().isEven : facingRight;
    if (rolling) {
      // Rolling rock: spin around the body's center.
      canvas.translate(0, -bodyHeight / 2);
      canvas.rotate((facingRight ? 1 : -1) * _t * 16);
      canvas.translate(0, bodyHeight / 2);
    }
    Paint? paint;
    if (dashing) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0x66FFFFFF),
          BlendMode.srcATop,
        );
    } else if (starPower) {
      // Rainbow shimmer.
      final hue = (_t * 360 * 1.5) % 360;
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = ColorFilter.mode(
          HSVColor.fromAHSV(0.2, hue, 0.6, 1).toColor(),
          BlendMode.srcATop,
        );
    }
    // Frame is 60x60, feet at y=58, centered at x=30.
    _strip.draw(
      canvas,
      _frame,
      const Offset(-30, -58),
      flip: !faceRight,
      paint: paint,
    );
    if (starPower) {
      canvas.drawImage(
        game.images.fromCache('sprites/sunglasses.png'),
        Offset(-12 + (faceRight ? 3 : -3), _eyeY),
        pixelPaint,
      );
    }
    final hat = game.hat;
    if (hat != null) {
      final a = character.hatAnchor;
      final bob = _frame.isOdd ? 1.0 : 0.0;
      final x = faceRight ? a.x : -a.x;
      _hats.draw(
        canvas,
        hat.index,
        Offset(x - Hat.width / 2, a.y - Hat.height + 3 + bob),
        flip: !faceRight,
      );
    }
    canvas.restore();
  }
}
