import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'tables.dart';

/// The game's languages. Italian is the source: every text is written in
/// the code as `tr('key', 'Testo italiano')`, and the other languages come
/// from the tables in lib/l10n/tr_*.dart (missing keys fall back to
/// English, then to the Italian source).
class L10n {
  L10n._();

  /// Language code -> its own name (for the language picker).
  static const languages = {
    'it': 'Italiano',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ru': 'Русский',
    'uk': 'Українська',
    'pl': 'Polski',
    'nl': 'Nederlands',
    'tr': 'Türkçe',
    'id': 'Bahasa Indonesia',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
  };

  /// The language in use; listen to rebuild the app when it changes.
  static final current = ValueNotifier<String>('it');

  static String get code => current.value;

  /// The first of the device's languages the game speaks, else English.
  static String deviceLanguage() {
    for (final l in ui.PlatformDispatcher.instance.locales) {
      if (languages.containsKey(l.languageCode)) return l.languageCode;
    }
    return 'en';
  }

  /// [saved] is the player's own choice (null: follow the device).
  static void use(String? saved) {
    current.value = languages.containsKey(saved) ? saved! : deviceLanguage();
  }
}

/// The text for [key] in the current language. [it] is the Italian source;
/// `{name}` placeholders are filled from [args].
String tr(String key, String it, [Map<String, Object?> args = const {}]) {
  final code = L10n.code;
  var s = code == 'it'
      ? it
      : (translations[code]?[key] ?? translations['en']?[key] ?? it);
  if (args.isNotEmpty) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  }
  return s;
}

/// Fonts for the scripts the pixel font doesn't have (bundled subsets, see
/// tool/subset_cjk_fonts.py), in the best order for the current language:
/// Japanese gets the pixel font first, Chinese and Korean their own.
List<String> get fontFallback => switch (L10n.code) {
  'zh' => const ['NotoSansSC', 'NotoSansKR', 'DotGothic16'],
  'ko' => const ['NotoSansKR', 'DotGothic16', 'NotoSansSC'],
  _ => const ['DotGothic16', 'NotoSansSC', 'NotoSansKR'],
};
