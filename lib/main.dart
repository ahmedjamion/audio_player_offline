import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/audio_player_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/settings_controller.dart';
import 'models/song_model.dart';
import 'models/playlist_model.dart';
import 'router/app_router.dart';

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
            return audio;
          },
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return MaterialApp.router(
            title: 'Offline Audio Player',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settings.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5A9E85),
        onPrimary: Colors.white,
        secondary: Color(0xFFC4918A),
        onSecondary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1A1A1A),
        error: Color(0xFFB85450),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F2EB),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F2EB),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF5A9E85),
        unselectedItemColor: Color(0xFF9E9E9E),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF5A9E85),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A9E85),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5A9E85),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF5A9E85),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF5A9E85),
        inactiveTrackColor: const Color(0xFFD4D4D4),
        thumbColor: const Color(0xFF5A9E85),
        overlayColor: const Color(0xFF5A9E85).withValues(alpha: 0.2),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF5A9E85),
        unselectedLabelColor: Color(0xFF9E9E9E),
        indicatorColor: Color(0xFF5A9E85),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7CB9A8),
        onPrimary: Color(0xFF1A1A1A),
        secondary: Color(0xFFD4A5A5),
        onSecondary: Color(0xFF1A1A1A),
        surface: Color(0xFF2A2A2A),
        onSurface: Color(0xFFE8E8E8),
        error: Color(0xFFEF5350),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      cardTheme: CardThemeData(
        color: const Color(0xFF252525),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFFE8E8E8),
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF252525),
        selectedItemColor: Color(0xFF7CB9A8),
        unselectedItemColor: Color(0xFF6E6E6E),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF7CB9A8),
        foregroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7CB9A8),
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7CB9A8),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF7CB9A8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF7CB9A8),
        inactiveTrackColor: const Color(0xFF4A4A4A),
        thumbColor: const Color(0xFF7CB9A8),
        overlayColor: const Color(0xFF7CB9A8).withValues(alpha: 0.2),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF7CB9A8),
        unselectedLabelColor: Color(0xFF6E6E6E),
        indicatorColor: Color(0xFF7CB9A8),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return GoogleFonts.openSansTextTheme(baseTheme).copyWith(
      displayLarge: GoogleFonts.oswald(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.oswald(
        fontSize: 45,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.oswald(
        fontSize: 36,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.oswald(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: GoogleFonts.oswald(
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.openSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
