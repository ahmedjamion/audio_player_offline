import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';

import 'controllers/audio_player_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/settings_controller.dart';
import 'models/song_model.dart';
import 'models/playlist_model.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize just_audio_media_kit for Windows/Linux audio support
  JustAudioMediaKit.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());

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
        ChangeNotifierProvider(create: (_) => AudioPlayerController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return MaterialApp.router(
            title: 'Offline Music',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            routerConfig: appRouter,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              SystemChrome.setSystemUIOverlayStyle(
                brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
              );
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
