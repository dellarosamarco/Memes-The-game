import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/sound.dart';
import '../fighter/fighter.dart';
import '../memes_game.dart';
import 'body.dart';
import 'effects.dart';

Paint _p(int c) => Paint()..color = Color(c);

/// Draws a little pixel picture from rows of palette letters ('.' = empty),
/// bottom-centered on the origin.
void _pixmap(
  Canvas canvas,
  List<String> rows,
  Map<String, Paint> palette, {
  bool flip = false,
  double px = 2,
}) {
  final w = rows.first.length;
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < w; x++) {
      final p = palette[rows[y][x]];
      if (p == null) continue;
      final dx = flip ? w - 1 - x : x;
      canvas.drawRect(
        Rect.fromLTWH((dx - w / 2) * px, (y - rows.length) * px, px, px),
        p,
      );
    }
  }
}

enum ProjectileKind { plush, rock, egg, chick, police, waterJet }

/// Things the specials throw, send or summon. They hurt the owner's
/// opponents (helmets bounce projectiles).
class FightProjectile extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  FightProjectile._(
    this.kind,
    this.owner, {
    required super.position,
    this.delay = 0,
  }) : dir = owner.facingRight ? 1 : -1,
       super(priority: 26);

  factory FightProjectile.plush(Fighter f) => FightProjectile._(
    ProjectileKind.plush,
    f,
    position: f.mid + Vector2(f.facingRight ? 14 : -14, 0),
  );

  factory FightProjectile.rock(Fighter f) => FightProjectile._(
    ProjectileKind.rock,
    f,
    position: f.mid - Vector2(0, 14),
  )..velocity.setValues(f.facingRight ? 300 : -300, -330);

  factory FightProjectile.egg(Fighter f) =>
      FightProjectile._(
          ProjectileKind.egg,
          f,
          position: f.position - Vector2(0, 8),
        )
        ..velocity.setValues(
          (f.facingRight ? 1 : -1) * 120 + f.velocity.x * .3,
          -140,
        );

  factory FightProjectile.chick(Fighter f, {double delay = 0}) =>
      FightProjectile._(
        ProjectileKind.chick,
        f,
        position: f.position + Vector2(f.facingRight ? 12 : -12, -2),
        delay: delay,
      );

  factory FightProjectile.police(Fighter f) {
    final view = f.game.camera.visibleWorldRect;
    final right = f.facingRight;
    return FightProjectile._(
      ProjectileKind.police,
      f,
      position: Vector2(right ? view.left - 40 : view.right + 40, f.position.y),
    );
  }

  factory FightProjectile.waterJet(Fighter f) => FightProjectile._(
    ProjectileKind.waterJet,
    f,
    position: f.mid + Vector2(f.facingRight ? 14 : -14, -6),
  );

  final ProjectileKind kind;
  final Fighter owner;
  final int dir;
  double delay;
  double _t = 0;
  bool _returning = false;
  int _bounces = 0;
  final Set<Fighter> _hit = {};

  Iterable<Fighter> get _targets =>
      game.fighters.where((f) => f != owner && f.alive && !_hit.contains(f));

  @override
  Future<void> onLoad() async {
    switch (kind) {
      case ProjectileKind.egg:
        bodyWidth = 14;
        bodyHeight = 16;
      case ProjectileKind.chick:
        bodyWidth = 16;
        bodyHeight = 18;
      default:
        break;
    }
    if (kind == ProjectileKind.waterJet) {
      Sound.play('spring', volume: .4);
      for (final o in _targets.toList()) {
        final d = o.mid - position;
        if (d.x * dir > -8 && d.x * dir < 190 && d.y.abs() < 34) {
          _strike(o, damage: 4, angle: 12, base: 420, growth: 2.5);
        }
      }
    }
  }

  void _strike(
    Fighter o, {
    required double damage,
    double angle = 40,
    double base = 220,
    double growth = 6,
    bool? right,
  }) {
    _hit.add(o);
    o.receiveHit(
      attacker: owner,
      damage: damage * (owner.character.passive.name == 'drip' ? 1.2 : 1),
      angle: angle,
      baseKb: base,
      kbGrowth: growth,
      towardsRight: right ?? dir > 0,
      projectile: true,
    );
  }

  Fighter? _touching(double radius) {
    for (final o in _targets) {
      if (o.mid.distanceTo(position) < radius ||
          o.hurtbox.contains(position.toOffset())) {
        return o;
      }
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (delay > 0) {
      delay -= dt;
      return;
    }
    _t += dt;
    switch (kind) {
      case ProjectileKind.plush:
        _plush(dt);
      case ProjectileKind.rock:
        _rock(dt);
      case ProjectileKind.egg:
        _egg(dt);
      case ProjectileKind.chick:
        _chick(dt);
      case ProjectileKind.police:
        _police(dt);
      case ProjectileKind.waterJet:
        if (_t > .45) removeFromParent();
    }
    if (position.y > game.level.height + 300 || _t > 4) removeFromParent();
  }

  void _plush(double dt) {
    if (_t > .45) _returning = true;
    if (_returning) {
      final to = owner.mid - position;
      if (to.length < 16 || _t > 2.5) {
        removeFromParent();
        return;
      }
      position += to.normalized() * 380 * dt;
    } else {
      position.x += dir * 340 * dt;
    }
    final o = _touching(18);
    if (o != null) {
      _strike(o, damage: 7, angle: 30, base: 200, growth: 4.5);
      _returning = true;
    }
  }

  void _rock(double dt) {
    velocity.y += 900 * dt;
    position += velocity * dt;
    final c = (position.x / 24).floor();
    final r = (position.y / 24).floor();
    if (game.level.isSolid(c, r)) {
      game.world.add(PoofEffect(position: position.clone()));
      removeFromParent();
      return;
    }
    final o = _touching(20);
    if (o != null) {
      _strike(o, damage: 10, angle: 40, base: 240, growth: 7);
      game.world.add(PoofEffect(position: position.clone()));
      removeFromParent();
    }
  }

  void _egg(double dt) {
    applyGravity(dt);
    moveAndCollide(dt);
    if (onGround) {
      _bounces++;
      velocity
        ..y = -150
        ..x *= .5;
    }
    if (_bounces >= 2 || _touching(22) != null || _t > 2.5) {
      game.world.add(
        ShockwaveEffect(
          position: position - Vector2(0, 4),
          maxRadius: 70,
          color: const Color(0xFFFFD86A),
        ),
      );
      game.world.add(Confetti(position: position.clone(), count: 14));
      game.shake(.15, intensity: 3);
      Sound.play('boss_hit', volume: .5);
      for (final o in _targets.toList()) {
        if (o.mid.distanceTo(position) < 70) {
          _strike(
            o,
            damage: 12,
            angle: 60,
            base: 250,
            growth: 7,
            right: o.position.x >= position.x,
          );
        }
      }
      removeFromParent();
    }
  }

  double _stuck = 0;

  void _chick(double dt) {
    velocity.x = dir * 220;
    if (onGround) velocity.y = hitWall ? -420 : -170;
    _stuck = hitWall ? _stuck + dt : 0;
    applyGravity(dt);
    moveAndCollide(dt);
    final o = _touching(22);
    if (o != null) _strike(o, damage: 7, angle: 45, base: 200, growth: 5);
    if (_t > 2.6 || _stuck > .4) {
      game.world.add(PoofEffect(position: position - Vector2(0, 9)));
      removeFromParent();
    }
  }

  void _police(double dt) {
    position.x += dir * 560 * dt;
    for (final o in _targets.toList()) {
      final d = o.position - position;
      if (d.x.abs() < 36 && d.y.abs() < 46) {
        _strike(o, damage: 14, angle: 35, base: 320, growth: 8.5);
        Sound.play('boss_hit', volume: .6);
      }
    }
    if (_t > 2.4) removeFromParent();
  }

  // ------------------------------------------------------------ render

  static final _chickPal = {
    'k': _p(0xFF1E1A22),
    'y': _p(0xFFFFD23F),
    'Y': _p(0xFFE8A91E),
    'o': _p(0xFFF08A24),
    'e': _p(0xFF101014),
  };
  static const _chickRows = [
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
  static final _eggPal = {
    'w': _p(0xFFFFF8EC),
    's': _p(0xFFE6D8C0),
    'k': _p(0xFF3A2440),
  };
  static const _eggRows = [
    '..kkk..',
    '.kwwwk.',
    'kwwwwwk',
    'kwwwwwk',
    'kwwwwsk',
    'kwwwssk',
    '.kssk..',
    '..kk...',
  ];
  static final _rockPal = {
    'k': _p(0xFF3A2440),
    'r': _p(0xFFD8D2C4),
    'R': _p(0xFFB0A898),
    'w': _p(0xFFF2EEE4),
  };
  static const _rockRows = [
    '.kkkkk.',
    'kwrrrRk',
    'krrRrRk',
    'krRrrRk',
    '.kRRRk.',
    '..kkk..',
  ];
  static final _white = _p(0xFFF4F0F8);
  static final _shade = _p(0xFFC9D0DC);
  static final _ink = _p(0xFF3A2440);
  static final _glass = _p(0xFF7FB8E8);
  static final _tyre = _p(0xFF26222C);
  static final _red = _p(0xFFFF4D5E);
  static final _blue = _p(0xFF4D7CFF);
  static final _dim = _p(0xFF6A6A7A);
  static final _water = _p(0xFF7FD4FF);
  static final _light = _p(0xFFE6F8FF);

  @override
  void render(Canvas canvas) {
    if (delay > 0) return;
    switch (kind) {
      case ProjectileKind.chick:
        _pixmap(canvas, _chickRows, _chickPal, flip: dir < 0);
      case ProjectileKind.egg:
        canvas.save();
        canvas.translate(0, -8);
        canvas.rotate(sin(_t * 18) * .25);
        canvas.translate(0, 8);
        _pixmap(canvas, _eggRows, _eggPal);
        canvas.restore();
      case ProjectileKind.rock:
        canvas.save();
        canvas.rotate(_t * 12 * dir);
        canvas.translate(0, 6);
        _pixmap(canvas, _rockRows, _rockPal);
        canvas.restore();
      case ProjectileKind.plush:
        canvas.save();
        canvas.rotate(_t * 14 * dir);
        canvas.drawRect(const Rect.fromLTWH(-7, -8, 14, 16), _white);
        canvas.drawRect(const Rect.fromLTWH(-8, -5, 16, 10), _white);
        canvas.drawRect(const Rect.fromLTWH(-8, 3, 16, 3), _shade);
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 3, 3), _ink);
        canvas.drawRect(const Rect.fromLTWH(1, -4, 3, 3), _ink);
        canvas.restore();
      case ProjectileKind.police:
        _renderCar(canvas);
      case ProjectileKind.waterJet:
        _renderJet(canvas);
    }
  }

  void _renderCar(Canvas canvas) {
    canvas.save();
    if (dir < 0) canvas.scale(-1, 1);
    canvas.drawRect(const Rect.fromLTWH(-30, -22, 60, 12), _ink);
    canvas.drawRect(const Rect.fromLTWH(-29, -21, 58, 10), _white);
    canvas.drawRect(const Rect.fromLTWH(-29, -13, 58, 2), _shade);
    canvas.drawRect(const Rect.fromLTWH(-16, -32, 30, 11), _ink);
    canvas.drawRect(const Rect.fromLTWH(-15, -31, 28, 10), _white);
    canvas.drawRect(const Rect.fromLTWH(-13, -29, 11, 7), _glass);
    canvas.drawRect(const Rect.fromLTWH(0, -29, 11, 7), _glass);
    canvas.drawRect(const Rect.fromLTWH(26, -19, 3, 3), _p(0xFFFFE07A));
    final on = (_t * 8).floor().isEven;
    canvas.drawRect(const Rect.fromLTWH(-6, -36, 6, 4), on ? _red : _dim);
    canvas.drawRect(const Rect.fromLTWH(0, -36, 6, 4), on ? _dim : _blue);
    canvas.drawRect(const Rect.fromLTWH(-24, -18, 44, 3), _blue);
    for (final x in [-18.0, 18.0]) {
      canvas.drawCircle(Offset(x, -7), 7, _tyre);
      canvas.drawCircle(Offset(x, -7), 3, _shade);
    }
    canvas.restore();
  }

  void _renderJet(Canvas canvas) {
    const len = 190.0;
    const d = .45;
    final reach = len * min(1.0, _t / .15);
    final fade = 1.0 - max(0.0, (_t - .25) / (d - .25));
    final paint = Paint()..color = _water.color.withValues(alpha: fade);
    for (var x = 0.0; x < reach; x += 6) {
      final wob = sin(x * .2 + _t * 30) * 2;
      final h = 14 - x / len * 6;
      canvas.drawRect(Rect.fromLTWH(dir * x - 3, wob - h / 2, 7, h), paint);
      if ((x ~/ 6).isEven) {
        canvas.drawRect(Rect.fromLTWH(dir * x - 2, wob - 3, 3, 3), _light);
      }
    }
  }
}
