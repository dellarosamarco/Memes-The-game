import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/meme_character.dart';
import '../memes_game.dart';
import '../upgrades.dart';
import 'effects.dart';
import 'enemy.dart';
import 'projectile.dart';

class Player extends PositionComponent with HasGameReference<MemesGame> {
  Player({required this.character, required super.position})
    : stats = PlayerStats(character),
      super(anchor: Anchor.center, size: Vector2.all(76), priority: 10) {
    hp = stats.maxHp;
  }

  final MemeCharacter character;
  final PlayerStats stats;
  late double hp;

  double get radius => 34;

  /// Movement input in [-1, 1], set by the game from joystick/keyboard.
  final Vector2 input = Vector2.zero();
  final Vector2 facing = Vector2(1, 0);

  double _attackTimer = 0.5;
  double specialTimer = 0;
  double _invulnerable = 0;
  double _hurtFlash = 0;
  double _t = 0;
  double _regenAcc = 0;

  // Heist dash state.
  double _dashTime = 0;
  final Vector2 _dashDir = Vector2.zero();
  final Set<Enemy> _dashHits = {};

  late final ui.Image _image;
  final _rnd = Random();

  bool get specialReady => specialTimer <= 0;
  double get specialProgress =>
      1 - (specialTimer / stats.specialCooldown).clamp(0.0, 1.0);
  double get auraRadius => 115 * stats.areaMult;

  @override
  Future<void> onLoad() async {
    _image = game.images.fromCache(character.spritePath);
  }

  void heal(double amount) {
    hp = min(stats.maxHp, hp + amount);
  }

  void takeDamage(double amount) {
    if (_invulnerable > 0 || _dashTime > 0 || game.isGameOver) return;
    hp -= amount;
    _invulnerable = 0.6;
    _hurtFlash = 0.25;
    if (_rnd.nextDouble() < 0.35) {
      game.world.add(
        FloatingText(
          position: position - Vector2(0, 50),
          text: character.hurtLines[_rnd.nextInt(character.hurtLines.length)],
          fontSize: 16,
          duration: 0.8,
        ),
      );
    }
    if (hp <= 0) {
      hp = 0;
      game.gameOver();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_invulnerable > 0) _invulnerable -= dt;
    if (_hurtFlash > 0) _hurtFlash -= dt;
    if (specialTimer > 0) specialTimer -= dt;

    if (stats.regenPerSecond > 0) {
      _regenAcc += stats.regenPerSecond * dt;
      if (_regenAcc >= 1) {
        heal(_regenAcc.floorToDouble());
        _regenAcc -= _regenAcc.floorToDouble();
      }
    }

    if (_dashTime > 0) {
      _updateDash(dt);
    } else if (input.length2 > 0.0001) {
      final move = input.length2 > 1 ? input.normalized() : input;
      position.addScaled(move, stats.speed * dt);
      facing.setFrom(input.normalized());
    }
    position.clamp(Vector2.all(radius), game.arenaSize - Vector2.all(radius));

    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      if (_attack()) _attackTimer = stats.attackCooldown;
    }
  }

  // ---------------------------------------------------------------- attacks

  Enemy? _nearest({double maxDist = 650}) {
    Enemy? best;
    var bestD = maxDist * maxDist;
    for (final e in game.enemies) {
      final d = e.position.distanceToSquared(position);
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    return best;
  }

  List<Enemy> _nearestN(int n, {double maxDist = 700}) {
    final list =
        game.enemies
            .where((e) => e.position.distanceTo(position) < maxDist)
            .toList()
          ..sort(
            (a, b) => a.position
                .distanceToSquared(position)
                .compareTo(b.position.distanceToSquared(position)),
          );
    return list.take(n).toList();
  }

  /// Returns false when there was nothing to attack (retry next frame).
  bool _attack() {
    switch (character.attackType) {
      case AttackType.hairFan:
        final target = _nearest();
        if (target == null) return false;
        final base = (target.position - position).normalized();
        final count = 3 + stats.extraProjectiles;
        const spread = 0.22;
        for (var i = 0; i < count; i++) {
          final a = (i - (count - 1) / 2) * spread;
          final dir = base.clone()..rotate(a);
          game.world.add(
            Projectile(
              position: position + dir * 20,
              velocity: dir * 430,
              damage: stats.damage,
              style: ProjectileStyle.hair,
              pierce: 1,
              lifetime: 1.1 * stats.areaMult,
              hitRadius: 10,
            ),
          );
        }
        return true;

      case AttackType.laserEyes:
        final targets = _nearestN(1 + stats.extraProjectiles);
        if (targets.isEmpty) return false;
        for (final t in targets) {
          final dir = (t.position - position).normalized();
          game.world.add(
            Projectile(
              position: position + Vector2(0, -6) + dir * 18,
              velocity: dir * 950,
              damage: stats.damage,
              style: ProjectileStyle.laser,
              pierce: 3,
              lifetime: 0.75 * stats.areaMult,
              hitRadius: 9,
            ),
          );
        }
        return true;

      case AttackType.knifeSlash:
        final target = _nearest(maxDist: 400);
        if (target == null) return false;
        final r = 95 * stats.areaMult;
        final dir = target.position - position;
        game.world.add(
          SlashEffect(
            position: position.clone(),
            radius: r,
            direction: atan2(dir.y, dir.x),
          ),
        );
        for (final e in game.enemies.toList()) {
          final reach = r + e.radius;
          if (e.position.distanceToSquared(position) < reach * reach) {
            e.hit(stats.damage, knockFrom: position, knockback: 220);
          }
        }
        for (var i = 0; i < stats.extraProjectiles; i++) {
          final d = dir.normalized()..rotate((_rnd.nextDouble() - .5) * 1.2);
          game.world.add(
            Projectile(
              position: position.clone(),
              velocity: d * 520,
              damage: stats.damage * .7,
              style: ProjectileStyle.knife,
              pierce: 2,
              lifetime: 0.9,
            ),
          );
        }
        return true;

      case AttackType.smileAura:
        final r = auraRadius;
        for (final e in game.enemies.toList()) {
          final reach = r + e.radius;
          if (e.position.distanceToSquared(position) < reach * reach) {
            e.hit(stats.damage, knockFrom: position, knockback: 40);
          }
        }
        return true;
    }
  }

  // ---------------------------------------------------------------- special

  void useSpecial() {
    if (!specialReady || game.isGameOver) return;
    specialTimer = stats.specialCooldown;
    game.world.add(
      FloatingText(
        position: position - Vector2(0, 70),
        text: character.specialShout,
        fontSize: 26,
        duration: 1.6,
      ),
    );

    switch (character.specialType) {
      case SpecialType.manager:
        final r = 300 * stats.areaMult;
        game.world.add(
          ShockwaveEffect(
            position: position.clone(),
            maxRadius: r,
            color: const Color(0xFFFF7043),
          ),
        );
        for (final e in game.enemies.toList()) {
          if (e.position.distanceTo(position) < r + e.radius) {
            e.hit(stats.damage * 5, knockFrom: position, knockback: 900);
          }
        }
        game.shake(0.3);

      case SpecialType.stare:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0x8840C4FF), duration: 0.6),
        );
        for (final e in game.enemies) {
          if (e.position.distanceTo(position) < 900) {
            e.frozenTime = 3.5;
            e.vulnerableTime = 3.5;
          }
        }

      case SpecialType.heist:
        _dashTime = 0.35;
        _dashHits.clear();
        _dashDir.setFrom(
          input.length2 > 0.01 ? input.normalized() : facing.normalized(),
        );
        for (final g in game.gems) {
          g.magnetized = true;
        }

      case SpecialType.cursedSmile:
        game.camera.viewport.add(
          ScreenFlash(color: const Color(0xCC000000), duration: 0.8),
        );
        game.world.add(
          ShockwaveEffect(
            position: position.clone(),
            maxRadius: 700,
            color: const Color(0xFFB388FF),
            duration: 0.7,
          ),
        );
        for (final e in game.enemies.toList()) {
          if (e.position.distanceTo(position) < 800) {
            e.fearTime = 3;
            e.hit(stats.damage * 6);
          }
        }
        heal(stats.maxHp * .1);
        game.shake(0.4);
    }
  }

  void _updateDash(double dt) {
    _dashTime -= dt;
    position.addScaled(_dashDir, 1150 * dt);
    if (_rnd.nextDouble() < .6) {
      game.world.add(
        ShockwaveEffect(
          position: position.clone(),
          maxRadius: 30,
          color: Colors.white,
          duration: 0.25,
        ),
      );
    }
    for (final e in game.enemies.toList()) {
      if (_dashHits.contains(e)) continue;
      final reach = radius + e.radius + 10;
      if (e.position.distanceToSquared(position) < reach * reach) {
        _dashHits.add(e);
        e.hit(stats.damage * 4, knockFrom: position, knockback: 500);
      }
    }
    if (_dashTime <= 0) _invulnerable = 0.3;
  }

  // ---------------------------------------------------------------- render

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final moving = input.length2 > 0.01 || _dashTime > 0;

    if (character.attackType == AttackType.smileAura) {
      final pulse = 1 + sin(_t * 4) * 0.04;
      canvas.drawCircle(
        c,
        auraRadius * pulse,
        Paint()..color = const Color(0x228E44AD),
      );
      canvas.drawCircle(
        c,
        auraRadius * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x668E44AD),
      );
    }

    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 36), width: 60, height: 14),
      Paint()..color = const Color(0x66000000),
    );

    // Hop when walking, squash slightly.
    final hop = moving ? -(sin(_t * 14).abs()) * 6 : sin(_t * 2) * 1.5;
    final squash = moving ? 1 + sin(_t * 28) * 0.04 : 1.0;

    canvas.save();
    canvas.translate(c.dx, c.dy + hop);
    canvas.scale(facing.x < 0 ? -1 : 1, 1);
    canvas.scale(1 / squash, squash);

    final blink = _invulnerable > 0 && (_t * 20).floor().isEven;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      rect,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: blink ? 0.45 : 1),
    );
    if (_hurtFlash > 0) {
      canvas.drawRect(rect, Paint()..color = const Color(0x88FF0000));
    }
    canvas.restore();
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = character.color,
    );
    canvas.drawCircle(
      Offset.zero,
      radius + 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );

    // The robber always carries the knife.
    if (character.attackType == AttackType.knifeSlash) {
      canvas.save();
      canvas.translate(radius * .85, radius * .55);
      canvas.rotate(-0.6 + sin(_t * 6) * 0.1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -3, 12, 6),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black,
      );
      canvas.drawPath(
        Path()
          ..moveTo(8, -3)
          ..lineTo(26, -1)
          ..lineTo(8, 3)
          ..close(),
        Paint()..color = const Color(0xFFCFD8DC),
      );
      canvas.restore();
    }
    canvas.restore();
  }
}
