import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'controllers/audio_player_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/settings_controller.dart';
import 'models/song_model.dart';
import 'models/playlist_model.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());

  // Open boxes if needed globally or let controllers handle it.
  // We let PlaylistController handle opening boxes for now.

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => PlaylistController()..init()),
        ChangeNotifierProxyProvider<SettingsController, AudioPlayerController>(
          create: (context) => AudioPlayerController(),
          update: (context, settings, audio) {
            if (audio == null) throw ArgumentError.notNull('audio');
            // Only scan if not loading and songs are empty or settings changed significantly?
            // For simplicity, we trigger scan if folders list changes.
            // But SettingsController notifies on folder change.
            // Hack: Trigger scan.
            // Note: Update is called on rebuild. We should only scan if folders changed logically.
            // Better to have explicit scan call from UI or SettingsController.
            // But requirement said "Automatic Scanning".
            // Let's just pass folders to audio controller and let it decide or exposer scan method
            // and call it in initState of HomeScreen.
            // For now, I won't auto-call scan here to avoid infinite loops or re-entrancy issues.
            return audio;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Offline Audio Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
