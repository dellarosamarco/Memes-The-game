import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_fight/screens/trophies_screen.dart';
import 'package:memes_the_fight/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screens fit a phone held sideways (no overflow stripes).
void main() {
  testWidgets('trophies with progress bars fit', (tester) async {
    SharedPreferences.setMockInitialValues({'stat_wins': 3, 'stat_kos': 12});
    await LocalStore.init();
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpWidget(const MaterialApp(home: TrophiesScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('3/10'), findsOneWidget);
  });
}
