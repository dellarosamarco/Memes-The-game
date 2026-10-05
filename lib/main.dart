import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/firebase_service.dart';
import 'services/local_store.dart';
import 'services/sound.dart';
import 'widgets/pixel_ui.dart';
import 'widgets/trophy_toasts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A side-scrolling platformer is played in landscape.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await PixelAssets.preload();
  await LocalStore.init();
  await Sound.init();
  await FirebaseService.instance.init();
  runApp(const MemesApp());
}

class MemesApp extends StatelessWidget {
  const MemesApp({super.key});

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
      builder: (context, child) =>
          Stack(children: [child ?? const SizedBox(), const TrophyToasts()]),
    );
  }
}
