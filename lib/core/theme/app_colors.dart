import 'package:flutter/material.dart';

/// Couleurs de l'application - Thème coucher de soleil (tons chauds et doux)
class AppColors {
  // Couleurs principales - Coucher de soleil (tons doux et élégants)
  static const Color primaryOrange = Color(0xFFD97757); // Terracotta doux
  static const Color primaryCoral = Color(0xFFE8997A); // Corail doux
  static const Color sunsetOrange = Color(0xFFF5A984); // Pêche doux
  static const Color warmPeach = Color(0xFFFFC5A3); // Pêche très doux
  static const Color goldenYellow = Color(0xFFFFD4A5); // Jaune pêche doux
  static const Color softPink = Color(0xFFFFB5A7); // Rose pêche doux
  
  // Couleurs secondaires
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFFF9F3); // Crème très clair
  static const Color lightBeige = Color(0xFFFFF5EB); // Beige très clair
  static const Color lightGray = Color(0xFFF8F8F8);
  static const Color mediumGray = Color(0xFFBDBDBD);
  static const Color darkGray = Color(0xFF424242);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color black = Color(0xFF000000);
  
  // Couleurs d'accent
  static const Color successGreen = Color(0xFF66BB6A);
  static const Color errorRed = Color(0xFFEF5350);
  static const Color warningYellow = Color(0xFFFFA726);
  
  // Couleurs météo
  static const Color sunnyYellow = Color(0xFFFFC947);
  static const Color cloudyGray = Color(0xFF90A4AE);
  static const Color rainyBlue = Color(0xFF42A5F5);
  
  // Pour compatibilité avec l'ancien code
  static const Color primaryBlue = primaryOrange;
  static const Color orangeSun = sunsetOrange;
}
