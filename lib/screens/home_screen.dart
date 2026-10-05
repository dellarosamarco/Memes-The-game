import 'dart:math';

import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../services/firebase_service.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import 'character_select_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

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
    if (trimmed.isNotEmpty) {
      await LocalStore.instance.setPlayerName(trimmed);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    return Scaffold(
      body: PixelBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              // The four memes hanging out on the grass.
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < MemeCharacter.all.length; i++)
                      _Hopper(
                        anim: _bob,
                        phase: i * 0.25,
                        child: CharacterSpriteView(
                          character: MemeCharacter.all[i],
                          scale: 1.6,
                        ),
                      ),
                  ],
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
                      PixelText('the game', size: 26, color: Color(0xFFFFE07A)),
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
                      label: 'Gioca',
                      icon: 'play',
                      width: 220,
                      onPressed: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => const CharacterSelectScreen(),
                            ),
                          )
                          .then((_) => setState(() {})),
                    ),
                    PixelButton(
                      label: 'Classifica',
                      icon: 'trophy',
                      width: 220,
                      color: PixelColor.purple,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                    ),
                  ],
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
                top: 8,
                child: PixelPanel(
                  px: 1.5,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PixelIcon('star', scale: 1.5),
                      const SizedBox(width: 6),
                      PixelText(
                        '${store.totalStars} / 1500',
                        size: 14,
                        color: kPlum,
                        outline: false,
                      ),
                      const SizedBox(width: 10),
                      PixelText(
                        FirebaseService.instance.available
                            ? 'online'
                            : 'offline',
                        size: 12,
                        color: FirebaseService.instance.available
                            ? const Color(0xFF3FAF7A)
                            : const Color(0xFF9A8FB0),
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
