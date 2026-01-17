import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/error/failures.dart';

/// Message d'erreur amélioré avec illustrations, tonalité empathique et actions contextuelles
class EnhancedErrorMessage extends StatefulWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final Map<String, VoidCallback>? customActions;

  const EnhancedErrorMessage({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
    this.customActions,
  });

  @override
  State<EnhancedErrorMessage> createState() => _EnhancedErrorMessageState();
}

class _EnhancedErrorMessageState extends State<EnhancedErrorMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Démarrer le countdown pour RateLimitFailure
    if (widget.failure is RateLimitFailure) {
      _secondsRemaining = 120; // 2 minutes par défaut
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final errorData = _getErrorData(widget.failure);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                  _buildAnimatedIcon(errorData),

                  const SizedBox(height: 24),

                  // Titre empathique
                  Text(
                    errorData.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: errorData.color,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Message explicatif
                  Text(
                    errorData.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.darkGray,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Countdown pour rate limit
                  if (widget.failure is RateLimitFailure && _secondsRemaining > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warningYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warningYellow.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: AppColors.warningYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Réessayez dans ${_formatTime(_secondsRemaining)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Actions
                  ...errorData.actions.map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActionButton(
                          label: action.label,
                          icon: action.icon,
                          onPressed: action.onPressed,
                          isPrimary: action.isPrimary,
                        ),
                      )),

                  // Bouton Retour/Annuler
                  if (widget.onDismiss != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: const Text(
                        'Retour',
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
      ),
    );
  }

  Widget _buildAnimatedIcon(_ErrorData errorData) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  errorData.color.withOpacity(0.2),
                  errorData.color.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: errorData.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              errorData.icon,
              size: 48,
              color: errorData.color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 2,
            shadowColor: AppColors.primaryOrange.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryOrange,
            side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
  }

  _ErrorData _getErrorData(Failure failure) {
    if (failure is NetworkFailure) {
      return _ErrorData(
        title: 'Connexion perdue',
        message: 'Nous n\'arrivons pas à vous connecter à Internet. '
            'Vérifiez votre Wi-Fi ou vos données mobiles et réessayez.',
        icon: Icons.wifi_off_rounded,
        color: AppColors.errorRed,
        actions: [
          _ErrorAction(
            label: 'Vérifier ma connexion',
            icon: Icons.settings,
            isPrimary: false,
            onPressed: () {
              // TODO: Ouvrir les paramètres réseau du système
            },
          ),
          if (widget.onRetry != null)
            _ErrorAction(
              label: 'Réessayer',
              icon: Icons.refresh,
              isPrimary: true,
              onPressed: widget.onRetry!,
            ),
        ],
      );
    } else if (failure is ServerFailure) {
      return _ErrorData(
        title: 'Service temporairement indisponible',
        message: 'Nos serveurs font une petite pause. '
            'Pas de panique, cela arrive ! Réessayez dans quelques instants.',
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFFF6B6B),
        actions: [
          if (widget.onRetry != null)
            _ErrorAction(
              label: 'Réessayer dans 30 secondes',
              icon: Icons.schedule,
              isPrimary: true,
              onPressed: () {
                Future.delayed(const Duration(seconds: 30), () {
                  widget.onRetry?.call();
                });
              },
            ),
          _ErrorAction(
            label: 'Réessayer maintenant',
            icon: Icons.refresh,
            isPrimary: false,
            onPressed: widget.onRetry ?? () {},
          ),
        ],
      );
    } else if (failure is RateLimitFailure) {
      return _ErrorData(
        title: 'Ralentissez un peu !',
        message: 'Vous avez effectué trop de recherches récemment. '
            'Prenez une pause café ☕ et réessayez dans quelques minutes.',
        icon: Icons.timer_outlined,
        color: AppColors.warningYellow,
        actions: [
          _ErrorAction(
            label: 'Affiner ma dernière recherche',
            icon: Icons.tune,
            isPrimary: true,
            onPressed: widget.customActions?['refineSearch'] ?? () {},
          ),
        ],
      );
    } else if (failure is TimeoutFailure) {
      return _ErrorData(
        title: 'Ça prend un peu de temps...',
        message: 'La recherche a pris trop de temps. '
            'Votre connexion est peut-être lente ou nous sommes très sollicités.',
        icon: Icons.hourglass_empty_rounded,
        color: const Color(0xFFFF9800),
        actions: [
          if (widget.onRetry != null)
            _ErrorAction(
              label: 'Réessayer',
              icon: Icons.refresh,
              isPrimary: true,
              onPressed: widget.onRetry!,
            ),
          _ErrorAction(
            label: 'Simplifier ma recherche',
            icon: Icons.search,
            isPrimary: false,
            onPressed: widget.customActions?['simplifySearch'] ?? () {},
          ),
        ],
      );
    } else if (failure is ApiKeyFailure) {
      return _ErrorData(
        title: 'Configuration incorrecte',
        message: 'Il semble y avoir un problème avec la configuration de l\'application. '
            'Contactez le support pour obtenir de l\'aide.',
        icon: Icons.key_off_rounded,
        color: const Color(0xFF9C27B0),
        actions: [
          _ErrorAction(
            label: 'Contacter le support',
            icon: Icons.support_agent,
            isPrimary: true,
            onPressed: () {
              // TODO: Ouvrir le support
            },
          ),
        ],
      );
    } else if (failure is ValidationFailure) {
      return _ErrorData(
        title: 'Paramètres invalides',
        message: failure.message,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warningYellow,
        actions: [
          _ErrorAction(
            label: 'Modifier mes critères',
            icon: Icons.edit,
            isPrimary: true,
            onPressed: widget.onDismiss ?? () {},
          ),
        ],
      );
    } else {
      return _ErrorData(
        title: 'Quelque chose s\'est mal passé',
        message: 'Une erreur inattendue est survenue. '
            'Nous en sommes désolés ! Réessayez ou contactez-nous si le problème persiste.',
        icon: Icons.error_outline_rounded,
        color: AppColors.errorRed,
        actions: [
          if (widget.onRetry != null)
            _ErrorAction(
              label: 'Réessayer',
              icon: Icons.refresh,
              isPrimary: true,
              onPressed: widget.onRetry!,
            ),
          _ErrorAction(
            label: 'Signaler le problème',
            icon: Icons.bug_report,
            isPrimary: false,
            onPressed: () {
              // TODO: Ouvrir formulaire de signalement
            },
          ),
        ],
      );
    }
  }
}

/// Données pour configurer l'affichage d'une erreur
class _ErrorData {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final List<_ErrorAction> actions;

  _ErrorData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.actions,
  });
}

/// Action disponible pour une erreur
class _ErrorAction {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  _ErrorAction({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });
}

/// Banner d'erreur amélioré avec animations
class EnhancedErrorBanner extends StatefulWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const EnhancedErrorBanner({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
  });

  @override
  State<EnhancedErrorBanner> createState() => _EnhancedErrorBannerState();
}

class _EnhancedErrorBannerState extends State<EnhancedErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss après 5 secondes si pas critique
    if (widget.failure is! NetworkFailure && widget.failure is! ApiKeyFailure) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _controller.reverse().then((_) => widget.onDismiss?.call());
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.failure is NetworkFailure) return const Color(0xFFFFEBEE);
    if (widget.failure is ServerFailure) return const Color(0xFFFFF3E0);
    if (widget.failure is RateLimitFailure) return const Color(0xFFFFFDE7);
    if (widget.failure is TimeoutFailure) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  Color _getTextColor() {
    if (widget.failure is NetworkFailure) return const Color(0xFFC62828);
    if (widget.failure is ServerFailure) return const Color(0xFFE65100);
    if (widget.failure is RateLimitFailure) return const Color(0xFFF57F17);
    if (widget.failure is TimeoutFailure) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  IconData _getIcon() {
    if (widget.failure is NetworkFailure) return Icons.wifi_off;
    if (widget.failure is ServerFailure) return Icons.cloud_off;
    if (widget.failure is RateLimitFailure) return Icons.timer;
    if (widget.failure is TimeoutFailure) return Icons.hourglass_empty;
    return Icons.error_outline;
  }

  String _getMessage() {
    if (widget.failure is NetworkFailure) return 'Connexion Internet perdue';
    if (widget.failure is ServerFailure) return 'Service temporairement indisponible';
    if (widget.failure is RateLimitFailure) return 'Trop de requêtes. Patientez quelques instants';
    if (widget.failure is TimeoutFailure) return 'Requête trop longue. Réessayez';
    return widget.failure.message;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border(
            bottom: BorderSide(
              color: _getTextColor().withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                _getIcon(),
                color: _getTextColor(),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getMessage(),
                  style: TextStyle(
                    color: _getTextColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.onRetry != null)
                TextButton(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: _getTextColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (widget.onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _controller.reverse().then((_) => widget.onDismiss?.call());
                  },
                  color: _getTextColor(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
