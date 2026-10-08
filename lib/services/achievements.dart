import 'package:flutter/foundation.dart';

import '../models/meme_character.dart';

import 'local_store.dart';
import 'sound.dart';

class Trophy {
  const Trophy(this.id, this.name, this.description);
  final String id;
  final String name;
  final String description;
}

/// Unlockable trophies. Unlocking one shows a toast anywhere in the app.
class Achievements {
  Achievements._();

  static const all = [
    Trophy('first_win', 'Primo sangue', 'Vinci il tuo primo incontro.'),
    Trophy('perfect', 'Intoccabile', 'Vinci senza perdere nemmeno una vita.'),
    Trophy('survivor', 'Duro a morire', 'Vinci con il 150% di danni o più.'),
    Trophy('smash_ko', 'SMASH!', "Manda KO l'avversario con uno smash."),
    Trophy('hard_win', 'Pro player', 'Vinci un incontro a Difficile.'),
    Trophy('wins10', 'Campione del feed', 'Vinci 10 incontri.'),
    Trophy('wins50', 'Leggenda di internet', 'Vinci 50 incontri.'),
    Trophy('kos100', 'Ratio', 'Manda KO 100 avversari in totale.'),
    Trophy('specials100', 'Spammone', 'Usa 100 mosse speciali.'),
    Trophy('damage5000', 'Danni collaterali', 'Infliggi 5000% di danni in totale.'),
    Trophy('arcade', 'Re dell\'Arcade', 'Completa la modalità Arcade.'),
    Trophy('arcade_hard', "Boss finale", 'Completa l\'Arcade a Difficile.'),
    Trophy('shopper', 'Fashion meme', 'Compra un cappellino.'),
    Trophy('respects', 'F', 'Rendi omaggio 10 volte.'),
    Trophy('all_memes', 'Collezionista', 'Gioca con tutti i meme.'),
    Trophy('all_wins', 'Tuttofare', 'Vinci almeno una volta con ogni meme.'),
  ];

  /// Trophies waiting to be shown as toasts.
  static final toasts = ValueNotifier<List<Trophy>>([]);

  static void unlock(String id) {
    if (!LocalStore.ready) return;
    final store = LocalStore.instance;
    if (store.trophies.contains(id)) return;
    final t = all.firstWhere((t) => t.id == id);
    store.addTrophy(id);
    Sound.play('checkpoint');
    toasts.value = [...toasts.value, t];
  }

  static void dismiss(Trophy t) {
    toasts.value = [...toasts.value]..remove(t);
  }

  /// Checks the cumulative stats.
  static void checkStats() {
    if (!LocalStore.ready) return;
    final s = LocalStore.instance;
    if (s.stat('wins') >= 1) unlock('first_win');
    if (s.stat('wins') >= 10) unlock('wins10');
    if (s.stat('wins') >= 50) unlock('wins50');
    if (s.stat('hard_wins') >= 1) unlock('hard_win');
    if (s.stat('kos') >= 100) unlock('kos100');
    if (s.stat('specials') >= 100) unlock('specials100');
    if (s.stat('damage') >= 5000) unlock('damage5000');
    if (s.stat('respects') >= 10) unlock('respects');
    if (s.arcadeTitles >= 1) unlock('arcade');
    if (s.playedWith.length >= MemeCharacter.all.length) {
      unlock('all_memes');
    }
    if (s.wonWith.length >= MemeCharacter.all.length) unlock('all_wins');
  }
}
