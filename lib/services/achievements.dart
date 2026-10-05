import '../models/meme_character.dart';

import 'package:flutter/foundation.dart';

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
    Trophy('first_win', 'Primo post', 'Completa il tuo primo livello.'),
    Trophy('three_stars', 'Perfezionista', 'Finisci un livello con 3 stelle.'),
    Trophy('no_damage', 'Intoccabile', 'Finisci un livello senza farti male.'),
    Trophy('speedrun', 'Speedrunner', 'Finisci un livello in meno di 30 s.'),
    Trophy('boss', 'Anti-algoritmo', "Sconfiggi L'Algoritmo."),
    Trophy('combo3', 'Triple kill', 'Schiaccia 3 nemici senza toccare terra.'),
    Trophy('combo6', 'MONSTER KILL', 'Schiaccia 6 nemici senza toccare terra.'),
    Trophy('stomp100', 'Calpestatore', 'Schiaccia 100 nemici in totale.'),
    Trophy('likes1000', 'Influencer', 'Raccogli 1000 like in totale.'),
    Trophy('deal', 'Deal with it', 'Indossa gli occhiali da sole.'),
    Trophy('stonks', 'Stonks', 'Prendi il power-up Stonks.'),
    Trophy('nap', 'Pisolino', 'Lascia dormire il tuo meme.'),
    Trophy('respects', 'F', 'Rendi omaggio 10 volte.'),
    Trophy('shopper', 'Fashion meme', 'Compra un cappellino.'),
    Trophy('all_memes', 'Collezionista', 'Gioca con tutti i meme.'),
    Trophy('world5', 'A metà strada', 'Sblocca il mondo 5.'),
    Trophy('world10', 'Il Server', 'Sblocca il mondo 10.'),
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
    if (s.stat('stomps') >= 100) unlock('stomp100');
    if (s.stat('likes') >= 1000) unlock('likes1000');
    if (s.stat('respects') >= 10) unlock('respects');
    if (s.playedWith.length >= MemeCharacter.all.length) {
      unlock('all_memes');
    }
    if (s.unlockedLevels > 200) unlock('world5');
    if (s.unlockedLevels > 450) unlock('world10');
  }
}
