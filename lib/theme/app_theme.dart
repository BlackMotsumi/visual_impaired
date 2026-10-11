import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // CUT INSPIRED COLOUR PALETTE
  // ============================================================

  // Main CUT-inspired blue
  static const Color primaryBlue = Color(0xFF0047AB);

  //surface blue
  static const Color surfaceBlue = Color(0xFFEAF2FF);

  // Darker blue for contrast
  static const Color darkBlue = Color(0xFF003477);

  // Lighter blue for cards and secondary areas
  static const Color lightBlue = Color(0xFF1565C0);

  // CUT-inspired red
  static const Color primaryRed = Color(0xFFD71920);

  // CUT-inspired yellow
  static const Color primaryYellow = Color(0xFFFFC72C);

  // White
  static const Color white = Colors.white;

  // Main text
  static const Color black = Color(0xFF111111);

  // Secondary text
  static const Color grey = Color(0xFFE5E7EB);

  // Error
  static const Color error = Color(0xFFD71920);

  // Success
  static const Color success = Color(0xFF2E7D32);
}

class AppTheme {
  // ============================================================
  // MAIN APPLICATION THEME
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // ----------------------------------------------------------
      // GLOBAL COLOUR SCHEME
      // ----------------------------------------------------------
      colorScheme: const ColorScheme(
        brightness: Brightness.light,

        primary: AppColors.primaryBlue,
        onPrimary: AppColors.white,

        secondary: AppColors.primaryYellow,
        onSecondary: AppColors.black,

        error: AppColors.primaryRed,
        onError: AppColors.white,

        surface: AppColors.white,
        onSurface: AppColors.black,

        surfaceContainerHighest: Color(0xFFEAF2FF),
      ),

      // ----------------------------------------------------------
      // SCAFFOLD
      // ----------------------------------------------------------
      scaffoldBackgroundColor: AppColors.primaryBlue,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,

        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ----------------------------------------------------------
      // TEXT
      // ----------------------------------------------------------
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),

        displayMedium: TextStyle(
          color: AppColors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),

        headlineLarge: TextStyle(
          color: AppColors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),

        headlineMedium: TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),

        titleLarge: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        titleMedium: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),

        bodyLarge: TextStyle(
          color: AppColors.white,
          fontSize: 18,
        ),

        bodyMedium: TextStyle(
          color: AppColors.white,
          fontSize: 16,
        ),

        bodySmall: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),

      // ----------------------------------------------------------
      // BUTTONS
      // ----------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryBlue,

          minimumSize: const Size(
            double.infinity,
            56,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // OUTLINED BUTTONS
      // ----------------------------------------------------------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,

          minimumSize: const Size(
            double.infinity,
            56,
          ),

          side: const BorderSide(
            color: AppColors.white,
            width: 2,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // INPUT FIELDS
      // ----------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryYellow,
            width: 3,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryRed,
            width: 2,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryRed,
            width: 3,
          ),
        ),

        hintStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
        ),

        labelStyle: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 16,
        ),
      ),

      // ----------------------------------------------------------
      // CARDS
      // ----------------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 4,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),

      // ----------------------------------------------------------
      // ICONS
      // ----------------------------------------------------------
      iconTheme: const IconThemeData(
        color: AppColors.white,
        size: 28,
      ),

      // ----------------------------------------------------------
      // DIVIDERS
      // ----------------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: Colors.white24,
        thickness: 1,
      ),

      // ----------------------------------------------------------
      // SNACKBAR
      // ----------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkBlue,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ----------------------------------------------------------
      // FLOATING ACTION BUTTON
      // ----------------------------------------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.black,
      ),

      // ----------------------------------------------------------
      // PROGRESS INDICATOR
      // ----------------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryYellow,
      ),
    );
  }
}