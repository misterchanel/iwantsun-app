import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/accessibility_service.dart';

/// Vérification et ajustement des couleurs pour l'accessibilité WCAG AA
class AccessibilityColors {
  /// Vérifie tous les contrastes de couleurs de l'application
  static Map<String, ContrastCheck> verifyAllContrasts() {
    return {
      // Texte sur fond blanc
      'primaryOrange/white': ContrastCheck(
        foreground: AppColors.primaryOrange,
        background: AppColors.white,
        name: 'Primary Orange sur Blanc',
        context: 'Texte normal',
      ),
      'darkGray/white': ContrastCheck(
        foreground: AppColors.darkGray,
        background: AppColors.white,
        name: 'Gris Foncé sur Blanc',
        context: 'Texte principal',
      ),
      'mediumGray/white': ContrastCheck(
        foreground: AppColors.mediumGray,
        background: AppColors.white,
        name: 'Gris Moyen sur Blanc',
        context: 'Texte secondaire',
      ),

      // Texte sur fond coloré
      'white/primaryOrange': ContrastCheck(
        foreground: AppColors.white,
        background: AppColors.primaryOrange,
        name: 'Blanc sur Primary Orange',
        context: 'Boutons principaux',
      ),
      'white/sunsetOrange': ContrastCheck(
        foreground: AppColors.white,
        background: AppColors.sunsetOrange,
        name: 'Blanc sur Sunset Orange',
        context: 'Boutons secondaires',
      ),

      // Texte sur fond gris
      'textDark/lightGray': ContrastCheck(
        foreground: AppColors.textDark,
        background: AppColors.lightGray,
        name: 'Texte Foncé sur Gris Clair',
        context: 'Cards et containers',
      ),
      'darkGray/cream': ContrastCheck(
        foreground: AppColors.darkGray,
        background: AppColors.cream,
        name: 'Gris Foncé sur Crème',
        context: 'Sections',
      ),

      // Couleurs d'état
      'successGreen/white': ContrastCheck(
        foreground: AppColors.successGreen,
        background: AppColors.white,
        name: 'Vert Succès sur Blanc',
        context: 'Messages de succès',
      ),
      'errorRed/white': ContrastCheck(
        foreground: AppColors.errorRed,
        background: AppColors.white,
        name: 'Rouge Erreur sur Blanc',
        context: 'Messages d\'erreur',
      ),
      'warningYellow/white': ContrastCheck(
        foreground: AppColors.warningYellow,
        background: AppColors.white,
        name: 'Jaune Avertissement sur Blanc',
        context: 'Messages d\'avertissement',
      ),
    };
  }

  /// Génère un rapport de conformité accessible
  static String generateAccessibilityReport() {
    final checks = verifyAllContrasts();
    final buffer = StringBuffer();

    buffer.writeln('=== RAPPORT DE CONFORMITÉ ACCESSIBILITÉ WCAG 2.1 AA ===\n');
    buffer.writeln('Date: ${DateTime.now()}\n');

    int passCount = 0;
    int failCount = 0;

    for (final entry in checks.entries) {
      final check = entry.value;
      final ratio = AccessibilityService.calculateContrastRatio(
        check.foreground,
        check.background,
      );
      final passes = AccessibilityService.hasEnoughContrast(
        check.foreground,
        check.background,
        isLargeText: false,
      );

      if (passes) {
        passCount++;
      } else {
        failCount++;
      }

      buffer.writeln('${check.name}:');
      buffer.writeln('  Contexte: ${check.context}');
      buffer.writeln('  Ratio de contraste: ${ratio.toStringAsFixed(2)}:1');
      buffer.writeln('  Statut: ${passes ? "✅ CONFORME" : "❌ NON CONFORME"}');
      buffer.writeln('  Requis: 4.5:1 (texte normal) ou 3:1 (texte large)');

      if (!passes) {
        final adjusted = AccessibilityService.adjustColorForContrast(
          check.foreground,
          check.background,
        );
        buffer.writeln('  Suggestion: Utiliser la couleur ajustée');
        buffer.writeln('  Couleur ajustée: ${adjusted.toString()}');
      }
      buffer.writeln('');
    }

    buffer.writeln('=== RÉSUMÉ ===');
    buffer.writeln('Conformes: $passCount');
    buffer.writeln('Non conformes: $failCount');
    buffer.writeln('Total: ${passCount + failCount}');
    buffer.writeln(
      'Taux de conformité: ${(passCount / (passCount + failCount) * 100).toStringAsFixed(1)}%',
    );

    return buffer.toString();
  }

  /// Couleurs ajustées pour l'accessibilité si nécessaire
  static final adjustedPrimaryOrange = AccessibilityService.adjustColorForContrast(
    AppColors.primaryOrange,
    AppColors.white,
  );

  static final adjustedMediumGray = AccessibilityService.adjustColorForContrast(
    AppColors.mediumGray,
    AppColors.white,
  );

  /// Guide d'utilisation des couleurs accessibles
  static const String usageGuide = '''
GUIDE D'UTILISATION DES COULEURS ACCESSIBLES

1. TEXTE SUR FOND BLANC
   - Utiliser: darkGray, textDark (ratio > 12:1) ✅
   - Utiliser avec prudence: primaryOrange (ratio > 3:1)
   - Éviter: mediumGray, lightGray (ratio insuffisant)

2. TEXTE SUR FOND COLORÉ
   - Boutons: Toujours utiliser white sur primaryOrange ✅
   - Cards colorées: Vérifier le contraste avec AccessibilityService
   - Gradient: Assurer un contraste minimum sur toute la zone

3. TEXTE DE GRANDE TAILLE (18pt+ ou 14pt+ gras)
   - Ratio minimum: 3:1
   - Plus de flexibilité dans le choix des couleurs

4. ÉLÉMENTS D'INTERFACE (icônes, bordures)
   - Ratio minimum: 3:1 avec l'arrière-plan
   - Utiliser primaryOrange pour les éléments importants

5. ÉTATS INTERACTIFS
   - Focus: Bordure visible de 2px minimum avec ratio 3:1
   - Hover: Changement de couleur avec contraste maintenu
   - Active: État visuellement distinct

6. MESSAGES D'ÉTAT
   - Succès: successGreen ✅ (ratio suffisant)
   - Erreur: errorRed ✅ (ratio suffisant)
   - Avertissement: warningYellow ⚠️ (vérifier selon le fond)

BONNES PRATIQUES:
- Toujours tester avec AccessibilityService.hasEnoughContrast()
- Utiliser adjustColorForContrast() pour ajuster automatiquement
- Ne jamais utiliser UNIQUEMENT la couleur pour transmettre l'information
- Ajouter des icônes et du texte explicite
''';
}

/// Classe pour représenter une vérification de contraste
class ContrastCheck {
  final Color foreground;
  final Color background;
  final String name;
  final String context;

  ContrastCheck({
    required this.foreground,
    required this.background,
    required this.name,
    required this.context,
  });
}

/// Extension pour faciliter la vérification des contrastes dans les widgets
extension AccessibilityColorValidation on BuildContext {
  /// Vérifie si un contraste est suffisant et log un warning si non
  bool validateContrast(
    Color foreground,
    Color background, {
    String? widgetName,
    bool isLargeText = false,
  }) {
    final hasContrast = AccessibilityService.hasEnoughContrast(
      foreground,
      background,
      isLargeText: isLargeText,
    );

    if (!hasContrast) {
      final ratio = AccessibilityService.calculateContrastRatio(
        foreground,
        background,
      );
      debugPrint(
        '⚠️ ACCESSIBILITÉ: Contraste insuffisant ${widgetName != null ? 'dans $widgetName' : ''}'
        '\n   Ratio: ${ratio.toStringAsFixed(2)}:1 '
        '(requis: ${isLargeText ? "3:1" : "4.5:1"})',
      );
    }

    return hasContrast;
  }
}
