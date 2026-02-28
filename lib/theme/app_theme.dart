import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shadowColor: AppColors.lightPrimary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.lightPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.unselectedItemLight,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lightPrimary,
        inactiveTrackColor: AppColors.inactiveTrackLight,
        thumbColor: AppColors.lightPrimary,
        overlayColor: AppColors.lightSecondary.withValues(alpha: 0.3),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.lightPrimary,
        unselectedLabelColor: AppColors.unselectedItemLight,
        indicatorColor: AppColors.lightPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 4,
        shadowColor: AppColors.glowCyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.unselectedItemDark,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkSecondary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkSecondary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.darkSecondary,
        inactiveTrackColor: AppColors.inactiveTrackDark,
        thumbColor: AppColors.darkSecondary,
        overlayColor: AppColors.darkSecondary.withValues(alpha: 0.3),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.darkSecondary,
        unselectedLabelColor: AppColors.unselectedItemDark,
        indicatorColor: AppColors.darkSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return GoogleFonts.poppinsTextTheme(baseTheme).copyWith(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.orbitron(
        fontSize: 45,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.orbitron(
        fontSize: 36,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
