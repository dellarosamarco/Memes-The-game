import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/sound.dart';
import '../fighter/fighter.dart';
import '../memes_game.dart';
import '../pixel.dart';
import 'body.dart';
import 'effects.dart';

/// Frames of `sprites/powerups.png`, in order.
enum ItemKind {
  sunglasses('Deal with it!'),
  stonks('STONKS'),
  pizza('Pizza! -20%'),
  coffee('Caffè!'),
  bomb('');

  const ItemKind(this.label);
  final String label;

  /// Good for whoever grabs it (the bomb is a hazard).
  bool get pickup => this != ItemKind.bomb;
}

/// An item dropped on the arena: touch it to use it. The bomb instead
/// starts ticking when it lands and blows up everyone nearby.
class FightItem extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  FightItem(this.kind, {required super.position}) : super(priority: 18) {
    bodyWidth = 22;
    bodyHeight = 22;
  }

  static const sheet = 'sprites/powerups.png';
  static const _life = 13.0;
  static const _fuse = 2.2;

  final ItemKind kind;
  late final Strip _strip;
  double _t = 0;
  double _fuseT = -1;
  bool get ticking => _fuseT >= 0;

  @override
  Future<void> onLoad() async {
    _strip = Strip(game.images.fromCache(sheet), 16, 16);
    velocity.y = 60;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.matchOver) return;
    _t += dt;
    applyGravity(dt);
    moveAndCollide(dt);
    if (position.y > game.blastZone.bottom) {
      removeFromParent();
      return;
    }
    if (kind == ItemKind.bomb) {
      if (onGround && !ticking) _fuseT = 0;
      if (ticking) {
        _fuseT += dt;
        if (_fuseT >= _fuse) _explode();
      }
      return;
    }
    if (_t > _life) {
      game.world.add(PoofEffect(position: position.clone()));
      removeFromParent();
      return;
    }
    final box = Rect.fromLTWH(left, top, bodyWidth, bodyHeight);
    for (final f in game.fighters) {
      if (f.alive && f.hurtbox.overlaps(box)) {
        _grab(f);
        return;
      }
    }
  }

  void _grab(Fighter f) {
    f.useItem(kind);
    Sound.play('like', volume: .7);
    game.world.add(Confetti(position: position.clone(), count: 14));
    game.world.add(
      FloatingText(
        position: f.mid - Vector2(0, 50),
        text: kind.label,
        fontSize: 11,
        color: const Color(0xFFFFE07A),
        duration: 1.2,
      ),
    );
    removeFromParent();
  }

  void _explode() {
    const radius = 95.0;
    game.world.add(
      ShockwaveEffect(
        position: position - Vector2(0, 10),
        maxRadius: radius,
        color: const Color(0xFFFF8A3D),
      ),
    );
    game.world.add(Confetti(position: position.clone(), count: 26));
    game.shake(.4, intensity: 7);
    Sound.play('boss_hit', volume: .9);
    for (final f in game.fighters.toList()) {
      if (!f.alive) continue;
      final d = f.mid - (position - Vector2(0, 10));
      if (d.length > radius) continue;
      f.receiveHit(
        attacker: null,
        damage: 16,
        angle: 62,
        baseKb: 320,
        kbGrowth: 8,
        towardsRight: d.x >= 0,
      );
    }
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Expiring pickups blink; the bomb flashes faster as the fuse burns.
    if (kind.pickup && _t > _life - 3 && (_t * 10).floor().isEven) return;
    final bob = kind.pickup && onGround ? sin(_t * 4) * 2 : 0.0;
    Paint? paint;
    if (ticking && (_fuseT * (4 + _fuseT * 6)).floor().isOdd) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0xAAFF4040),
          BlendMode.srcATop,
        );
    }
    if (kind.pickup) {
      // A soft glow so items read as "grab me".
      canvas.drawCircle(
        Offset(0, -12 + bob),
        15 + sin(_t * 6),
        Paint()..color = const Color(0x44FFF3A0),
      );
    }
    final s = ticking ? 1.6 + .15 * sin(_fuseT * 20) : 1.5;
    _strip.draw(
      canvas,
      kind.index,
      Offset(-8 * s, -16 * s + bob),
      scale: s,
      paint: paint,
    );
  }
}
