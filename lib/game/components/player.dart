import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/meme_character.dart';
import '../level.dart';
import '../memes_game.dart';
import '../pixel.dart';
import '../../services/sound.dart';
import '../physics.dart';
import 'body.dart';
import 'items.dart';
import 'effects.dart';

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

  bool get specialReady => specialTimer <= 0;
  double get specialProgress =>
      1 - (specialTimer / character.specialCooldown).clamp(0.0, 1.0);
  bool get dashing => _dash > 0;
  bool get invulnerable => _invulnerable > 0 || dashing || starPower;

  // Power-ups.
  PowerUpKind? power;
  double powerTime = 0;
  bool get starPower => power == PowerUpKind.sunglasses;
  double get _speedMult => power == PowerUpKind.coffee ? 1.35 : 1;
  double get _jumpMult => power == PowerUpKind.coffee ? 1.1 : 1;
  final List<(Vector2, int, bool)> _trail = [];

  // Stomp combos and idle naps.
  int _combo = 0;
  double _idleTime = 0;
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

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache(character.spriteSheet), 60, 60);
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
  void onCeiling(int col, int row) => game.bumpBlock(col, row);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_invulnerable > 0) _invulnerable -= dt;
    if (specialTimer > 0) specialTimer -= dt;
    if (power != null) {
      powerTime -= dt;
      if (powerTime <= 0) power = null;
    }
    if (power == PowerUpKind.coffee && _t % 0.06 < dt) {
      _trail.add((position.clone(), _frame, facingRight));
    }
    if (_trail.length > 5 || (power == null && _trail.isNotEmpty)) {
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

    if (_dash > 0) {
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
      final target = dir * character.runSpeed * _speedMult;
      _napCheck(dir, dt);
      final accel = onGround ? _accelGround : _accelAir;
      final dv = target - velocity.x;
      velocity.x += dv.clamp(-accel * dt, accel * dt);

      // Jumping: coyote time + buffered presses + variable height.
      if (onGround) {
        _coyote = 0.1;
        _airJumps = character.passive == Passive.doubleJump ? 1 : 0;
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
    }

    if (input.specialQueued) {
      input.specialQueued = false;
      useSpecial();
    }

    moveAndCollide(dt);
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
    if (_idleTime > 5) {
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
      if (dashing || starPower) {
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
        velocity.y = game.input.jump ? -460 : -300;
        Sound.play('stomp');
        Sound.haptic();
        _cuttable = false;
        game.world.add(Sparkles(position: e.mid));
        _combo++;
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
        _airJumps = character.passive == Passive.doubleJump ? 1 : 0;
      } else {
        takeDamage(fromX: e.position.x);
      }
    }
  }

  void _checkSpikes() {
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
    hearts--;
    Sound.play('hurt');
    Sound.haptic(strong: true);
    _invulnerable = 1.3;
    velocity
      ..x = (position.x < fromX ? -1 : 1) * 170
      ..y = -260;
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
    canvas.scale(1 + (1 - _squash) * 0.7, _squash);
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
      flip: !facingRight,
      paint: paint,
    );
    if (starPower) {
      canvas.drawImage(
        game.images.fromCache('sprites/sunglasses.png'),
        Offset(-12 + (facingRight ? 3 : -3), _eyeY),
        pixelPaint,
      );
    }
    canvas.restore();
  }
}
