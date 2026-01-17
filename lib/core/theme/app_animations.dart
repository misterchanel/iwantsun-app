import 'package:flutter/material.dart';

/// Constantes et helpers pour les animations de l'application
class AppAnimations {
  AppAnimations._();

  // === DURATIONS ===

  /// Durée ultra rapide pour les micro-interactions (100ms)
  static const Duration ultraFast = Duration(milliseconds: 100);

  /// Durée très rapide pour les petites animations (200ms)
  static const Duration veryFast = Duration(milliseconds: 200);

  /// Durée rapide pour les animations standards (300ms)
  static const Duration fast = Duration(milliseconds: 300);

  /// Durée normale pour les animations (400ms)
  static const Duration normal = Duration(milliseconds: 400);

  /// Durée lente pour les animations importantes (600ms)
  static const Duration slow = Duration(milliseconds: 600);

  /// Durée très lente pour les animations complexes (800ms)
  static const Duration verySlow = Duration(milliseconds: 800);

  // === CURVES ===

  /// Curve standard Material Design
  static const Curve standardCurve = Curves.easeInOut;

  /// Curve pour les entrées d'éléments
  static const Curve enterCurve = Curves.easeOut;

  /// Curve pour les sorties d'éléments
  static const Curve exitCurve = Curves.easeIn;

  /// Curve pour les rebonds
  static const Curve bounceCurve = Curves.elasticOut;

  /// Curve pour les accélérations
  static const Curve accelerateCurve = Curves.easeInCubic;

  /// Curve pour les décélérations
  static const Curve decelerateCurve = Curves.easeOutCubic;

  // === ANIMATIONS PRÉDÉFINIES ===

  /// Animation de scale pour les boutons (tap effect)
  static Animation<double> buttonScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: standardCurve,
    ));
  }

  /// Animation de fade in
  static Animation<double> fadeInAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: enterCurve,
    ));
  }

  /// Animation de fade out
  static Animation<double> fadeOutAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: exitCurve,
    ));
  }

  /// Animation de slide from bottom
  static Animation<Offset> slideFromBottomAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: enterCurve,
    ));
  }

  /// Animation de slide from top
  static Animation<Offset> slideFromTopAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: enterCurve,
    ));
  }

  /// Animation de slide from left
  static Animation<Offset> slideFromLeftAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: enterCurve,
    ));
  }

  /// Animation de slide from right
  static Animation<Offset> slideFromRightAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: enterCurve,
    ));
  }

  /// Animation de scale up
  static Animation<double> scaleUpAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: bounceCurve,
    ));
  }

  /// Animation de rotation
  static Animation<double> rotationAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: standardCurve,
    ));
  }

  // === PAGE TRANSITIONS ===

  /// Transition de slide pour les routes
  static RouteTransitionsBuilder slideTransition({
    SlideDirection direction = SlideDirection.left,
  }) {
    return (context, animation, secondaryAnimation, child) {
      Offset begin;
      switch (direction) {
        case SlideDirection.left:
          begin = const Offset(1.0, 0.0);
          break;
        case SlideDirection.right:
          begin = const Offset(-1.0, 0.0);
          break;
        case SlideDirection.up:
          begin = const Offset(0.0, 1.0);
          break;
        case SlideDirection.down:
          begin = const Offset(0.0, -1.0);
          break;
      }

      return SlideTransition(
        position: Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        )),
        child: child,
      );
    };
  }

  /// Transition de fade pour les routes
  static RouteTransitionsBuilder fadeTransition() {
    return (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    };
  }

  /// Transition de scale pour les routes
  static RouteTransitionsBuilder scaleTransition() {
    return (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        )),
        child: child,
      );
    };
  }

  // === STAGGERED ANIMATIONS ===

  /// Crée une animation décalée pour les listes
  static Animation<double> staggeredAnimation(
    AnimationController controller,
    int index, {
    int itemCount = 5,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    final start = (index / itemCount) * 0.5;
    final end = start + 0.5;

    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        end,
        curve: enterCurve,
      ),
    ));
  }
}

/// Direction pour les slide transitions
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Helper pour créer des AnimationControllers avec durée prédéfinie
extension AnimationControllerExtension on TickerProvider {
  AnimationController ultraFastController() {
    return AnimationController(
      duration: AppAnimations.ultraFast,
      vsync: this,
    );
  }

  AnimationController veryFastController() {
    return AnimationController(
      duration: AppAnimations.veryFast,
      vsync: this,
    );
  }

  AnimationController fastController() {
    return AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
  }

  AnimationController normalController() {
    return AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
  }

  AnimationController slowController() {
    return AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
  }

  AnimationController verySlowController() {
    return AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
  }
}
