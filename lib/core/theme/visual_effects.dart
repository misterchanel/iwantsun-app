import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// Effets visuels professionnels pour l'application

class VisualEffects {
  VisualEffects._();

  // === SHADOWS ===

  /// Ombre douce pour les cartes
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Ombre moyenne pour les éléments élevés
  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Ombre forte pour les dialogues et modales
  static List<BoxShadow> get strongShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.20),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];

  /// Ombre colorée basée sur la couleur primaire
  static List<BoxShadow> coloredShadow(Color color, {double opacity = 0.3}) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Ombre intérieure (effet enfoncé)
  static List<BoxShadow> get innerShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.7),
          blurRadius: 8,
          offset: const Offset(-2, -2),
        ),
      ];

  // === GRADIENTS ===

  /// Gradient orange soleil (primaire)
  static LinearGradient get sunsetGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryOrange,
          Color(0xFFFF6B35),
        ],
      );

  /// Gradient bleu ciel
  static LinearGradient get skyGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4A90E2),
          AppColors.primaryBlue,
        ],
      );

  /// Gradient succès (vert)
  static LinearGradient get successGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4CAF50),
          Color(0xFF2E7D32),
        ],
      );

  /// Gradient erreur (rouge)
  static LinearGradient get errorGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF44336),
          Color(0xFFC62828),
        ],
      );

  /// Gradient neutre (gris)
  static LinearGradient get neutralGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.mediumGray,
          AppColors.darkGray,
        ],
      );

  /// Gradient overlay pour images (dark)
  static LinearGradient get darkOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.7),
        ],
      );

  /// Gradient overlay pour images (light)
  static LinearGradient get lightOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
      );

  /// Gradient shimmer pour loading
  static LinearGradient shimmerGradient(double animationValue) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.lightGray,
          AppColors.lightGray.withOpacity(0.5),
          AppColors.lightGray,
        ],
        stops: [
          (animationValue - 0.3).clamp(0.0, 1.0),
          animationValue.clamp(0.0, 1.0),
          (animationValue + 0.3).clamp(0.0, 1.0),
        ],
      );

  /// Gradient température froide (bleu)
  static LinearGradient get coldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00BCD4),
          Color(0xFF0097A7),
        ],
      );

  /// Gradient température chaude (orange/rouge)
  static LinearGradient get hotGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF9800),
          Color(0xFFFF5722),
        ],
      );

  /// Gradient température parfaite (vert/jaune)
  static LinearGradient get perfectGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8BC34A),
          Color(0xFFFFEB3B),
        ],
      );

  // === BORDER RADIUS ===

  /// Coins arrondis petits
  static BorderRadius get smallRadius => BorderRadius.circular(8);

  /// Coins arrondis moyens
  static BorderRadius get mediumRadius => BorderRadius.circular(12);

  /// Coins arrondis grands
  static BorderRadius get largeRadius => BorderRadius.circular(16);

  /// Coins arrondis extra larges
  static BorderRadius get xlRadius => BorderRadius.circular(24);

  /// Coins arrondis circulaires
  static BorderRadius get circularRadius => BorderRadius.circular(999);

  /// Coins arrondis haut seulement
  static BorderRadius get topRadius => const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      );

  /// Coins arrondis bas seulement
  static BorderRadius get bottomRadius => const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );

  // === BLUR EFFECTS ===

  /// Effet de flou léger
  static double get lightBlur => 5.0;

  /// Effet de flou moyen
  static double get mediumBlur => 10.0;

  /// Effet de flou fort
  static double get strongBlur => 20.0;

  // === DECORATIONS PRÉDÉFINIES ===

  /// Décoration de carte standard
  static BoxDecoration cardDecoration({
    Color? color,
    List<BoxShadow>? boxShadow,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? mediumRadius,
      boxShadow: boxShadow ?? softShadow,
      border: border,
    );
  }

  /// Décoration de carte avec gradient
  static BoxDecoration gradientCardDecoration({
    required Gradient gradient,
    List<BoxShadow>? boxShadow,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius ?? mediumRadius,
      boxShadow: boxShadow ?? softShadow,
      border: border,
    );
  }

  /// Décoration glassmorphism
  static BoxDecoration glassDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.2),
      borderRadius: borderRadius ?? mediumRadius,
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Décoration badge
  static BoxDecoration badgeDecoration({
    required Color color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: coloredShadow(color),
    );
  }

  /// Décoration input field
  static BoxDecoration inputDecoration({
    Color? fillColor,
    Color? borderColor,
    bool hasFocus = false,
  }) {
    return BoxDecoration(
      color: fillColor ?? AppColors.lightGray.withOpacity(0.3),
      borderRadius: mediumRadius,
      border: Border.all(
        color: hasFocus
            ? (borderColor ?? AppColors.primaryOrange)
            : AppColors.lightGray,
        width: hasFocus ? 2 : 1,
      ),
      boxShadow: hasFocus
          ? coloredShadow(
              borderColor ?? AppColors.primaryOrange,
              opacity: 0.2,
            )
          : null,
    );
  }

  // === TEXT STYLES AVEC EFFECTS ===

  /// Style de texte avec ombre
  static TextStyle textWithShadow({
    required TextStyle baseStyle,
    Color shadowColor = Colors.black,
    double shadowOpacity = 0.3,
  }) {
    return baseStyle.copyWith(
      shadows: [
        Shadow(
          color: shadowColor.withOpacity(shadowOpacity),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  /// Style de texte avec glow
  static TextStyle textWithGlow({
    required TextStyle baseStyle,
    required Color glowColor,
  }) {
    return baseStyle.copyWith(
      shadows: [
        Shadow(
          color: glowColor.withOpacity(0.5),
          blurRadius: 8,
        ),
        Shadow(
          color: glowColor.withOpacity(0.3),
          blurRadius: 16,
        ),
      ],
    );
  }

  // === WEATHER VISUAL HELPERS ===

  /// Obtenir le gradient basé sur la température
  static LinearGradient temperatureGradient(double temperature) {
    if (temperature < 10) {
      return coldGradient;
    } else if (temperature > 30) {
      return hotGradient;
    } else {
      return perfectGradient;
    }
  }

  /// Obtenir la couleur basée sur la température
  static Color temperatureColor(double temperature) {
    if (temperature < 10) {
      return const Color(0xFF00BCD4); // Cyan
    } else if (temperature < 15) {
      return const Color(0xFF4CAF50); // Vert
    } else if (temperature < 25) {
      return const Color(0xFFFFEB3B); // Jaune
    } else if (temperature < 30) {
      return const Color(0xFFFF9800); // Orange
    } else {
      return const Color(0xFFFF5722); // Rouge
    }
  }

  /// Obtenir le gradient pour le score de correspondance
  static LinearGradient scoreGradient(double scorePercentage) {
    if (scorePercentage >= 80) {
      return successGradient;
    } else if (scorePercentage >= 60) {
      return perfectGradient;
    } else if (scorePercentage >= 40) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryOrange,
          Colors.orange.shade700,
        ],
      );
    } else {
      return errorGradient;
    }
  }

  /// Obtenir la couleur pour le score de correspondance
  static Color scoreColor(double scorePercentage) {
    if (scorePercentage >= 80) {
      return const Color(0xFF4CAF50); // Vert
    } else if (scorePercentage >= 60) {
      return const Color(0xFF8BC34A); // Vert clair
    } else if (scorePercentage >= 40) {
      return AppColors.primaryOrange;
    } else {
      return const Color(0xFFF44336); // Rouge
    }
  }

  // === ANIMATED DECORATIONS ===

  /// Décoration qui pulse (pour appliquer avec AnimatedContainer)
  static BoxDecoration pulsingDecoration({
    required Color color,
    required double animationValue,
    BorderRadius? borderRadius,
  }) {
    final pulseValue = 0.5 + (animationValue * 0.5);
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? mediumRadius,
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4 * pulseValue),
          blurRadius: 20 * pulseValue,
          spreadRadius: 2 * pulseValue,
        ),
      ],
    );
  }

  /// Décoration avec bordure animée
  static BoxDecoration animatedBorderDecoration({
    required Color borderColor,
    required double animationValue,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: borderRadius ?? mediumRadius,
      border: Border.all(
        color: borderColor.withOpacity(animationValue),
        width: 2 + (animationValue * 2),
      ),
    );
  }
}

/// Extension pour faciliter l'application d'effets visuels
extension VisualEffectsExtension on Widget {
  /// Ajoute une ombre au widget
  Widget withShadow({List<BoxShadow>? shadow}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: shadow ?? VisualEffects.softShadow,
      ),
      child: this,
    );
  }

  /// Ajoute des coins arrondis au widget
  Widget withRadius({BorderRadius? radius}) {
    return ClipRRect(
      borderRadius: radius ?? VisualEffects.mediumRadius,
      child: this,
    );
  }

  /// Ajoute un gradient overlay au widget
  Widget withGradientOverlay({Gradient? gradient}) {
    return Stack(
      children: [
        this,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient ?? VisualEffects.darkOverlay,
            ),
          ),
        ),
      ],
    );
  }

  /// Ajoute un padding et une décoration
  Widget withDecoration({
    required BoxDecoration decoration,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: this,
    );
  }
}
