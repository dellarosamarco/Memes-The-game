import 'dart:math';

import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../services/local_store.dart';
import '../services/name_filter.dart';
import '../services/sound.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import 'arcade_screen.dart';
import 'character_select_screen.dart';
import 'fight_setup_screen.dart';
import 'shop_screen.dart';
import 'trophies_screen.dart';
import '../l10n/l10n.dart';
import '../services/daily.dart';
import '../services/missions.dart';
import '../widgets/daily_reward.dart';
import 'missions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<MemeCharacter> _crowd = (List.of(
    MemeCharacter.all,
  )..shuffle()).take(9).toList();

  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Sound.music('menu');
    // Once a day: the login reward.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Missions.refresh();
      if (!mounted) return;
      await showDailyReward(context);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: LocalStore.instance.playerName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: PixelPanel(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelText(
                tr('home.yourName', 'Il tuo nome'),
                size: 22,
                color: Color(0xFFFF82B4),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLength: 16,
                autofocus: true,
                style: TextStyle(
                  fontFamily: kPixelFont,
                  fontFamilyFallback: fontFallback,
                  fontSize: 20,
                  color: kPlum,
                ),
                decoration: const InputDecoration(hintText: 'xX_MemeLord_Xx'),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PixelButton(
                    label: tr('common.cancel', 'Annulla'),
                    color: PixelColor.grey,
                    height: 46,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(width: 10),
                  PixelButton(
                    label: tr('common.save', 'Salva'),
                    color: PixelColor.mint,
                    height: 46,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(ctx, ctrl.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    if (!NameFilter.isClean(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'home.nameRejected',
              'Questo nome non è consentito, scegline un altro.',
            ),
          ),
        ),
      );
      return;
    }
    await LocalStore.instance.setPlayerName(trimmed);
    setState(() {});
  }

  /// Character select, then [next] (fight setup or Arcade ladder).
  void _pick(
    String title,
    Widget Function(MemeCharacter) next, {
    MemeCharacter? initial,
  }) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CharacterSelectScreen(
              title: title,
              initial: initial,
              onChosen: (ctx, c) =>
                  Navigator.of(ctx)
                      .push(MaterialPageRoute(builder: (_) => next(c))),
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    return Scaffold(
      body: PixelBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              // A different bunch of memes hangs out on the grass every time.
              Positioned(
                left: 64,
                right: 140,
                bottom: 60,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _crowd.length; i++)
                        _Hopper(
                          anim: _bob,
                          phase: i * 0.25,
                          child: CharacterSpriteView(
                            character: _crowd[i],
                            scale: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.62),
                child: AnimatedBuilder(
                  animation: _bob,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, -4 * _bob.value),
                    child: child,
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BouncyText('MEMES', size: 64, color: Color(0xFFFF82B4)),
                      PixelText(
                        'The fight',
                        size: 26,
                        color: Color(0xFFFFE07A),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.02),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    PixelButton(
                      label: tr('menu.freeFight', 'Lotta libera'),
                      icon: 'play',
                      width: 220,
                      onPressed: () => _pick(
                        tr(
                          'menu.freeFightPick',
                          'Lotta libera: scegli il tuo meme',
                        ),
                        (c) => FightSetupScreen(player: c),
                      ),
                    ),
                    PixelButton(
                      label: tr('menu.arcade', 'Arcade'),
                      icon: 'trophy',
                      width: 220,
                      color: PixelColor.purple,
                      onPressed: () => _pick(
                        tr('menu.arcadePick', 'Arcade: scegli il tuo meme'),
                        (c) => ArcadeScreen(player: c),
                      ),
                    ),
                  ],
                ),
              ),
              // Meme of the day banner, on the grass.
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: _DailyMeme(
                    MemeCharacter.ofTheDay(),
                    onTap: () => _pick(
                      tr(
                        'menu.freeFightPick',
                        'Lotta libera: scegli il tuo meme',
                      ),
                      (c) => FightSetupScreen(player: c),
                      initial: MemeCharacter.ofTheDay(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 8,
                child: GestureDetector(
                  onTap: _editName,
                  child: PixelPanel(
                    px: 1.5,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PixelText(
                          store.playerName,
                          size: 14,
                          color: kPlum,
                          outline: false,
                        ),
                        const SizedBox(width: 8),
                        const PixelIcon('edit', scale: 1.5),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Badge(
                      count: Missions.claimable,
                      child: PixelButton(
                        label: tr('menu.missions', 'Missioni'),
                        icon: 'star',
                        color: PixelColor.pink,
                        width: 176,
                        height: 44,
                        fontSize: 14,
                        onPressed: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const MissionsScreen(),
                              ),
                            )
                            .then((_) => setState(() {})),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PixelButton(
                      label: tr('menu.shop', 'Negozio'),
                      icon: 'like',
                      color: PixelColor.yellow,
                      width: 176,
                      height: 44,
                      fontSize: 14,
                      onPressed: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => const ShopScreen(),
                            ),
                          )
                          .then((_) => setState(() {})),
                    ),
                    const SizedBox(height: 8),
                    PixelButton(
                      label: tr('menu.trophies', 'Trofei'),
                      icon: 'trophy',
                      color: PixelColor.mint,
                      width: 176,
                      height: 44,
                      fontSize: 14,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TrophiesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                bottom: 96,
                child: PixelButton(
                  icon: 'gear',
                  color: PixelColor.blue,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () => showSettings(context),
                ),
              ),
              // Days in a row: something to keep alive.
              if (DailyReward.streak() > 0)
                Positioned(
                  left: 14,
                  top: 58,
                  child: Row(
                    children: [
                      const PixelIcon('star', scale: 1.5),
                      const SizedBox(width: 5),
                      PixelText(
                        tr('home.streak', '{n} giorni di fila', {
                          'n': DailyReward.streak(),
                        }),
                        size: 13,
                        color: const Color(0xFFFFE07A),
                      ),
                    ],
                  ),
                ),
              Positioned(
                right: 12,
                top: 8,
                child: PixelPanel(
                  px: 1.5,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PixelIcon('like', scale: 1.5),
                      const SizedBox(width: 6),
                      PixelText(
                        '${store.wallet}',
                        size: 14,
                        color: kPlum,
                        outline: false,
                      ),
                      const SizedBox(width: 12),
                      const PixelIcon('trophy', scale: 1.5),
                      const SizedBox(width: 6),
                      PixelText(
                        tr('home.wins', '{n} vittorie', {
                          'n': store.stat('wins'),
                        }),
                        size: 14,
                        color: kPlum,
                        outline: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Makes its child do a little happy hop now and then.
class _Hopper extends StatelessWidget {
  const _Hopper({required this.anim, required this.phase, required this.child});

  final Animation<double> anim;
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final v = (anim.value + phase) % 1.0;
        final hop = v < .25 ? sin(v / .25 * pi) * 10 : 0.0;
        return Transform.translate(offset: Offset(0, -hop), child: child);
      },
      child: child,
    );
  }
}

class _DailyMeme extends StatelessWidget {
  const _DailyMeme(this.character, {required this.onTap});

  final MemeCharacter character;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: PixelPanel(
      px: 1.5,
      padding: const EdgeInsets.fromLTRB(10, 4, 14, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            character.portraitAsset,
            height: 26,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(width: 8),
          PixelText(
            tr('home.memeOfTheDay', 'Meme del giorno: {name}', {
              'name': character.name,
            }),
            size: 13,
            color: kPlum,
            outline: false,
          ),
          const SizedBox(width: 8),
          const PixelIcon('like', scale: 1.4),
          PixelText(
            tr('home.doubleLikes', ' x2 like'),
            size: 13,
            color: const Color(0xFFFF82B4),
            outline: false,
          ),
          const SizedBox(width: 6),
          const PixelIcon('play', scale: 1.4),
        ],
      ),
    ),
  );
}

/// A red count in the corner of a button (rewards waiting).
class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D5E),
              shape: BoxShape.circle,
              border: Border.all(color: kPlum, width: 2),
            ),
            child: PixelText('$count', size: 12),
          ),
        ),
      ],
    );
  }
}
