import 'dart:math';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/fighter/fighter.dart';
import '../models/meme_character.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprite_view.dart';
import '../l10n/l10n.dart';
import '../services/local_store.dart';
import '../services/sound.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({
    super.key,
    required this.onChosen,
    this.title,
    this.initial,
  });

  /// Shown first (otherwise the last meme picked).
  final MemeCharacter? initial;

  /// What happens once the player picks a meme (opens the next screen).
  final void Function(BuildContext context, MemeCharacter character) onChosen;
  final String? title;

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late int _index = _startIndex();
  late final _thumbs = ScrollController(
    initialScrollOffset: max(0, _index * _thumbStride - 200),
  );

  static const _thumbStride = 60.0;

  int _startIndex() {
    const all = MemeCharacter.all;
    final id =
        widget.initial?.id ??
        (LocalStore.ready ? LocalStore.instance.lastMeme : null);
    final i = all.indexWhere((c) => c.id == id);
    return i < 0 ? 0 : i;
  }

  void _choose(MemeCharacter c) {
    LocalStore.instance.setLastMeme(c.id);
    widget.onChosen(context, c);
  }

  @override
  void dispose() {
    _thumbs.dispose();
    super.dispose();
  }

  /// A random playable meme (never the one already shown).
  void _random() {
    final n = MemeCharacter.all.length;
    final options = [
      for (var i = 0; i < n; i++)
        if (i != _index && MemeCharacter.all[i].isUnlocked) i,
    ];
    if (options.isEmpty) return;
    _select(options[Random().nextInt(options.length)] - _index);
  }

  Future<void> _buy(MemeCharacter c) async {
    final store = LocalStore.instance;
    if (store.wallet >= c.price &&
        !await confirmDialog(
          context,
          title: tr('select.unlockAsk', 'Sbloccare {name}?', {'name': c.name}),
          text: tr('select.unlockCost', 'Costa {n} like (ne hai {have}).', {
            'n': c.price,
            'have': store.wallet,
          }),
          ok: tr('select.unlock', 'Sblocca {n}', {'n': c.price}),
          okColor: PixelColor.yellow,
        )) {
      return;
    }
    if (await store.buyMeme(c.id, c.price)) {
      Sound.play('finish');
      setState(() {});
      if (mounted) await _celebrate(c);
      return;
    }
    Sound.play('hurt', volume: .4);
    if (!mounted) return;
    showToast(
      context,
      tr(
        'select.needLikes',
        'Ti servono ancora {n} like: vinci incontri e completa le missioni!',
        {'n': c.price - LocalStore.instance.wallet},
      ),
    );
  }

  /// The new meme pops in, dancing.
  Future<void> _celebrate(MemeCharacter c) => showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: PixelPanel(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BouncyText(
                tr('select.unlocked', 'Sbloccato!'),
                size: 30,
                color: const Color(0xFFFFE07A),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .2, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: CharacterSpriteView(
                  character: c,
                  scale: 2.2,
                  running: true,
                ),
              ),
              PixelText(c.name, size: 20, color: const Color(0xFFFF82B4)),
              const SizedBox(height: 10),
              PixelButton(
                label: tr('select.pick', 'Scegli'),
                icon: 'play',
                color: PixelColor.pink,
                height: 46,
                fontSize: 15,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Next/previous meme, keeping its thumbnail in view.
  void _select(int delta) {
    final n = MemeCharacter.all.length;
    setState(() => _index = (_index + delta + n) % n);
    if (!_thumbs.hasClients) return;
    final pos = _thumbs.position;
    final target = (_index * _thumbStride - pos.viewportDimension / 2 + 30)
        .clamp(0.0, pos.maxScrollExtent);
    _thumbs.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const chars = MemeCharacter.all;
    final c = chars[_index];
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _select(-1);
          if (e.logicalKey == LogicalKeyboardKey.arrowRight) _select(1);
          return KeyEventResult.handled;
        },
        child: PixelBackdrop(
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
                      Expanded(
                        child: PixelText(
                          widget.title ??
                              tr('select.title', 'Scegli il tuo meme'),
                          size: 24,
                        ),
                      ),
                      WalletChip(likes: LocalStore.instance.wallet),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Arrow(
                                    icon: 'left',
                                    onTap: () => _select(-1),
                                  ),
                                  // Shrinks to fit: the arrows always
                                  // stay visible and tappable.
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: CharacterSpriteView(
                                        key: ValueKey(c.id),
                                        character: c,
                                        scale: 3.2,
                                        running: true,
                                      ),
                                    ),
                                  ),
                                  _Arrow(
                                    icon: 'right',
                                    onTap: () => _select(1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: PixelPanel(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                            child: _Info(character: c),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: PointerDeviceKind.values.toSet(),
                            ),
                            child: ListView.separated(
                              controller: _thumbs,
                              scrollDirection: Axis.horizontal,
                              itemCount: chars.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, i) => Center(
                                child: MemeThumb(
                                  character: chars[i],
                                  showLock: true,
                                  selected: i == _index,
                                  onTap: () => setState(() => _index = i),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PixelButton(
                        icon: 'dice',
                        color: PixelColor.mint,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: _random,
                      ),
                      const SizedBox(width: 8),
                      if (c.isUnlocked)
                        PixelButton(
                          label: tr('select.pick', 'Scegli'),
                          icon: 'play',
                          color: PixelColor.pink,
                          onPressed: () => _choose(c),
                        )
                      else
                        PixelButton(
                          label: tr('select.unlock', 'Sblocca {n}', {
                            'n': c.price,
                          }),
                          icon: 'like',
                          color: LocalStore.instance.wallet >= c.price
                              ? PixelColor.yellow
                              : PixelColor.grey,
                          fontSize: 16,
                          onPressed: () => _buy(c),
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

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PixelButton(
    icon: icon,
    color: PixelColor.grey,
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    onPressed: onTap,
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.character});

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) {
    final c = character;
    final body = TextStyle(
      fontFamily: kPixelFont,
      fontFamilyFallback: fontFallback,
      color: Color(0xFF6B5A78),
      fontSize: 13,
      height: 1.25,
    );
    // The bottom fades out: there is more to read below.
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0, .86, 1],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: _Scrolled(
        builder: (ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PixelText(
                          c.name,
                          size: 24,
                          color: const Color(0xFFFF82B4),
                          align: TextAlign.left,
                        ),
                        PixelText(
                          c.memeAlias,
                          size: 13,
                          color: kPlum,
                          outline: false,
                          align: TextAlign.left,
                        ),
                        const SizedBox(height: 6),
                        // The stats sit next to the photo, so the bigger
                        // photo doesn't push the abilities down.
                        Wrap(
                          spacing: 14,
                          runSpacing: 2,
                          children: [
                            _Stat(
                              tr('stat.speed', 'Velocità'),
                              Fighter.speedRating(c),
                            ),
                            _Stat(
                              tr('stat.jump', 'Salto'),
                              Fighter.jumpRating(c),
                            ),
                            _Stat(
                              tr('stat.weight', 'Peso'),
                              Fighter.weightRating(c),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Photo(character: c),
                ],
              ),
              const SizedBox(height: 8),
              if (c.isOfTheDay && !c.isOwned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: PixelText(
                    tr(
                      'select.freeTry',
                      'Prova gratis solo oggi, poi sbloccalo con i like!',
                    ),
                    size: 12,
                    color: const Color(0xFF2E9E6E),
                    outline: false,
                    align: TextAlign.left,
                  ),
                ),
              if (c.isOfTheDay)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: PixelText(
                    tr(
                      'select.memeOfTheDay',
                      'Meme del giorno: like doppi nel portafoglio!',
                    ),
                    size: 12,
                    color: Color(0xFFFF82B4),
                    outline: false,
                    align: TextAlign.left,
                  ),
                ),
              _Ability(title: c.passiveName, text: c.passiveDescription),
              _Ability(
                title: '${c.specialName} (${_secs(c.specialCooldown)})',
                text: c.specialDescription,
                special: true,
              ),
              // The lore last: what matters for picking comes first.
              const SizedBox(height: 8),
              Text(c.lore, style: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// A scroll view with a scrollbar that's always visible (there's more
/// below) and mouse-wheel friendly.
class _Scrolled extends StatefulWidget {
  const _Scrolled({required this.builder});

  final Widget Function(ScrollController) builder;

  @override
  State<_Scrolled> createState() => _ScrolledState();
}

class _ScrolledState extends State<_Scrolled> {
  final _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _ctrl,
    thumbVisibility: true,
    child: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
        scrollbars: false,
      ),
      child: widget.builder(_ctrl),
    ),
  );
}

/// 8 -> "8s", 4.5 -> "4,5s".
String _secs(double v) => tr('select.seconds', '{n}s', {
  'n': v == v.roundToDouble()
      ? v.round()
      : v.toString().replaceAll('.', tr('number.decimal', ',')),
});

/// The original meme photo: a tap shows it big.
class _Photo extends StatelessWidget {
  const _Photo({required this.character});

  final MemeCharacter character;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Center(
            child: PixelPanel(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  character.photoAsset,
                  height: MediaQuery.sizeOf(ctx).height * .78,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: kPlum,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            character.photoAsset,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _Ability extends StatelessWidget {
  const _Ability({
    required this.title,
    required this.text,
    this.special = false,
  });

  final String title;
  final String text;
  final bool special;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: PixelIcon(special ? 'bolt' : 'heart', scale: 1.5),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kPlum,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: TextStyle(
                fontFamily: kPixelFont,
                fontFamilyFallback: fontFallback,
                fontSize: 13,
                color: Color(0xFF6B5A78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small portrait tile, highlighted when [selected].
class MemeThumb extends StatelessWidget {
  const MemeThumb({
    super.key,
    required this.character,
    required this.selected,
    required this.onTap,
    this.size = 54,
    this.showLock = false,
  });

  /// Grey out memes not unlocked yet (character select only).
  final bool showLock;
  final MemeCharacter character;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? size + 10 : size,
        height: selected ? size + 10 : size,
        padding: const EdgeInsets.all(6),
        decoration: pixelFrame(
          selected
              ? 'assets/images/ui/button_yellow.png'
              : 'assets/images/ui/panel.png',
          px: 2,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                character.portraitAsset,
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
            if (showLock && !character.isUnlocked) ...[
              Positioned.fill(
                child: ColoredBox(color: const Color(0x993A2440)),
              ),
              const Center(child: PixelIcon('lock', scale: 2)),
            ],
            // Meme of the day: double likes.
            if (character.isOfTheDay)
              const Positioned(
                right: -8,
                top: -8,
                child: PixelIcon('star', scale: 1.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tiny 5-segment stat bar.
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;

  /// 0..1
  final double value;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * 4).round() + 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelText(label, size: 12, color: kPlum, outline: false),
        const SizedBox(width: 5),
        CustomPaint(size: const Size(55, 11), painter: _BarPainter(filled)),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.filled);

  final int filled;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 5;
    final w = size.width / n;
    final on = Paint()..color = const Color(0xFFFF82B4);
    final off = Paint()..color = const Color(0xFFE6DCE8);
    final edge = Paint()
      ..color = kPlum
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < n; i++) {
      final r = Rect.fromLTWH(i * w + 1, 1, w - 3, size.height - 2);
      canvas.drawRect(r, i < filled ? on : off);
      canvas.drawRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.filled != filled;
}
