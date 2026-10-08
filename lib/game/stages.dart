import 'level.dart';

/// An arena: a floating island (or islands) with platforms, built from a
/// small description instead of hand-drawn ASCII so every arena is
/// consistent: the island tapers underneath, spawns sit on the ground.
class Stage {
  const Stage({
    required this.name,
    required this.theme,
    required this.islands,
    this.platforms = const [],
    this.blocks = const [],
    this.moving = const [],
    this.music = 'level',
  });

  final String name;
  final LevelTheme theme;

  /// Solid islands: (top row, first col, last col).
  final List<(int, int, int)> islands;

  /// One-way platforms: (row, first col, last col).
  final List<(int, int, int)> platforms;

  /// Extra solid blocks: (top row, bottom row, first col, last col).
  final List<(int, int, int, int)> blocks;

  /// Moving platforms: (row, col).
  final List<(int, int)> moving;
  final String music;

  static const cols = 40;
  static const rows = 16;

  /// World coordinates of the arena (in tiles) are 0..cols x 0..rows;
  /// fighters are KO'd beyond these margins.
  static const blastSide = 7.0;
  static const blastTop = 9.0;
  static const blastBottom = 5.0;

  int get mainTop => islands.map((i) => i.$1).reduce((a, b) => a < b ? a : b);

  /// Leftmost / rightmost walkable column of the islands.
  int get left => islands.map((i) => i.$2).reduce((a, b) => a < b ? a : b);
  int get right => islands.map((i) => i.$3).reduce((a, b) => a > b ? a : b);

  LevelData build(int index) {
    final g = List.generate(rows, (_) => List.filled(cols, ' '));
    void put(int r, int c, String t) {
      if (r >= 0 && r < rows && c >= 0 && c < cols) g[r][c] = t;
    }

    for (final (top, c0, c1) in islands) {
      // A floating island: full width on top, tapering below.
      for (var r = top; r < rows - 1; r++) {
        final inset = switch (r - top) { 0 || 1 => 0, 2 => 1, 3 => 2, _ => 4 };
        if (c1 - c0 - 2 * inset < 2) break;
        for (var c = c0 + inset; c <= c1 - inset; c++) {
          put(r, c, '#');
        }
        if (r - top >= 4) break;
      }
    }
    for (final (top, bottom, c0, c1) in blocks) {
      for (var r = top; r <= bottom; r++) {
        for (var c = c0; c <= c1; c++) {
          put(r, c, '#');
        }
      }
    }
    for (final (r, c0, c1) in platforms) {
      for (var c = c0; c <= c1; c++) {
        put(r, c, '=');
      }
    }
    for (final (r, c) in moving) {
      put(r, c, 'M');
    }
    return LevelData(
      index: index,
      theme: theme,
      parTime: 0,
      map: g.map((r) => r.join()).join('\n'),
      walls: false,
    );
  }

  static const all = [
    Stage(
      name: 'Campo del Feed',
      theme: LevelTheme.feed,
      islands: [(10, 7, 32)],
      platforms: [(7, 10, 15), (7, 24, 29), (4, 17, 22)],
    ),
    Stage(
      name: 'Sezione Commenti',
      theme: LevelTheme.comments,
      islands: [(10, 8, 31)],
      platforms: [(7, 9, 14), (7, 25, 30), (5, 17, 22)],
    ),
    Stage(
      name: 'Spiaggia Finale',
      theme: LevelTheme.beach,
      islands: [(10, 5, 34)],
    ),
    Stage(
      name: 'Duna dei Like',
      theme: LevelTheme.desert,
      islands: [(10, 7, 32)],
      blocks: [(8, 9, 17, 22)],
      platforms: [(6, 9, 14), (6, 25, 30)],
    ),
    Stage(
      name: 'Iceberg Cringe',
      theme: LevelTheme.ice,
      islands: [(10, 5, 16), (10, 23, 34)],
      platforms: [(7, 16, 23), (4, 18, 21)],
    ),
    Stage(
      name: 'Torta dei Trend',
      theme: LevelTheme.candy,
      islands: [(10, 7, 32)],
      platforms: [(8, 9, 12), (6, 14, 17), (6, 22, 25), (8, 27, 30)],
    ),
    Stage(
      name: 'Radura dei Meme',
      theme: LevelTheme.forest,
      islands: [(10, 10, 29)],
      platforms: [(7, 5, 12), (7, 27, 34), (4, 16, 23)],
    ),
    Stage(
      name: 'Cratere Flame',
      theme: LevelTheme.volcano,
      islands: [(10, 7, 32)],
      blocks: [(8, 9, 7, 8), (8, 9, 31, 32)],
      platforms: [(6, 15, 24)],
      music: 'boss',
    ),
    Stage(
      name: 'Nuvole Virali',
      theme: LevelTheme.clouds,
      islands: [(11, 13, 26)],
      platforms: [(8, 6, 12), (8, 27, 33), (5, 15, 24), (11, 7, 11), (11, 28, 32)],
    ),
    Stage(
      name: 'Data Center',
      theme: LevelTheme.server,
      islands: [(10, 7, 32)],
      platforms: [(7, 9, 13), (7, 26, 30)],
      moving: [(5, 19)],
      music: 'boss',
    ),
  ];
}
