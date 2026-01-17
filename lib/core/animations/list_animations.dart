import 'package:flutter/material.dart';

/// Animations pour listes et grilles avec effets d'entrée échelonnés

/// Widget pour animer l'entrée d'un élément de liste
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;
  final bool fadeIn;
  final bool slideIn;
  final bool scaleIn;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0, 0.3),
    this.fadeIn = true,
    this.slideIn = true,
    this.scaleIn = false,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(
      begin: widget.fadeIn ? 0.0 : 1.0,
      end: 1.0,
    ).animate(curvedAnimation);

    _slideAnimation = Tween<Offset>(
      begin: widget.slideIn ? widget.slideOffset : Offset.zero,
      end: Offset.zero,
    ).animate(curvedAnimation);

    _scaleAnimation = Tween<double>(
      begin: widget.scaleIn ? 0.8 : 1.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // Délai basé sur l'index
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget result = child!;

        if (widget.scaleIn) {
          result = Transform.scale(
            scale: _scaleAnimation.value,
            child: result,
          );
        }

        if (widget.slideIn) {
          result = Transform.translate(
            offset: Offset(
              _slideAnimation.value.dx * MediaQuery.of(context).size.width,
              _slideAnimation.value.dy * MediaQuery.of(context).size.height,
            ),
            child: result,
          );
        }

        if (widget.fadeIn) {
          result = Opacity(
            opacity: _fadeAnimation.value,
            child: result,
          );
        }

        return result;
      },
      child: widget.child,
    );
  }
}

/// Liste avec animation d'entrée échelonnée
class StaggeredAnimatedList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const StaggeredAnimatedList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 80),
    this.itemDuration = const Duration(milliseconds: 400),
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          delay: itemDelay,
          duration: itemDuration,
          slideOffset: scrollDirection == Axis.vertical
              ? const Offset(0, 0.2)
              : const Offset(0.2, 0),
          child: children[index],
        );
      },
    );
  }
}

/// Grille avec animation d'entrée échelonnée
class StaggeredAnimatedGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final Duration itemDelay;
  final Duration itemDuration;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const StaggeredAnimatedGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.itemDelay = const Duration(milliseconds: 60),
    this.itemDuration = const Duration(milliseconds: 400),
    this.mainAxisSpacing = 10,
    this.crossAxisSpacing = 10,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          delay: itemDelay,
          duration: itemDuration,
          scaleIn: true,
          child: children[index],
        );
      },
    );
  }
}

/// Animation de suppression d'élément de liste
class SlideOutListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismissed;
  final Duration duration;
  final Axis direction;

  const SlideOutListItem({
    super.key,
    required this.child,
    this.onDismissed,
    this.duration = const Duration(milliseconds: 300),
    this.direction = Axis.horizontal,
  });

  @override
  State<SlideOutListItem> createState() => SlideOutListItemState();

  /// Déclenche l'animation de suppression
  static void remove(BuildContext context) {
    final state = context.findAncestorStateOfType<SlideOutListItemState>();
    state?.remove();
  }
}

class SlideOutListItemState extends State<SlideOutListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: widget.direction == Axis.horizontal
          ? const Offset(1.0, 0.0)
          : const Offset(0.0, -1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void remove() {
    _controller.forward().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animation de révélation progressive (expand)
class ExpandAnimation extends StatefulWidget {
  final Widget child;
  final bool expand;
  final Duration duration;
  final Axis axis;

  const ExpandAnimation({
    super.key,
    required this.child,
    required this.expand,
    this.duration = const Duration(milliseconds: 300),
    this.axis = Axis.vertical,
  });

  @override
  State<ExpandAnimation> createState() => _ExpandAnimationState();
}

class _ExpandAnimationState extends State<ExpandAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    if (widget.expand) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ExpandAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.expand != oldWidget.expand) {
      if (widget.expand) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axis: widget.axis,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child,
      ),
    );
  }
}

/// Effet de rebond pour les boutons et interactions
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const BounceAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
