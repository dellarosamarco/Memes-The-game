/// Keeps player names on the public leaderboard clean (store requirement for
/// user-generated content). Checks Italian and English swear words, also
/// written with numbers/symbols in place of letters.
class NameFilter {
  NameFilter._();

  static const _banned = [
    // Italian
    'cazz', 'minchi', 'stronz', 'vaffan', 'fancul', 'puttan', 'troia',
    'coglion', 'merda', 'figa', 'fica', 'mignott', 'zoccol', 'frocio',
    'ricchion', 'negro', 'porcodio', 'dioporco', 'diocan', 'porcamadonna',
    'bastard', 'pompin', 'sega', 'culatton', 'terron',
    // English
    'fuck', 'shit', 'bitch', 'cunt', 'dick', 'pussy', 'nigg', 'fag',
    'whore', 'slut', 'rape', 'nazi', 'hitler', 'retard', 'asshole', 'penis',
    'vagina', 'porn', 'sex',
  ];

  static const _leet = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '8': 'b',
    '@': 'a',
    r'$': 's',
    '!': 'i',
    '|': 'i',
    '€': 'e',
  };

  static String _normalize(String s) {
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final c = _leet[ch] ?? ch;
      if (RegExp('[a-zàèéìòù]').hasMatch(c)) b.write(c);
    }
    // Collapse repeated letters ("caaazzo" -> "cazo") and check both forms.
    return b.toString();
  }

  static String _squeeze(String s) =>
      s.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);

  /// True if [name] is fine to show to everyone.
  static bool isClean(String name) {
    final n = _normalize(name);
    final sq = _squeeze(n);
    for (final w in _banned) {
      if (n.contains(w) || sq.contains(_squeeze(w))) return false;
    }
    return true;
  }

  /// What the leaderboard shows for [name].
  static String display(String name) => isClean(name) ? name : 'Anonimo';
}
