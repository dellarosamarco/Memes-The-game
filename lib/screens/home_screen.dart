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
              const PixelText(
                'Il tuo nome',
                size: 22,
                color: Color(0xFFFF82B4),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLength: 16,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: kPixelFont,
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
                    label: 'Annulla',
                    color: PixelColor.grey,
                    height: 46,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(width: 10),
                  PixelButton(
                    label: 'Salva',
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
        const SnackBar(
          content: Text('Questo nome non è consentito, scegline un altro.'),
        ),
      );
      return;
    }
    await LocalStore.instance.setPlayerName(trimmed);
    setState(() {});
  }

  /// Character select, then [next] (fight setup or Arcade ladder).
  void _pick(String title, Widget Function(MemeCharacter) next) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CharacterSelectScreen(
              title: title,
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
                      PixelText('The fight', size: 26, color: Color(0xFFFFE07A)),
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
                      label: 'Lotta libera',
                      icon: 'play',
                      width: 220,
                      onPressed: () => _pick(
                        'Lotta libera: scegli il tuo meme',
                        (c) => FightSetupScreen(player: c),
                      ),
                    ),
                    PixelButton(
                      label: 'Arcade',
                      icon: 'trophy',
                      width: 220,
                      color: PixelColor.purple,
                      onPressed: () => _pick(
                        'Arcade: scegli il tuo meme',
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
                child: Center(child: _DailyMeme(MemeCharacter.ofTheDay())),
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
                    PixelButton(
                      label: 'Negozio',
                      icon: 'like',
                      color: PixelColor.yellow,
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
                      label: 'Trofei',
                      icon: 'trophy',
                      color: PixelColor.mint,
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
                        '${store.stat('wins')} vittorie',
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
  const _DailyMeme(this.character);

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) => PixelPanel(
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
          'Meme del giorno: ${character.name}',
          size: 13,
          color: kPlum,
          outline: false,
        ),
        const SizedBox(width: 8),
        const PixelIcon('like', scale: 1.4),
        const PixelText(
          ' x2',
          size: 13,
          color: Color(0xFFFF82B4),
          outline: false,
        ),
      ],
    ),
  );
}
