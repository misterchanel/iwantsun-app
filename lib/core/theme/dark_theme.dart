import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// Couleurs pour le thème sombre
class DarkColors {
  DarkColors._();

  // Couleurs de fond
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF2C2C2C);
  static const Color surfaceCard = Color(0xFF252525);

  // Couleurs primaires (ajustées pour le dark mode)
  static const Color primaryOrange = Color(0xFFFF9F5A);
  static const Color primaryBlue = Color(0xFF64B5F6);
  static const Color accentYellow = Color(0xFFFFD54F);

  // Texte
  static const Color textPrimary = Color(0xFFE1E1E1);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF757575);

  // Statuts
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  // Dividers et bordures
  static const Color divider = Color(0xFF3A3A3A);
  static const Color border = Color(0xFF404040);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9F5A), Color(0xFFFF7043)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
  );
}

/// ThemeData pour le mode sombre
class DarkTheme {
  DarkTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Couleurs de base
        colorScheme: const ColorScheme.dark(
          primary: DarkColors.primaryOrange,
          secondary: DarkColors.primaryBlue,
          surface: DarkColors.surface,
          error: DarkColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: DarkColors.textPrimary,
          onError: Colors.white,
        ),

        // Scaffold
        scaffoldBackgroundColor: DarkColors.background,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: DarkColors.surface,
          foregroundColor: DarkColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DarkColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: DarkColors.textPrimary),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: DarkColors.surfaceCard,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Elevated Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DarkColors.primaryOrange,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: DarkColors.primaryOrange.withOpacity( 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DarkColors.primaryOrange,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Outlined Buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DarkColors.textPrimary,
            side: const BorderSide(color: DarkColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DarkColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DarkColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DarkColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DarkColors.primaryOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DarkColors.error),
          ),
          labelStyle: const TextStyle(color: DarkColors.textSecondary),
          hintStyle: const TextStyle(color: DarkColors.textTertiary),
        ),

        // Chips
        chipTheme: ChipThemeData(
          backgroundColor: DarkColors.surfaceElevated,
          selectedColor: DarkColors.primaryOrange.withOpacity( 0.2),
          labelStyle: const TextStyle(color: DarkColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: DarkColors.border),
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: DarkColors.surface,
          selectedItemColor: DarkColors.primaryOrange,
          unselectedItemColor: DarkColors.textTertiary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),

        // TabBar
        tabBarTheme: const TabBarThemeData(
          labelColor: DarkColors.primaryOrange,
          unselectedLabelColor: DarkColors.textTertiary,
          indicatorColor: DarkColors.primaryOrange,
        ),

        // Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: DarkColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DarkColors.textPrimary,
          ),
          contentTextStyle: const TextStyle(
            fontSize: 16,
            color: DarkColors.textSecondary,
          ),
        ),

        // Bottom Sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: DarkColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: DarkColors.surfaceElevated,
          contentTextStyle: const TextStyle(color: DarkColors.textPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: DarkColors.divider,
          thickness: 1,
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: DarkColors.textSecondary,
        ),

        // Text
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: DarkColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: DarkColors.textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DarkColors.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DarkColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: DarkColors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: DarkColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: DarkColors.textSecondary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: DarkColors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: DarkColors.textTertiary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DarkColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: DarkColors.textTertiary,
          ),
        ),

        // Slider
        sliderTheme: SliderThemeData(
          activeTrackColor: DarkColors.primaryOrange,
          inactiveTrackColor: DarkColors.surfaceElevated,
          thumbColor: DarkColors.primaryOrange,
          overlayColor: DarkColors.primaryOrange.withOpacity( 0.2),
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DarkColors.primaryOrange;
            }
            return DarkColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DarkColors.primaryOrange.withOpacity( 0.5);
            }
            return DarkColors.surfaceElevated;
          }),
        ),

        // Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DarkColors.primaryOrange;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: DarkColors.border),
        ),

        // Radio
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DarkColors.primaryOrange;
            }
            return DarkColors.textTertiary;
          }),
        ),

        // Progress Indicators
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: DarkColors.primaryOrange,
          linearTrackColor: DarkColors.surfaceElevated,
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: DarkColors.primaryOrange,
          foregroundColor: Colors.white,
        ),

        // List Tile
        listTileTheme: const ListTileThemeData(
          textColor: DarkColors.textPrimary,
          iconColor: DarkColors.textSecondary,
        ),
      );
}
