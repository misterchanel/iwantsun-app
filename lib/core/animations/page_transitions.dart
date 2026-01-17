import 'package:flutter/material.dart';

/// Transitions de page personnalisées pour une navigation fluide

/// Transition de fondu (fade)
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Transition de slide (glissement)
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Offset beginOffset;

  SlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.beginOffset = const Offset(1.0, 0.0),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: beginOffset, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Transition de scale (zoom)
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Alignment alignment;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: 0.8, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            return ScaleTransition(
              scale: animation.drive(tween),
              alignment: alignment,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Transition de rotation
class RotationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  RotationPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final rotationTween = Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            final fadeTween = Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeIn));

            return RotationTransition(
              turns: animation.drive(rotationTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Transition combinée slide + fade
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Offset beginOffset;

  SlideFadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.beginOffset = const Offset(0.0, 0.3),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween(begin: beginOffset, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween = Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Transition de slide avec parallax
class ParallaxPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ParallaxPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Page entrante glisse de droite à gauche
            final primaryTween = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            // Page sortante glisse légèrement vers la gauche (effet parallax)
            final secondaryTween = Tween(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            return Stack(
              children: [
                SlideTransition(
                  position: secondaryAnimation.drive(secondaryTween),
                  child: child,
                ),
                SlideTransition(
                  position: animation.drive(primaryTween),
                  child: child,
                ),
              ],
            );
          },
        );
}

/// Transition de flip (retournement)
class FlipPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Axis axis;

  FlipPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
    this.axis = Axis.horizontal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final angle = animation.value * 3.14159; // π radians
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(axis == Axis.horizontal ? angle : 0.0)
                    ..rotateX(axis == Axis.vertical ? angle : 0.0),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: child,
            );
          },
        );
}

/// Transition avec effet de blur (flou)
class BlurPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  BlurPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

/// Extension pour faciliter la navigation avec animations
extension AnimatedNavigation on BuildContext {
  /// Navigation avec fade
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(FadePageRoute(page: page));
  }

  /// Navigation avec slide
  Future<T?> pushSlide<T>(Widget page, {Offset? beginOffset}) {
    return Navigator.of(this).push<T>(
      SlidePageRoute(page: page, beginOffset: beginOffset ?? const Offset(1.0, 0.0)),
    );
  }

  /// Navigation avec scale
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.of(this).push<T>(ScalePageRoute(page: page));
  }

  /// Navigation avec slide + fade
  Future<T?> pushSlideFade<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideFadePageRoute(page: page));
  }

  /// Navigation avec parallax
  Future<T?> pushParallax<T>(Widget page) {
    return Navigator.of(this).push<T>(ParallaxPageRoute(page: page));
  }
}
