import 'package:flutter/material.dart';

import '../game/level.dart';
import '../game/level_gen.dart';
import '../game/theme_colors.dart';
import '../models/meme_character.dart';
import '../services/local_store.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import 'game_screen.dart';

/// The 10 worlds, swipeable; tap one to see its 50 levels.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, required this.character});

  final MemeCharacter character;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  late final PageController _pages;
  late int _world;

  @override
  void initState() {
    super.initState();
    final unlocked = LocalStore.instance.unlockedLevels.clamp(1, kLevelCount);
    _world = (unlocked - 1) ~/ kLevelsPerWorld;
    _pages = PageController(viewportFraction: 0.5, initialPage: _world);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelTheme.values[_world];
    final colors = ThemeColors.of(theme);
    return Scaffold(
      body: PixelBackdrop(
        top: colors.skyTop,
        bottom: colors.skyBottom,
        theme: theme.name,
        ground: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    PixelButton(
                      icon: 'left',
                      color: PixelColor.grey,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(child: PixelText('Mondi', size: 26)),
                    CharacterSpriteView(character: widget.character, scale: .8),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: LevelTheme.values.length,
                    onPageChanged: (i) => setState(() => _world = i),
                    itemBuilder: (_, i) => _WorldCard(
                      world: i,
                      selected: i == _world,
                      onTap: () => _open(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(int world) async {
    if (!_worldUnlocked(world)) return;
    if (world != _world) {
      _pages.animateToPage(
        world,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LevelGridScreen(character: widget.character, world: world),
      ),
    );
    setState(() {});
  }
}

bool _worldUnlocked(int world) =>
    LocalStore.instance.unlockedLevels > world * kLevelsPerWorld;

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.selected,
    required this.onTap,
  });

  final int world;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = LevelTheme.values[world];
    final colors = ThemeColors.of(theme);
    final store = LocalStore.instance;
    final unlocked = _worldUnlocked(world);
    var stars = 0;
    for (var i = 0; i < kLevelsPerWorld; i++) {
      stars += store.stars(_levelId(world * kLevelsPerWorld + i));
    }
    return AnimatedScale(
      scale: selected ? 1 : 0.86,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Opacity(
            opacity: unlocked ? 1 : 0.6,
            child: PixelPanel(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                children: [
                  PixelText(
                    'Mondo ${world + 1}',
                    size: 16,
                    color: kPlum,
                    outline: false,
                  ),
                  PixelText(
                    theme.worldName,
                    size: 20,
                    color: colors.accent == const Color(0xFFFFFFFF)
                        ? const Color(0xFFFF82B4)
                        : colors.accent,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [colors.skyTop, colors.skyBottom],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/sprites/bg_${theme.name}_far.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.none,
                          ),
                          if (!unlocked)
                            const Center(child: PixelIcon('lock', scale: 4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const PixelIcon('star', scale: 1.6),
                      const SizedBox(width: 6),
                      PixelText(
                        '$stars / ${kLevelsPerWorld * 3}',
                        size: 15,
                        color: kPlum,
                        outline: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _levelId(int index) => 'L${(index + 1).toString().padLeft(3, '0')}';

/// The 50 levels of a world.
class LevelGridScreen extends StatefulWidget {
  const LevelGridScreen({
    super.key,
    required this.character,
    required this.world,
  });

  final MemeCharacter character;
  final int world;

  @override
  State<LevelGridScreen> createState() => _LevelGridScreenState();
}

class _LevelGridScreenState extends State<LevelGridScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = LevelTheme.values[widget.world];
    final colors = ThemeColors.of(theme);
    final store = LocalStore.instance;
    return Scaffold(
      body: PixelBackdrop(
        top: colors.skyTop,
        bottom: colors.skyBottom,
        theme: theme.name,
        ground: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    PixelButton(
                      icon: 'left',
                      color: PixelColor.grey,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: PixelText(
                        'Mondo ${widget.world + 1} · ${theme.worldName}',
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 84,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: .95,
                        ),
                    itemCount: kLevelsPerWorld,
                    itemBuilder: (_, i) {
                      final index = widget.world * kLevelsPerWorld + i;
                      final locked = index >= store.unlockedLevels;
                      final boss = i == kLevelsPerWorld - 1;
                      return _LevelButton(
                        number: i + 1,
                        stars: store.stars(_levelId(index)),
                        locked: locked,
                        boss: boss,
                        onTap: locked ? null : () => _play(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _play(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(character: widget.character, levelIndex: index),
      ),
    );
    setState(() {});
  }
}

class _LevelButton extends StatefulWidget {
  const _LevelButton({
    required this.number,
    required this.stars,
    required this.locked,
    required this.boss,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool locked;
  final bool boss;
  final VoidCallback? onTap;

  @override
  State<_LevelButton> createState() => _LevelButtonState();
}

class _LevelButtonState extends State<_LevelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.locked
        ? 'grey'
        : widget.boss
        ? 'purple'
        : widget.stars == 3
        ? 'yellow'
        : widget.stars > 0
        ? 'mint'
        : 'pink';
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _down = false);
              widget.onTap!();
            },
      child: Container(
        padding: EdgeInsets.only(top: _down ? 8 : 4, bottom: _down ? 4 : 8),
        decoration: pixelFrame(
          'assets/images/ui/button_$color${_down ? '_down' : ''}.png',
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.locked)
              const PixelIcon('lock', scale: 2)
            else if (widget.boss)
              const PixelIcon('skull', scale: 2)
            else
              PixelText('${widget.number}', size: 22),
            const SizedBox(height: 4),
            if (!widget.locked) PixelStars(widget.stars, scale: 1),
          ],
        ),
      ),
    );
  }
}
