import 'package:flutter/material.dart';

/// Service d'accessibilité pour garantir la conformité WCAG 2.1 niveau AA
class AccessibilityService {
  /// Vérifie si le contraste entre deux couleurs est suffisant (WCAG AA: 4.5:1 pour texte normal, 3:1 pour texte large)
  static bool hasEnoughContrast(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final requiredRatio = isLargeText ? 3.0 : 4.5;
    return ratio >= requiredRatio;
  }

  /// Calcule le ratio de contraste entre deux couleurs selon WCAG
  static double calculateContrastRatio(Color color1, Color color2) {
    final l1 = _calculateRelativeLuminance(color1);
    final l2 = _calculateRelativeLuminance(color2);

    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calcule la luminance relative d'une couleur
  static double _calculateRelativeLuminance(Color color) {
    final r = _gammaCorrect(color.red / 255.0);
    final g = _gammaCorrect(color.green / 255.0);
    final b = _gammaCorrect(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Correction gamma pour le calcul de luminance
  static double _gammaCorrect(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ((value + 0.055) / 1.055).pow(2.4);
    }
  }

  /// Trouve une couleur de texte accessible (noir ou blanc) pour un fond donné
  static Color getAccessibleTextColor(Color backgroundColor) {
    final blackContrast = calculateContrastRatio(Colors.black, backgroundColor);
    final whiteContrast = calculateContrastRatio(Colors.white, backgroundColor);

    return blackContrast > whiteContrast ? Colors.black : Colors.white;
  }

  /// Assombrit ou éclaircit une couleur pour atteindre un contraste suffisant
  static Color adjustColorForContrast(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    if (hasEnoughContrast(foreground, background, isLargeText: isLargeText)) {
      return foreground;
    }

    // Essayer d'assombrir
    Color adjusted = foreground;
    for (var i = 0; i < 10; i++) {
      adjusted = Color.lerp(adjusted, Colors.black, 0.1)!;
      if (hasEnoughContrast(adjusted, background, isLargeText: isLargeText)) {
        return adjusted;
      }
    }

    // Si assombrir ne fonctionne pas, essayer d'éclaircir
    adjusted = foreground;
    for (var i = 0; i < 10; i++) {
      adjusted = Color.lerp(adjusted, Colors.white, 0.1)!;
      if (hasEnoughContrast(adjusted, background, isLargeText: isLargeText)) {
        return adjusted;
      }
    }

    // En dernier recours, retourner noir ou blanc selon le fond
    return getAccessibleTextColor(background);
  }
}

extension ColorAccessibility on Color {
  /// Vérifie si cette couleur a un contraste suffisant avec une autre
  bool hasEnoughContrastWith(Color other, {bool isLargeText = false}) {
    return AccessibilityService.hasEnoughContrast(
      this,
      other,
      isLargeText: isLargeText,
    );
  }

  /// Calcule le ratio de contraste avec une autre couleur
  double contrastRatioWith(Color other) {
    return AccessibilityService.calculateContrastRatio(this, other);
  }

  /// Ajuste cette couleur pour avoir un contraste suffisant avec une autre
  Color adjustedForContrastWith(Color other, {bool isLargeText = false}) {
    return AccessibilityService.adjustColorForContrast(
      this,
      other,
      isLargeText: isLargeText,
    );
  }
}

extension on double {
  double pow(double exponent) {
    if (exponent == 0.0) return 1.0;
    if (exponent == 1.0) return this;

    double result = 1.0;
    double base = this;
    int exp = exponent.toInt();

    if (exponent != exp) {
      // Pour les exposants non entiers, utiliser une approximation
      return _powApprox(exponent);
    }

    bool negative = exp < 0;
    if (negative) exp = -exp;

    while (exp > 0) {
      if (exp % 2 == 1) {
        result *= base;
      }
      base *= base;
      exp ~/= 2;
    }

    return negative ? 1.0 / result : result;
  }

  double _powApprox(double exponent) {
    // Approximation de pow pour les exposants non entiers
    if (this <= 0) return 0.0;
    final ln = _ln();
    final result = _exp(exponent * ln);
    return result;
  }

  double _ln() {
    // Approximation du logarithme naturel
    if (this <= 0) return double.negativeInfinity;
    double x = this - 1.0;
    double result = 0.0;
    double term = x;
    for (int n = 1; n <= 20; n++) {
      result += term / n;
      term *= -x;
    }
    return result;
  }

  double _exp(double x) {
    // Approximation de l'exponentielle
    double result = 1.0;
    double term = 1.0;
    for (int n = 1; n <= 20; n++) {
      term *= x / n;
      result += term;
    }
    return result;
  }
}

/// Widget accessible avec Semantics configuré automatiquement
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isLink;
  final bool isHeader;
  final bool isImage;
  final bool isTextField;
  final bool excludeSemantics;
  final VoidCallback? onTap;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isLink = false,
    this.isHeader = false,
    this.isImage = false,
    this.isTextField = false,
    this.excludeSemantics = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      link: isLink,
      header: isHeader,
      image: isImage,
      textField: isTextField,
      onTap: onTap,
      enabled: onTap != null,
      child: child,
    );
  }
}

/// Wrapper pour les boutons accessibles
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String label;
  final String? hint;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: child,
    );
  }
}

/// Wrapper pour les champs de texte accessibles
class AccessibleTextField extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final String? value;
  final String? errorText;

  const AccessibleTextField({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      textField: true,
      child: errorText != null
          ? Semantics(
              liveRegion: true,
              child: child,
            )
          : child,
    );
  }
}

/// Wrapper pour les images accessibles
class AccessibleImage extends StatelessWidget {
  final Widget child;
  final String altText;
  final bool isDecorative;

  const AccessibleImage({
    super.key,
    required this.child,
    required this.altText,
    this.isDecorative = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDecorative) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: altText,
      image: true,
      child: child,
    );
  }
}

/// Wrapper pour les en-têtes accessibles
class AccessibleHeader extends StatelessWidget {
  final Widget child;
  final String text;
  final int level; // 1 = h1, 2 = h2, etc.

  const AccessibleHeader({
    super.key,
    required this.child,
    required this.text,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      header: true,
      child: child,
    );
  }
}

/// Wrapper pour les liens accessibles
class AccessibleLink extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  const AccessibleLink({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      link: true,
      onTap: onTap,
      child: child,
    );
  }
}

/// Utilitaires pour les annonces de lecteur d'écran
class ScreenReaderAnnouncer {
  /// Annonce un message au lecteur d'écran
  static void announce(BuildContext context, String message) {
    // Utilise un Semantics avec liveRegion pour annoncer le message
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        return Semantics(
          liveRegion: true,
          label: message,
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}
