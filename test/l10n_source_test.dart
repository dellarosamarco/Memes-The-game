import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_fight/game/components/fight_items.dart';
import 'package:memes_the_fight/game/level.dart';
import 'package:memes_the_fight/game/memes_game.dart';
import 'package:memes_the_fight/game/stages.dart';
import 'package:memes_the_fight/l10n/l10n.dart';
import 'package:memes_the_fight/l10n/tables.dart';
import 'package:memes_the_fight/models/hats.dart';
import 'package:memes_the_fight/models/meme_character.dart';
import 'package:memes_the_fight/services/achievements.dart';

/// The Italian source of the game data (memes, hats, trophies, arenas...),
/// for tool/extract_strings.py; and checks the translation tables.
void main() {
  Map<String, String> dataTexts() => {
    for (final c in MemeCharacter.all) ...c.sourceTexts,
    ...Hat.sourceTexts,
    for (final t in Achievements.all) ...t.sourceTexts,
    ...Stage.sourceTexts,
    for (final w in LevelTheme.values) 'world.${w.name}': w.worldName,
    for (final d in Difficulty.values) 'difficulty.${d.name}': d.label,
    for (final k in ItemKind.values)
      if (k.label.isNotEmpty) 'item.${k.name}': k.label,
  };

  test('writes the data texts', () {
    L10n.current.value = 'it';
    Directory('build').createSync(recursive: true);
    File('build/l10n_data.json').writeAsStringSync(jsonEncode(dataTexts()));
  });

  test('every language has a table', () {
    expect(
      translations.keys.toSet(),
      L10n.languages.keys.where((c) => c != 'it').toSet(),
    );
  });

  test('every table has the source keys and keeps the placeholders', () {
    final source = (jsonDecode(
      File('lib/l10n/source_it.json').readAsStringSync(),
    ) as Map).cast<String, String>();
    final holes = RegExp(r'\{\w+\}');
    for (final MapEntry(key: code, value: table) in translations.entries) {
      // English is the fallback of every other language: it must be
      // complete. The others may lag behind for new texts (they show the
      // English until translated).
      final missing = source.keys.where((k) => !table.containsKey(k));
      if (code == 'en') {
        expect(missing, isEmpty, reason: '$code is missing $missing');
      }
      for (final MapEntry(:key, :value) in source.entries) {
        final want = holes.allMatches(value).map((m) => m[0]).toSet();
        if (!table.containsKey(key)) continue;
        final got = holes.allMatches(table[key]!).map((m) => m[0]).toSet();
        expect(got, want, reason: '$code $key placeholders');
      }
    }
  });
}
