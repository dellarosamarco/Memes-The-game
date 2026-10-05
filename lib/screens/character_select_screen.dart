import 'package:flutter/material.dart';

import '../models/meme_character.dart';
import '../services/local_store.dart';
import '../widgets/meme_text.dart';
import 'game_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  final _pages = PageController(viewportFraction: 0.86);
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _play(MemeCharacter c) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameScreen(character: c)));
  }

  @override
  Widget build(BuildContext context) {
    const chars = MemeCharacter.all;
    final current = chars[_index];
    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const MemeText('Scegli il tuo meme', fontSize: 22),
        centerTitle: true,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              current.color.withValues(alpha: 0.45),
              const Color(0xFF14121F),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: chars.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _CharacterCard(character: chars[i]),
                ),
              ),
              const SizedBox(height: 8),
              MemeButton(
                label: 'Gioca con ${current.name.split(' ').first}',
                icon: Icons.play_arrow,
                color: current.color == const Color(0xFF3A3A3A)
                    ? const Color(0xFFFF4FA3)
                    : current.color,
                onPressed: () => _play(current),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < chars.length; i++)
                      GestureDetector(
                        onTap: () => _pages.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _index
                                ? chars[i].color
                                : Colors.white24,
                          ),
                          child: CircleAvatar(
                            radius: i == _index ? 24 : 18,
                            backgroundImage: AssetImage(
                              'assets/images/${chars[i].spritePath}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character});

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) {
    final c = character;
    final best = LocalStore.instance.bestScore(c.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        color: const Color(0xFF221D33),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.color, width: 4),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: Image.asset(
                      c.portraitAsset,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 8,
                    child: MemeText(c.tagline, fontSize: 18),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: MemeText(c.name, fontSize: 34),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.memeAlias,
                      style: TextStyle(
                        color: c.color == const Color(0xFF3A3A3A)
                            ? Colors.white70
                            : c.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(c.lore, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    _Stat('Vita', c.maxHp / 140, c.maxHp.round().toString()),
                    _Stat(
                      'Velocità',
                      c.speed / 215,
                      c.speed.round().toString(),
                    ),
                    _Stat(
                      'Danno/s',
                      (c.damage / c.attackCooldown) / 37,
                      (c.damage / c.attackCooldown).toStringAsFixed(1),
                    ),
                    const SizedBox(height: 12),
                    _Ability(
                      icon: '⚔️',
                      title: c.attackName,
                      text: c.attackDescription,
                    ),
                    _Ability(
                      icon: '🔥',
                      title: '${c.specialName} (${c.specialCooldown.round()}s)',
                      text: c.specialDescription,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record personale: $best',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.text);

  final String label;
  final double value;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 10,
                backgroundColor: Colors.white12,
                color: const Color(0xFFFFD54F),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ability extends StatelessWidget {
  const _Ability({required this.icon, required this.title, required this.text});

  final String icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(text, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
