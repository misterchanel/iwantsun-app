import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/presentation/providers/search_state.dart';

/// Indicateur de chargement amélioré avec contexte détaillé et animations
class EnhancedLoadingIndicator extends StatefulWidget {
  final SearchLoading loadingState;
  final VoidCallback? onCancel;

  const EnhancedLoadingIndicator({
    super.key,
    required this.loadingState,
    this.onCancel,
  });

  @override
  State<EnhancedLoadingIndicator> createState() => _EnhancedLoadingIndicatorState();
}

class _EnhancedLoadingIndicatorState extends State<EnhancedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(EnhancedLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rejouer l'animation quand l'état change
    if (oldWidget.loadingState.currentStep != widget.loadingState.currentStep) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getStepIcon(int? step) {
    switch (step) {
      case 1:
        return Icons.search;
      case 2:
        return Icons.wb_sunny;
      case 3:
        return Icons.hotel;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStepColor(int? step) {
    switch (step) {
      case 1:
        return AppColors.primaryOrange;
      case 2:
        return AppColors.sunnyYellow;
      case 3:
        return AppColors.primaryCoral;
      default:
        return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.loadingState.currentStep ?? 0;
    final totalSteps = widget.loadingState.totalSteps ?? 3;
    final progress = widget.loadingState.progress ?? (currentStep / totalSteps);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône animée avec cercle coloré
                _buildAnimatedIcon(currentStep),

                const SizedBox(height: 24),

                // Message principal
                Text(
                  widget.loadingState.message ?? 'Chargement...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Informations détaillées
                if (widget.loadingState.detailedInfo != null) ...[
                  Text(
                    widget.loadingState.detailedInfo!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mediumGray,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],

                // Indicateur de progression
                Text(
                  'Étape ${currentStep > 0 ? currentStep : 1} sur $totalSteps',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGray,
                  ),
                ),

                const SizedBox(height: 12),

                // Barre de progression animée
                _buildProgressBar(progress),

                // Pourcentage
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStepColor(currentStep),
                  ),
                ),

                // Bouton Annuler
                if (widget.onCancel != null) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text(
                      'Annuler la recherche',
                      style: TextStyle(
                        color: AppColors.mediumGray,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(int? step) {
    final icon = _getStepIcon(step);
    final color = _getStepColor(step);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de progression animé
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    backgroundColor: color.withOpacity(0.2),
                  ),
                ),
                // Icône
                Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double progress) {
    return Stack(
      children: [
        // Fond de la barre
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Progression animée
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStepColor(widget.loadingState.currentStep),
                      _getStepColor(widget.loadingState.currentStep).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: _getStepColor(widget.loadingState.currentStep).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Indicateur de chargement compact pour les petits espaces
class CompactLoadingIndicator extends StatelessWidget {
  final SearchLoading loadingState;

  const CompactLoadingIndicator({
    super.key,
    required this.loadingState,
  });

  @override
  Widget build(BuildContext context) {
    final progress = loadingState.progress ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: progress,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
              backgroundColor: AppColors.lightGray,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loadingState.message ?? 'Chargement...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (loadingState.detailedInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    loadingState.detailedInfo!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de skeleton loading pour les cartes de résultats
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne de titre
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Ligne de sous-titre
              Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              // Ligne de détails
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withOpacity(_animation.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withOpacity(_animation.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
