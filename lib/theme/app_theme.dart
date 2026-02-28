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
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
        overlayColor: AppColors.lightPrimary.withValues(alpha: 0.2),
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
        shadowColor: Colors.black.withValues(alpha: 0.3),
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
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.unselectedItemDark,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
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
          foregroundColor: AppColors.darkPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.darkPrimary,
        inactiveTrackColor: AppColors.inactiveTrackDark,
        thumbColor: AppColors.darkPrimary,
        overlayColor: AppColors.darkPrimary.withValues(alpha: 0.2),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.darkPrimary,
        unselectedLabelColor: AppColors.unselectedItemDark,
        indicatorColor: AppColors.darkPrimary,
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
