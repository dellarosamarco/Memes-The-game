import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memes_game.dart';
import 'xp_gem.dart';

/// The "anti-meme" forces: everything a meme hates.
enum EnemyKind {
  normie('🤓', 'Normie', 17, 20, 80, 8, 1, Color(0xFF4A90D9)),
  cringe('😬', 'Cringe', 14, 10, 145, 5, 1, Color(0xFFE5C04B)),
  hater('😡', 'Hater', 20, 38, 105, 10, 2, Color(0xFFD9534F)),
  boomer('👴', 'Boomer', 26, 80, 55, 14, 3, Color(0xFF8D8D8D)),
  algorithm('🤖', 'L\'ALGORITMO', 56, 1400, 72, 25, 40, Color(0xFF2ECC71));

  const EnemyKind(
    this.emoji,
    this.label,
    this.radius,
    this.hp,
    this.speed,
    this.damage,
    this.xp,
    this.color,
  );

  final String emoji;
  final String label;
  final double radius;
  final double hp;
  final double speed;
  final double damage;
  final int xp;
  final Color color;

  bool get isBoss => this == EnemyKind.algorithm;
}

class Enemy extends PositionComponent with HasGameReference<MemesGame> {
  Enemy({
    required this.kind,
    required Vector2 position,
    required double hpScale,
  }) : maxHp = kind.hp * hpScale,
       super(position: position, anchor: Anchor.center, priority: 5) {
    hp = maxHp;
    radius = kind.radius;
    size = Vector2.all(radius * 2);
  }

  final EnemyKind kind;
  final double maxHp;
  late double hp;
  late double radius;

  double frozenTime = 0;
  double fearTime = 0;
  double vulnerableTime = 0;
  double _flash = 0;
  final Vector2 _knockback = Vector2.zero();
  final double _wobbleSeed = Random().nextDouble() * 10;
  double _t = 0;
  bool dead = false;

  static final Map<EnemyKind, ui.Image> _faceCache = {};
  static ui.Image? _fearImage;

  /// Pre-renders the emoji faces once: drawing text every frame for hundreds
  /// of enemies is too slow.
  static void warmUp() {
    for (final k in EnemyKind.values) {
      _faceCache[k] ??= _emojiImage(k.emoji, k.radius * 1.7);
    }
    _fearImage ??= _emojiImage('😱', 14);
  }

  static ui.Image _emojiImage(String emoji, double fontSize) {
    final px = (fontSize * 1.42).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((px - tp.width) / 2, (px - tp.height) / 2));
    return recorder.endRecording().toImageSync(px, px);
  }

  @override
  void onMount() {
    super.onMount();
    game.enemies.add(this);
  }

  @override
  void onRemove() {
    game.enemies.remove(this);
    super.onRemove();
  }

  void hit(double damage, {Vector2? knockFrom, double knockback = 0}) {
    if (dead) return;
    if (vulnerableTime > 0) damage *= 1.5;
    hp -= damage;
    _flash = 0.12;
    if (knockFrom != null && knockback > 0 && !kind.isBoss) {
      final dir = position - knockFrom;
      if (dir.length2 > 0) _knockback.add(dir.normalized() * knockback);
    }
    if (hp <= 0) _die();
  }

  void _die() {
    dead = true;
    game.onEnemyKilled(this);
    final gems = kind.isBoss ? 8 : 1;
    final rnd = Random();
    for (var i = 0; i < gems; i++) {
      final offset = gems == 1
          ? Vector2.zero()
          : Vector2(rnd.nextDouble() - .5, rnd.nextDouble() - .5) * 80;
      game.world.add(
        XpGem(
          position: position + offset,
          value: gems == 1 ? kind.xp : (kind.xp / gems).ceil(),
        ),
      );
    }
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_flash > 0) _flash -= dt;
    if (vulnerableTime > 0) vulnerableTime -= dt;

    if (_knockback.length2 > 1) {
      position.addScaled(_knockback, dt);
      _knockback.scale(pow(0.02, dt).toDouble());
    }

    if (frozenTime > 0) {
      frozenTime -= dt;
      return;
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    if (dist > 0.01) {
      final dir = toPlayer / dist;
      // A little sideways wobble so hordes don't collapse into a single dot.
      final wobble = sin(_t * 3 + _wobbleSeed) * 0.35;
      final side = Vector2(-dir.y, dir.x) * wobble;
      var move = (dir + side)..normalize();
      if (fearTime > 0) {
        fearTime -= dt;
        move = -move;
      }
      position.addScaled(move, kind.speed * dt);
    }

    if (fearTime <= 0 && dist < radius + player.radius) {
      player.takeDamage(kind.damage);
    }
    position.clamp(Vector2.zero(), game.arenaSize);
  }

  static final _shadow = Paint()..color = const Color(0x55000000);
  static final _hpBack = Paint()..color = const Color(0xAA000000);
  static final _hpFill = Paint()..color = const Color(0xFFE74C3C);

  @override
  void render(Canvas canvas) {
    final c = Offset(radius, radius);
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, radius * .85),
        width: radius * 1.8,
        height: radius * .6,
      ),
      _shadow,
    );
    final body = Paint()
      ..color = _flash > 0
          ? Colors.white
          : frozenTime > 0
          ? const Color(0xFF9FD8FF)
          : kind.color;
    final bounce = sin(_t * 10 + _wobbleSeed) * radius * 0.06;
    canvas.drawCircle(c.translate(0, bounce), radius, body);
    canvas.drawCircle(
      c.translate(0, bounce),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.black87,
    );
    final img = _faceCache[kind];
    if (img != null) {
      final s = radius * 2.4;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: c.translate(0, bounce), width: s, height: s),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final fear = _fearImage;
    if (fearTime > 0 && fear != null) {
      canvas.drawImage(
        fear,
        c.translate(
          radius * .9 - fear.width / 2,
          -radius * .9 - fear.height / 2,
        ),
        Paint(),
      );
    }
    if (kind.isBoss || hp < maxHp) {
      final w = radius * 2;
      final top = -10.0;
      canvas.drawRect(Rect.fromLTWH(0, top, w, 5), _hpBack);
      canvas.drawRect(
        Rect.fromLTWH(0, top, w * (hp / maxHp).clamp(0, 1), 5),
        _hpFill,
      );
    }
  }
}
