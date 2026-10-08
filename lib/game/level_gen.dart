import 'dart:math';

import 'level.dart';
import 'level_solver.dart';

/// Total number of levels: 10 worlds × 50.
const kLevelCount = 500;
const kLevelsPerWorld = 50;

final Map<int, LevelData> _cache = {};

/// The level at [index] (0-based). Levels are generated procedurally from a
/// fixed seed, so every player gets the same 500 levels, and each one is
/// checked with [LevelSolver] (a failing layout is regenerated with the next
/// seed).
LevelData levelAt(int index) => _cache.putIfAbsent(index, () {
  for (var attempt = 0; attempt < 40; attempt++) {
    final level = LevelGenerator(index, attempt).build();
    if (LevelSolver(level).solve()) return level;
  }
  // Practically unreachable: fall back to a gentle layout.
  return LevelGenerator(index, 0, forceEasy: true).build();
});

/// Deterministic PRNG (Park–Miller), identical on the VM and on the web.
class Rng {
  Rng(int seed) : _s = (seed % 2147483646) + 1;
  int _s;

  int _next() => _s = (_s * 48271) % 2147483647;

  double next() => (_next() - 1) / 2147483646;
  int nextInt(int max) => (next() * max).floor().clamp(0, max - 1);
  bool chance(double p) => next() < p;
  int range(int lo, int hi) => lo + nextInt(hi - lo + 1);
  T pick<T>(List<T> items) => items[nextInt(items.length)];
}

class LevelGenerator {
  LevelGenerator(this.index, this.attempt, {this.forceEasy = false})
    : rnd = Rng(index * 7919 + attempt * 104729 + 17);

  final int index;
  final int attempt;
  final bool forceEasy;
  final Rng rnd;

  static const rows = 14;
  static const maxCols = 260;

  late final int world = index ~/ kLevelsPerWorld;
  late final int local = index % kLevelsPerWorld;
  late final bool boss = local == kLevelsPerWorld - 1;

  /// 0 → 1 across the campaign, with a small ramp inside each world. The
  /// curve is eased (slow at first) so the middle worlds stay fun.
  late final double diff = forceEasy
      ? 0
      : (pow(index / (kLevelCount - 1), 1.35) * 0.82 +
                local / kLevelsPerWorld * 0.18)
            .clamp(0.0, 1.0)
            .toDouble();

  final _g = List.generate(rows, (_) => List.filled(maxCols, ' '));
  int _col = 0;

  /// Row of the ground surface (the first solid row).
  int _h = 12;

  /// Columns where the next checkpoints go (one every ~65 columns).
  final List<int> _checkpoints = [];

  LevelData build() {
    final length =
        (60 + (index / 10).clamp(0, 1) * 20 + diff * 100 + rnd.nextInt(20))
            .round();
    final n = (length / 65).floor().clamp(1, 3);
    for (var k = 1; k <= n; k++) {
      _checkpoints.add(length * k ~/ (n + 1));
    }
    _flat(6, likes: false, enemies: false);
    _put(2, _h - 1, 'P');
    while (_col < length - 14) {
      if (_checkpoints.isNotEmpty && _col > _checkpoints.first) {
        _checkpoints.removeAt(0);
        _flat(4, likes: false, enemies: false);
        _put(_col - 2, _h - 1, 'K');
        continue;
      }
      _chunk();
    }
    if (boss) {
      _bossArena();
    } else {
      _flat(10, likes: true, enemies: false);
    }
    _put(_col - 4, _h - 1, 'F');
    final map = [for (final row in _g) row.sublist(0, _col).join()].join('\n');
    return LevelData(
      index: index,
      theme: LevelTheme.values[world.clamp(0, LevelTheme.values.length - 1)],
      parTime: 40 + length ~/ 2,
      map: map,
      bossHp: 4 + world,
    );
  }

  // ------------------------------------------------------------ primitives

  void _put(int c, int r, String ch) {
    if (c < 0 || c >= maxCols || r < 0 || r >= rows) return;
    _g[r][c] = ch;
  }

  String _at(int c, int r) => _g[r][c];

  void _ground(int c, int top) {
    for (var r = top; r < rows; r++) {
      _put(c, r, '#');
    }
  }

  // ---------------------------------------------------------------- chunks

  void _chunk() {
    // The first levels are a gentle tutorial; new obstacles are introduced
    // one at a time and get more frequent with the difficulty.
    final early = (index / 10).clamp(0.0, 1.0);
    final options = <(double, void Function())>[
      (4 - diff * 2, () => _flat(rnd.range(3, 6))),
      (0.6 + early + diff * 2.5, _gap),
      (1.2, _stepUp),
      (1.0, _stepDown),
      (index >= 3 ? 0.4 + early * 0.6 + diff * 3 : 0, _platformsOverPit),
      (index >= 4 ? 0.6 + diff * 2 : 0, _spikes),
      (1.6, _blocks),
      (index >= 8 && _h >= 9 ? 0.8 + diff : 0, _springWall),
      (index >= 12 ? 0.6 + diff * 1.5 : 0, _movingPlatform),
      (index >= 6 ? 0.8 : 0, _tunnel),
      (0.6 + early * 0.4 + diff * 2.5, _enemyGroup),
    ];

    final total = options.fold(0.0, (s, o) => s + o.$1);
    var r = rnd.next() * total;
    for (final (w, f) in options) {
      r -= w;
      if (r <= 0) {
        f();
        return;
      }
    }
    _flat(4);
  }

  void _flat(int len, {bool likes = true, bool enemies = true}) {
    final start = _col;
    for (var i = 0; i < len; i++) {
      _ground(_col++, _h);
    }
    if (likes && rnd.chance(.35) && len >= 3) {
      for (var c = start + 1; c < _col - 1; c++) {
        _put(c, _h - 1, 'o');
      }
    } else if (enemies && len >= 4 && rnd.chance(.2 + diff * .5)) {
      _put(start + len ~/ 2, _h - 1, _enemy());
    }
  }

  String _enemy() {
    final pool = <String>['n', 'n'];
    if (index >= 2) pool.add('c');
    if (index >= 15) pool.add('b');
    if (index >= 40) pool.addAll(['h', if (diff > .5) 'h']);
    if (diff > .3) pool.add('c');
    return rnd.pick(pool);
  }

  void _gap() {
    final w = rnd.range(2, diff < .15 ? 2 : 3);
    final mid = _col + w ~/ 2;
    _col += w;
    final dh = rnd.pick([-1, 0, 0, 1]);
    if (rnd.chance(.5)) _put(mid, _h - 3, 'o');
    _h = (_h + dh).clamp(8, 12);
    _flat(rnd.range(2, 4), enemies: false);
  }

  void _stepUp() {
    if (_h <= 7) return _flat(3);
    final up = rnd.range(1, _h <= 8 ? 1 : 2);
    final bricks = rnd.chance(.4);
    for (var i = 1; i <= up; i++) {
      final c = _col++;
      _ground(c, _h);
      if (bricks) {
        for (var r = _h - i; r < _h; r++) {
          _put(c, r, 'B');
        }
      } else {
        _ground(c, _h - i);
      }
    }
    _h -= up;
    _flat(rnd.range(2, 4), enemies: false);
  }

  void _stepDown() {
    if (_h >= 12) return _flat(3);
    _h = (_h + rnd.range(1, 2)).clamp(8, 12);
    _flat(rnd.range(3, 5));
  }

  void _platformsOverPit() {
    final pit = rnd.range(5, 6 + (diff * 7).round());
    final start = _col;
    final end = start + pit;
    var surface = _h; // row we jump from
    var x = start;
    while (true) {
      final gap = rnd.range(1, diff < .3 ? 2 : 3);
      if (x + gap >= end - 1) break;
      final w = rnd.range(2, 3);
      // Row the platform sits on: at most 2 up from where we jump.
      final row = (surface + rnd.range(-2, 1)).clamp(_h - 3, _h - 1);
      for (var c = x + gap; c < x + gap + w && c < end; c++) {
        _put(c, row, '=');
        if (rnd.chance(.5)) _put(c, row - 1, 'o');
      }
      surface = row;
      x += gap + w;
      if (end - x <= 3) break;
    }
    _col = end;
    _flat(rnd.range(2, 4), enemies: false);
  }

  void _spikes() {
    _flat(2, likes: false, enemies: false);
    final n = rnd.range(1, diff < .25 ? 1 : 2);
    for (var i = 0; i < n; i++) {
      _ground(_col, _h);
      _put(_col++, _h - 1, '^');
    }
    _flat(2, likes: false, enemies: false);
  }

  void _blocks() {
    final start = _col;
    _flat(6, likes: false);
    final row = _h - 4;
    if (row < 1) return;
    final power = index >= 1 && rnd.chance(.3) ? start + rnd.range(1, 4) : -1;
    for (var c = start + 1; c < start + 5; c++) {
      _put(c, row, c == power ? '!' : (rnd.chance(.45) ? '?' : 'B'));
    }
    if (rnd.chance(.5)) {
      for (var c = start + 1; c < start + 5; c++) {
        if (row - 1 >= 0) _put(c, row - 1, 'o');
      }
    }
  }

  void _springWall() {
    _flat(2, likes: false, enemies: false);
    _ground(_col, _h);
    _put(_col++, _h - 1, 'S');
    final top = _h - rnd.range(5, 6);
    if (top < 2) return;
    for (var i = 0; i < 2; i++) {
      _ground(_col++, top);
    }
    _h = top;
    for (var r = _h - 3; r >= _h - 4 && r >= 0; r--) {
      _put(_col - 1, r, 'o');
    }
    _flat(rnd.range(3, 5), enemies: false);
  }

  void _movingPlatform() {
    final pit = rnd.range(9, 11);
    final center = _col + pit ~/ 2;
    _put(center, _h - 1, 'M');
    for (var c = center - 1; c <= center + 1; c++) {
      if (rnd.chance(.6)) _put(c, _h - 3, 'o');
    }
    _col += pit;
    _flat(rnd.range(3, 4), enemies: false);
  }

  void _tunnel() {
    final len = rnd.range(5, 8);
    final start = _col;
    _flat(len, likes: false, enemies: false);
    for (var c = start + 1; c < start + len - 1; c++) {
      _put(c, _h - 3, 'B');
      if (_at(c, _h - 1) == ' ' && rnd.chance(.3)) _put(c, _h - 1, 'o');
    }
    if (rnd.chance(.4 + diff * .4)) _put(start + len ~/ 2, _h - 1, _enemy());
  }

  void _enemyGroup() {
    final len = rnd.range(6, 10);
    final start = _col;
    _flat(len, likes: false, enemies: false);
    final n = 1 + (diff * 2.5).floor().clamp(0, 2) + (rnd.chance(.3) ? 1 : 0);
    for (var i = 0; i < n; i++) {
      final c = start + 1 + ((len - 2) * (i + 1) / (n + 1)).floor();
      _put(c, _h - 1, _enemy());
    }
  }

  void _bossArena() {
    _h = 12;
    _flat(4, likes: false, enemies: false);
    final start = _col;
    _flat(30, likes: false, enemies: false);
    for (final (c, r) in [(5, 9), (22, 9), (13, 7)]) {
      for (var i = 0; i < 4; i++) {
        _put(start + c + i, r, '=');
      }
    }
    _put(start + 18, _h - 1, 'A');
    for (var r = 0; r < _h; r++) {
      _put(_col, r, 'G');
    }
    _ground(_col++, _h);
    _flat(8, likes: true, enemies: false);
  }
}
