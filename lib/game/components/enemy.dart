import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/meme_character.dart';
import '../../services/sound.dart';
import '../memes_game.dart';
import '../pixel.dart';
import 'body.dart';
import 'effects.dart';
import 'projectile.dart';

/// The "anti-meme" forces.
enum EnemyKind {
  normie('normie', 'Normie', 40, 1, 25),
  cringe('cringe', 'Cringe', 55, 1, 25),
  hater('hater', 'Hater', 30, 1, 40),
  boomer('boomer', 'Boomer', 24, 2, 50),
  algorithm('algorithm', 'L\'Algoritmo', 70, 5, 500);

  const EnemyKind(this.sprite, this.label, this.speed, this.hp, this.score);

  final String sprite;
  final String label;
  final double speed;
  final int hp;
  final int score;

  bool get isBoss => this == EnemyKind.algorithm;
  String get spritePath => 'sprites/enemy_$sprite.png';

  static EnemyKind? fromCode(String code) => switch (code) {
    'n' => normie,
    'c' => cringe,
    'h' => hater,
    'b' => boomer,
    'A' => algorithm,
    _ => null,
  };
}

class Enemy extends PositionComponent
    with HasGameReference<MemesGame>, TileBody {
  Enemy({required this.kind, required super.position}) : super(priority: 15) {
    hp = kind.hp;
    final s = kind.isBoss ? 46.0 : 20.0;
    bodyWidth = s;
    bodyHeight = s;
  }

  final EnemyKind kind;
  late int hp;
  late int maxHp;
  late final Strip _strip;
  final _rnd = Random();

  int _dir = -1;
  double _t = 0;
  double _flash = 0;
  double _hurtCooldown = 0;
  double frozenTime = 0;
  double scaredTime = 0;
  double _actionTimer = 1.5;
  double _talk = 3;

  static const _lines = {
    EnemyKind.normie: [
      'Ma è un meme?',
      'LOL',
      'Non ho capito',
      'Mi piace il pane',
      'Che ridere.',
    ],
    EnemyKind.cringe: ['uwu', 'Rawr XD', '*imbarazzo*', '...ok', 'Sono quirky'],
    EnemyKind.hater: ['RATIO', 'Cringe.', 'L + ratio', 'Unfollow!', 'Mid.'],
    EnemyKind.boomer: [
      'Buongiornissimo!',
      'Kaffè?',
      'Ai miei tempi...',
      'Inoltro su WhatsApp',
      'Cos\'è un meme?',
    ],
    EnemyKind.algorithm: [
      'Engagement!',
      'Shadowban!',
      'Contenuto sponsorizzato',
    ],
  };
  bool dead = false;

  bool get frozen => frozenTime > 0;
  bool get scared => scaredTime > 0;
  Vector2 get mid => position - Vector2(0, bodyHeight / 2);

  @override
  Future<void> onLoad() async {
    maxHp = hp = kind.isBoss ? game.level.bossHp : kind.hp;
    final img = game.images.fromCache(kind.spritePath);
    final fw = kind.isBoss ? 56.0 : 28.0;
    _strip = Strip(img, fw, fw);
    _actionTimer = 1 + _rnd.nextDouble() * 2;
    _talk = 1.5 + _rnd.nextDouble() * 6;
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

  void freeze(double seconds) {
    if (dead) return;
    frozenTime = seconds;
    velocity.x = 0;
  }

  void scare(double seconds) {
    if (dead) return;
    scaredTime = seconds;
    frozenTime = 0;
  }

  /// Stomped, slashed, dashed through...
  void hit({bool heavy = false, bool stomp = false}) {
    if (dead || _hurtCooldown > 0) return;
    final bossDamage = game.character.passive == Passive.bossBrawler ? 2 : 1;
    hp -= kind.isBoss ? bossDamage : (heavy ? hp : 1);
    _flash = 0.15;
    if (kind.isBoss) {
      Sound.play('boss_hit');
      _hurtCooldown = 1.0;
      frozenTime = 0;
      game.shake(0.3);
      // The algorithm gets angrier.
      _actionTimer = 0.4;
    }
    if (hp <= 0) {
      dead = true;
      if (stomp && !kind.isBoss) {
        // Squashed flat like a pancake, then poof.
        game.world.add(
          FlatEnemy(strip: _strip, position: position.clone(), flip: _dir > 0),
        );
      } else {
        game.world.add(PoofEffect(position: mid));
      }
      game.onEnemyKilled(this);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt * game.enemyTimeScale);
    _tick(dt * game.enemyTimeScale);
  }

  void _tick(double dt) {
    if (game.isOver) return; // everyone freezes for the game over hop
    _t += dt;
    if (_flash > 0) _flash -= dt;
    if (_hurtCooldown > 0) _hurtCooldown -= dt;
    if (scaredTime > 0) scaredTime -= dt;
    if (game.finished) return;

    if (frozenTime > 0) {
      frozenTime -= dt;
      velocity.x = 0;
      applyGravity(dt);
      moveAndCollide(dt);
      return;
    }

    final player = game.player;
    final dx = player.position.x - position.x;
    final near = dx.abs() < 420;
    if (!near && !kind.isBoss) {
      // Sleep off-screen: no need to simulate the whole level.
      return;
    }

    _talk -= dt;
    if (_talk <= 0 && dx.abs() < 200 && !scared) {
      _talk = 6 + _rnd.nextDouble() * 8;
      final lines = _lines[kind]!;
      game.world.add(
        SpeechBubble(speaker: this, text: lines[_rnd.nextInt(lines.length)]),
      );
    }

    var speed = kind.speed;
    if (scared) {
      _dir = dx > 0 ? -1 : 1;
      speed *= 1.6;
    }
    if (kind.isBoss) speed *= 1 + (maxHp - hp) / maxHp * 0.8;

    _actionTimer -= dt;
    switch (kind) {
      case EnemyKind.cringe:
        // Nervous little hops.
        if (onGround && _actionTimer <= 0) {
          velocity.y = -330;
          _actionTimer = 1 + _rnd.nextDouble();
        }
      case EnemyKind.hater:
        if (!scared &&
            _actionTimer <= 0 &&
            dx.abs() < 260 &&
            (player.position.y - position.y).abs() < 60) {
          _dir = dx > 0 ? 1 : -1;
          game.world.add(
            RatioProjectile(
              position: position - Vector2(0, 14),
              direction: _dir,
            ),
          );
          _actionTimer = 2.4;
        }
      case EnemyKind.algorithm:
        if (dx.abs() < 400) _dir = dx > 0 ? 1 : -1;
        if (onGround && _actionTimer <= 0) {
          velocity.y = -520;
          _actionTimer = 2.2 - (maxHp - hp) / maxHp * 1.2;
          if (game.enemies.length < 4) game.spawnMinion(position.clone());
        }
      default:
        break;
    }

    velocity.x = _dir * speed;
    applyGravity(dt);
    moveAndCollide(dt);
    if (hitWall) _dir = -_dir;
    if (onGround &&
        !kind.isBoss &&
        kind != EnemyKind.cringe &&
        ledgeAhead(_dir)) {
      _dir = -_dir;
    }
    if (position.y > game.level.height + 100) {
      dead = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fw = _strip.frameWidth;
    if (onGround) {
      canvas.drawOval(
        Rect.fromLTRB(-bodyWidth * .6, -2.5, bodyWidth * .6, 2.5),
        Paint()..color = const Color(0x333A2440),
      );
    }
    final frame = frozen ? 0 : ((_t * (kind.isBoss ? 4 : 6)).floor() % 2);
    Paint? paint;
    if (_flash > 0 || (_hurtCooldown > 0 && (_t * 16).floor().isEven)) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
    } else if (frozen) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0x8870D0FF),
          BlendMode.srcATop,
        );
    } else if (scared) {
      paint = Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = const ColorFilter.mode(
          Color(0x55B388FF),
          BlendMode.srcATop,
        );
    }
    final shake = scared ? sin(_t * 60) : 0.0;
    _strip.draw(
      canvas,
      frame,
      Offset(-fw / 2 + shake, -fw),
      flip: _dir > 0,
      paint: paint,
    );
    if (frozen) {
      canvas.drawRect(
        Rect.fromLTRB(-fw / 2, -fw, fw / 2, 0),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFBDEBFF),
      );
    }
    if (kind.isBoss) {
      const w = 50.0;
      canvas.drawRect(
        const Rect.fromLTWH(-w / 2, -64, w, 5),
        Paint()..color = Colors.black87,
      );
      canvas.drawRect(
        Rect.fromLTWH(-w / 2 + 1, -63, (w - 2) * hp / maxHp, 3),
        Paint()..color = const Color(0xFF2ECC71),
      );
    }
  }
}

/// A stomped enemy, squashed flat for a moment before vanishing.
class FlatEnemy extends PositionComponent {
  FlatEnemy({required this.strip, required super.position, required this.flip})
    : super(priority: 14);

  final Strip strip;
  final bool flip;
  double _t = 0;
  static const _d = 0.4;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _d) {
      parent?.add(PoofEffect(position: position - Vector2(0, 6)));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fw = strip.frameWidth;
    final squash = 0.35 + 0.1 * sin(_t * 40).abs() * (1 - _t / _d);
    canvas.save();
    canvas.scale(1.25, squash);
    strip.draw(
      canvas,
      0,
      Offset(-fw / 2, -fw),
      flip: flip,
      paint: Paint()
        ..filterQuality = FilterQuality.none
        ..color = Color.fromRGBO(255, 255, 255, 1 - (_t / _d) * .5),
    );
    canvas.restore();
  }
}

/// A little pixel speech bubble above an enemy.
class SpeechBubble extends PositionComponent {
  SpeechBubble({required this.speaker, required this.text})
    : super(priority: 38);

  final Enemy speaker;
  final String text;
  double _t = 0;
  static const _d = 2.0;
  late final TextPainter _tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'Pixelify',
        fontSize: 7,
        fontWeight: FontWeight.w700,
        color: Color(0xFF3A2440),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void update(double dt) {
    _t += dt;
    if (!speaker.dead) {
      position.setFrom(speaker.position - Vector2(0, speaker.bodyHeight + 12));
    }
    if (_t >= _d) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final pop = _t < .12 ? _t / .12 : (_t > _d - .15 ? (_d - _t) / .15 : 1.0);
    canvas.save();
    canvas.scale(pop.clamp(0.01, 1));
    final w = _tp.width + 8;
    final h = _tp.height + 4;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w / 2, -h, w, h),
      const Radius.circular(3),
    );
    final tail = Path()
      ..moveTo(-3, -0.5)
      ..lineTo(3, -0.5)
      ..lineTo(-1, 4)
      ..close();
    final fill = Paint()..color = Colors.white;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF3A2440);
    canvas.drawRRect(r, fill);
    canvas.drawRRect(r, line);
    canvas.drawPath(tail, fill);
    canvas.drawPath(tail, line);
    canvas.drawRect(const Rect.fromLTWH(-2.5, -1.5, 5, 1.5), fill);
    _tp.paint(canvas, Offset(-_tp.width / 2, -h + 2));
    canvas.restore();
  }
}
