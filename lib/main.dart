import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/local_store.dart';
import 'services/sound.dart';
import 'widgets/pixel_ui.dart';
import 'widgets/trophy_toasts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fights are played in landscape.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await PixelAssets.preload();
  await LocalStore.init();
  await Sound.init();
  runApp(const MemesApp());
}

class MemesApp extends StatefulWidget {
  const MemesApp({super.key});

  @override
  State<MemesApp> createState() => _MemesAppState();
}

class _MemesAppState extends State<MemesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No music from a phone in the pocket.
    if (state == AppLifecycleState.resumed) {
      Sound.resumeMusic();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      Sound.pauseMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memes: the game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pixelify',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4FA3),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF14121F),
      ),
      home: const HomeScreen(),
      // Text a bit larger than the platform default: the game is played
      // on phones held at arm's length, in landscape.
      builder: (context, child) => _UiScale(
        child: Stack(
          children: [child ?? const SizedBox(), const TrophyToasts()],
        ),
      ),
    );
  }
}

/// The whole UI is designed for a phone in landscape (~400 logical px tall).
/// On bigger screens (tablets, desktop browsers) it is laid out at that
/// size and scaled up, so menus and the game keep their proportions instead
/// of shrinking into a sea of empty space. Text is also a bit larger than
/// the platform default: the game is played at arm's length.
class _UiScale extends StatelessWidget {
  const _UiScale({required this.child});

  final Widget child;

  static const _designHeight = 410.0;
  static const _designWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = min(
      mq.size.shortestSide / _designHeight,
      mq.size.longestSide / _designWidth,
    ).clamp(1.0, 3.0);
    final text = mq.textScaler.clamp(minScaleFactor: 1.12, maxScaleFactor: 1.3);
    if (scale == 1.0) {
      return MediaQuery(
        data: mq.copyWith(textScaler: text),
        child: child,
      );
    }
    final size = mq.size / scale;
    return MediaQuery(
      data: mq.copyWith(
        size: size,
        textScaler: text,
        padding: mq.padding / scale,
        viewPadding: mq.viewPadding / scale,
        viewInsets: mq.viewInsets / scale,
        devicePixelRatio: mq.devicePixelRatio * scale,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    );
  }
}
