import 'dart:ui';

import 'level.dart';

/// Colors of each world (kept in sync with tool/pixel_world.py).
class ThemeColors {
  const ThemeColors(this.skyTop, this.skyBottom, this.accent, this.ground);
  final Color skyTop;
  final Color skyBottom;
  final Color accent;
  final Color ground;

  static ThemeColors of(LevelTheme t) => _all[t]!;

  static const _all = {
    LevelTheme.feed: ThemeColors(
      Color(0xFF8CD2FF),
      Color(0xFFD6F2FF),
      Color(0xFF7ED66E),
      Color(0xFFC48C62),
    ),
    LevelTheme.comments: ThemeColors(
      Color(0xFF5A4696),
      Color(0xFFC8A0E6),
      Color(0xFFC896F0),
      Color(0xFF8264AA),
    ),
    LevelTheme.beach: ThemeColors(
      Color(0xFF6EC8FA),
      Color(0xFFC8F5FF),
      Color(0xFFFCE4A0),
      Color(0xFFF0C882),
    ),
    LevelTheme.desert: ThemeColors(
      Color(0xFFFFBE8C),
      Color(0xFFFFECBE),
      Color(0xFFFAC878),
      Color(0xFFE2A060),
    ),
    LevelTheme.ice: ThemeColors(
      Color(0xFFAAD2FA),
      Color(0xFFEBF8FF),
      Color(0xFFF0FAFF),
      Color(0xFFA0D2F0),
    ),
    LevelTheme.candy: ThemeColors(
      Color(0xFFFFC8E6),
      Color(0xFFFFF0FA),
      Color(0xFFFFB4DC),
      Color(0xFFBE8264),
    ),
    LevelTheme.forest: ThemeColors(
      Color(0xFF64AA96),
      Color(0xFFBEE6C8),
      Color(0xFF5AB46E),
      Color(0xFF826050),
    ),
    LevelTheme.volcano: ThemeColors(
      Color(0xFF5A2846),
      Color(0xFFDC6E64),
      Color(0xFFFF8C5A),
      Color(0xFF6E4650),
    ),
    LevelTheme.clouds: ThemeColors(
      Color(0xFF96B4FF),
      Color(0xFFFFE6FA),
      Color(0xFFFFFFFF),
      Color(0xFFDCE6FF),
    ),
    LevelTheme.server: ThemeColors(
      Color(0xFF141832),
      Color(0xFF3C3C78),
      Color(0xFF6EFABE),
      Color(0xFF3C466E),
    ),
  };
}
