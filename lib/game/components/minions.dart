import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memes_game.dart';
import 'body.dart';
import 'effects.dart';

Paint _p(int c) => Paint()..color = Color(c);

/// Draws a little pixel picture from rows of palette letters ('.' = empty).
void _pixmap(
  Canvas canvas,
  List<String> rows,
  Map<String, Paint> palette, {
  bool flip = false,
}) {
  final w = rows.first.length;
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < w; x++) {
      final p = palette[rows[y][x]];
      if (p == null) continue;
      final dx = flip ? w - 1 - x : x;
      canvas.drawRect(
        Rect.fromLTWH(dx - w / 2, y - rows.length.toDouble(), 1, 1),
        p,
      );
    }
  }
}

/// A tiny bowl-cut chick that runs ahead and bowls enemies over.
class ChickMinion extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  ChickMinion({required super.position, required this.dir, this.delay = 0})
    : super(priority: 21) {
    bodyWidth = 10;
    bodyHeight = 10;
  }

  final int dir;
  double delay;
  double _t = 0;

  static final _pal = {
    'k': _p(0xFF1E1A22),
    'y': _p(0xFFFFD23F),
    'Y': _p(0xFFE8A91E),
    'o': _p(0xFFF08A24),
    'e': _p(0xFF101014),
  };
  static const _rows = [
    '..kkkkk..',
    '.kkkkkkk.',
    '.kyyyyyk.',
    '.yyyyeyyo',
    '.yyyyyyoo',
    'yyyyyyyy.',
    'YyyyyyyY.',
    '.YyyyyY..',
    '..o..o...',
  ];

  @override
  void update(double dt) {
    super.update(dt);
    if (delay > 0) {
      delay -= dt;
      return;
    }
    _t += dt;
    velocity.x = dir * 210;
    if (onGround && _t % 0.3 < dt) velocity.y = -160;
    applyGravity(dt);
    moveAndCollide(dt);
    for (final e in game.enemies.toList()) {
      if (!e.dead && e.mid.distanceTo(position - Vector2(0, 5)) < 18) {
        e.hit(heavy: true);
      }
    }
    if (_t > 2.6 || hitWall || position.y > game.level.height + 40) {
      game.world.add(PoofEffect(position: position - Vector2(0, 5)));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (delay > 0) return;
    _pixmap(canvas, _rows, _pal, flip: dir < 0);
  }
}

/// The hen's egg: falls, bounces once and explodes.
class EggBomb extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  EggBomb({required super.position, required double vx}) : super(priority: 21) {
    bodyWidth = 8;
    bodyHeight = 10;
    velocity.setValues(vx, -120);
  }

  double _t = 0;
  int _bounces = 0;

  static final _pal = {
    'w': _p(0xFFFFF8EC),
    's': _p(0xFFE6D8C0),
    'k': _p(0xFF3A2440),
  };
  static const _rows = [
    '..kkk..',
    '.kwwwk.',
    'kwwwwwk',
    'kwwwwwk',
    'kwwwwsk',
    'kwwwssk',
    '.kssk..',
    '..kk...',
  ];

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    applyGravity(dt);
    moveAndCollide(dt);
    if (onGround) {
      _bounces++;
      velocity
        ..y = -150
        ..x *= 0.5;
    }
    final touching = game.enemies.any(
      (e) => !e.dead && e.mid.distanceTo(position) < 16,
    );
    if (_bounces >= 2 || touching || _t > 2.5) _explode();
  }

  void _explode() {
    game.world.add(
      ShockwaveEffect(
        position: position - Vector2(0, 4),
        maxRadius: 64,
        color: const Color(0xFFFFD86A),
      ),
    );
    game.world.add(Confetti(position: position.clone(), count: 14));
    game.shake(0.15);
    for (final e in game.enemies.toList()) {
      if (e.mid.distanceTo(position) < 64) e.hit(heavy: true);
    }
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(sin(_t * 18) * 0.25);
    _pixmap(canvas, _rows, _pal);
    canvas.restore();
  }
}

/// The POLIS car: speeds through the player's lane flattening enemies.
class PoliceCar extends PositionComponent with HasGameReference<MemesGame> {
  PoliceCar({required super.position, required this.dir}) : super(priority: 26);

  final int dir;
  double _t = 0;

  static final _white = _p(0xFFF4F6FA);
  static final _shade = _p(0xFFC9D0DC);
  static final _ink = _p(0xFF3A2440);
  static final _glass = _p(0xFF7FB8E8);
  static final _tyre = _p(0xFF26222C);
  static final _red = _p(0xFFFF4D5E);
  static final _blue = _p(0xFF4D7CFF);
  static final _dim = _p(0xFF6A6A7A);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.x += dir * 520 * dt;
    for (final e in game.enemies.toList()) {
      final d = e.position - position;
      if (!e.dead && d.x.abs() < 34 && d.y.abs() < 40) e.hit(heavy: true);
    }
    if (_t > 2.2) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (dir < 0) canvas.scale(-1, 1);
    // Body (feet = bottom-center).
    canvas.drawRect(const Rect.fromLTWH(-30, -22, 60, 12), _ink);
    canvas.drawRect(const Rect.fromLTWH(-29, -21, 58, 10), _white);
    canvas.drawRect(const Rect.fromLTWH(-29, -13, 58, 2), _shade);
    canvas.drawRect(const Rect.fromLTWH(-16, -32, 30, 11), _ink);
    canvas.drawRect(const Rect.fromLTWH(-15, -31, 28, 10), _white);
    canvas.drawRect(const Rect.fromLTWH(-13, -29, 11, 7), _glass);
    canvas.drawRect(const Rect.fromLTWH(0, -29, 11, 7), _glass);
    canvas.drawRect(const Rect.fromLTWH(26, -19, 3, 3), _p(0xFFFFE07A));
    // Siren.
    final on = (_t * 8).floor().isEven;
    canvas.drawRect(const Rect.fromLTWH(-6, -36, 6, 4), on ? _red : _dim);
    canvas.drawRect(const Rect.fromLTWH(0, -36, 6, 4), on ? _dim : _blue);
    // "POLIS" stripe.
    canvas.drawRect(const Rect.fromLTWH(-24, -18, 44, 3), _blue);
    // Wheels.
    for (final x in [-18.0, 18.0]) {
      canvas.drawCircle(Offset(x, -7), 7, _tyre);
      canvas.drawCircle(Offset(x, -7), 3, _shade);
    }
    canvas.restore();
  }
}

/// Patrick's water jet: a short-lived beam of droplets.
class WaterJet extends PositionComponent with HasGameReference<MemesGame> {
  WaterJet({required super.position, required this.dir}) : super(priority: 26);

  final int dir;
  double _t = 0;
  static const _len = 190.0;
  static const _d = 0.45;
  static final _water = _p(0xFF7FD4FF);
  static final _light = _p(0xFFE6F8FF);

  @override
  Future<void> onLoad() async {
    for (final e in game.enemies.toList()) {
      final d = e.mid - position;
      if (d.x * dir > -6 && d.x * dir < _len && d.y.abs() < 22) {
        e.hit(heavy: true);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final reach = _len * min(1.0, _t / 0.15);
    final fade = 1.0 - max(0.0, (_t - 0.25) / (_d - 0.25));
    final paint = _water..color = _water.color.withValues(alpha: fade);
    for (var x = 0.0; x < reach; x += 6) {
      final wob = sin(x * 0.2 + _t * 30) * 2;
      final h = 6 - x / _len * 2;
      canvas.drawRect(Rect.fromLTWH(dir * x - 3, wob - h / 2, 6, h), paint);
      if ((x ~/ 6).isEven) {
        canvas.drawRect(Rect.fromLTWH(dir * x - 1, wob - 1, 2, 2), _light);
      }
    }
  }
}
