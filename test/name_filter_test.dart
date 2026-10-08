import 'package:flutter_test/flutter_test.dart';
import 'package:memes_the_fight/services/name_filter.dart';

void main() {
  test('clean names pass', () {
    for (final n in [
      'Anon1234',
      'xX_MemeLord_Xx',
      'Marco',
      'Pietro',
      'Sassy',
    ]) {
      expect(NameFilter.isClean(n), isTrue, reason: n);
    }
  });

  test('swear words are caught, also in leetspeak', () {
    for (final n in [
      'cazzone',
      'C4ZZ0',
      'vaffanculo',
      'FuCk',
      'sh1t',
      'stronzo99',
    ]) {
      expect(NameFilter.isClean(n), isFalse, reason: n);
      expect(NameFilter.display(n), 'Anonimo');
    }
  });
}
