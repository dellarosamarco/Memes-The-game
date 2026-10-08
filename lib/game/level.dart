import 'package:flame/components.dart';

/// Tile size in world units (= pixels of the pixel art).
const double kTile = 24;

/// One theme per world (tileset + parallax background + sky).
enum LevelTheme {
  feed('Il Feed'),
  comments('Sezione Commenti'),
  beach('Spiaggia dei Reel'),
  desert('Deserto dei Like'),
  ice('Ghiacciaio Cringe'),
  candy('Città dei Trend'),
  forest('Foresta dei Meme'),
  volcano('Vulcano dei Flame'),
  clouds('Nuvole Virali'),
  server('Il Server');

  const LevelTheme(this.worldName);
  final String worldName;
}

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
///   `?` like block `G` boss gate (opens when the boss dies) `S` spring
///   `!` power-up block
///   `o` like       `K` checkpoint `F` finish flag        `P` player start
///   `M` moving platform (moves left/right around its spawn)
///   `n` normie     `c` cringe     `h` hater   `b` boomer  `A` L'Algoritmo
class LevelData {
  LevelData({
    required this.index,
    required this.theme,
    required this.parTime,
    required this.map,
    this.bossHp = 5,
    this.walls = true,
  }) {
    final lines = map.split('\n');
    if (lines.isNotEmpty && lines.first.isEmpty) lines.removeAt(0);
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
    cols = lines.fold(0, (m, l) => l.length > m ? l.length : m);
    rows = lines.length;
    for (var r = 0; r < rows; r++) {
      final line = lines[r].padRight(cols);
      final row = <String>[];
      for (var c = 0; c < cols; c++) {
        final ch = line[c];
        if (_tiles.contains(ch)) {
          row.add(ch);
        } else {
          row.add(' ');
          if (ch != ' ' && ch != '.') spawns.add(Spawn(ch, c, r));
        }
      }
      _grid.add(row);
    }
  }

  static const _tiles = '#B=^?GS!';

  /// 0-based position in the campaign.
  final int index;
  final LevelTheme theme;
  final String map;
  final int bossHp;

  /// Whether the left/right edges of the map act as walls (arenas: no, you
  /// can fly off the sides).
  final bool walls;

  /// Seconds under which the player earns a time bonus.
  final int parTime;

  late final int cols;
  late final int rows;
  final List<List<String>> _grid = [];
  final List<Spawn> spawns = [];

  String get id => 'L${(index + 1).toString().padLeft(3, '0')}';
  int get world => index ~/ 50 + 1;
  int get number => index % 50 + 1;
  String get name => '$world-$number';
  String get subtitle => theme.worldName;
  bool get hasBoss => spawns.any((s) => s.code == 'A');

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
    if (c < 0 || c >= cols) return walls;
    return const {'#', 'B', '?', 'U', 'G', 'S', '!'}.contains(tileAt(c, r));
  }

  bool isOneWay(int c, int r) => tileAt(c, r) == '=';

  bool isStandable(int c, int r) => isSolid(c, r) || isOneWay(c, r);

  /// Fresh copy, so a restarted level gets its blocks and gates back.
  LevelData copy() => LevelData(
    index: index,
    theme: theme,
    parTime: parTime,
    map: map,
    bossHp: bossHp,
    walls: walls,
  );
}
