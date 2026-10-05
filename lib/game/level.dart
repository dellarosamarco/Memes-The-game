import 'package:flame/components.dart';

/// Tile size in world units (= pixels of the pixel art).
const double kTile = 24;

enum LevelTheme { feed, comments, server }

/// Something placed in the level by a letter in the ASCII map.
class Spawn {
  const Spawn(this.code, this.col, this.row);
  final String code;
  final int col;
  final int row;

  /// Bottom-center of the tile, where entities stand.
  Vector2 get feet => Vector2((col + .5) * kTile, (row + 1) * kTile);
}

/// A level described as ASCII art.
///
/// Legend:
///   `#` ground     `B` brick      `=` one-way platform   `^` spikes
///   `?` like block `G` boss gate (opens when the boss dies)
///   `o` like       `K` checkpoint `F` finish flag        `P` player start
///   `n` normie     `c` cringe     `h` hater   `b` boomer  `A` L'Algoritmo
class LevelData {
  LevelData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.theme,
    required this.parTime,
    required this.map,
  }) {
    final lines = map.split('\n');
    // Only drop the empty lines around the raw string; rows made of spaces
    // are real (empty) rows of the level.
    if (lines.isNotEmpty && lines.first.isEmpty) lines.removeAt(0);
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
    cols = lines.fold(0, (m, l) => l.length > m ? l.length : m);
    rows = lines.length;
    for (var r = 0; r < rows; r++) {
      final line = lines[r].padRight(cols);
      final row = <String>[];
      for (var c = 0; c < cols; c++) {
        final ch = line[c];
        if ('#B=^?G'.contains(ch)) {
          row.add(ch);
        } else {
          row.add(' ');
          if (ch != ' ' && ch != '.') spawns.add(Spawn(ch, c, r));
        }
      }
      _grid.add(row);
    }
  }

  final String id;
  final String map;
  final String name;
  final String subtitle;
  final LevelTheme theme;

  /// Seconds under which the player earns a time bonus.
  final int parTime;

  late final int cols;
  late final int rows;
  final List<List<String>> _grid = [];
  final List<Spawn> spawns = [];

  double get width => cols * kTile;
  double get height => rows * kTile;

  int get totalLikes =>
      spawns.where((s) => s.code == 'o').length +
      _grid.expand((r) => r).where((t) => t == '?').length;

  String tileAt(int c, int r) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return ' ';
    return _grid[r][c];
  }

  void setTile(int c, int r, String t) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    _grid[r][c] = t;
  }

  /// Fully solid tiles. The level's left/right edges act as walls.
  bool isSolid(int c, int r) {
    if (c < 0 || c >= cols) return true;
    return const {'#', 'B', '?', 'U', 'G'}.contains(tileAt(c, r));
  }

  bool isOneWay(int c, int r) => tileAt(c, r) == '=';

  bool isStandable(int c, int r) => isSolid(c, r) || isOneWay(c, r);

  /// Fresh copy, so a restarted level gets its blocks and gates back.
  LevelData copy() => LevelData(
    id: id,
    name: name,
    subtitle: subtitle,
    theme: theme,
    parTime: parTime,
    map: map,
  );
}
