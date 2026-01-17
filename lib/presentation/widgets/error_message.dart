import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/error/failures.dart';

/// Widget pour afficher un message d'erreur
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.errorRed.withOpacity(0.1),
                    AppColors.errorRed.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 64,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.errorRed,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primaryOrange.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Crée un ErrorMessage depuis un Failure
  factory ErrorMessage.fromFailure(
    Failure failure, {
    VoidCallback? onRetry,
  }) {
    String message;
    IconData icon;

    if (failure is NetworkFailure) {
      message = 'Vérifiez votre connexion Internet\net réessayez.';
      icon = Icons.wifi_off;
    } else if (failure is ServerFailure) {
      message = 'Le serveur ne répond pas.\nVeuillez réessayer plus tard.';
      icon = Icons.cloud_off;
    } else if (failure is ApiKeyFailure) {
      message = 'Configuration invalide.\nVérifiez vos clés API.';
      icon = Icons.key_off;
    } else if (failure is RateLimitFailure) {
      message = 'Trop de requêtes.\nVeuillez patienter quelques instants.';
      icon = Icons.timer_off;
    } else if (failure is TimeoutFailure) {
      message = 'La requête a pris trop de temps.\nVeuillez réessayer.';
      icon = Icons.access_time;
    } else if (failure is ValidationFailure) {
      message = failure.message;
      icon = Icons.warning_amber;
    } else {
      message = 'Une erreur est survenue.\n${failure.message}';
      icon = Icons.error_outline;
    }

    return ErrorMessage(
      message: message,
      onRetry: onRetry,
      icon: icon,
    );
  }
}

/// Bannière d'erreur compacte pour afficher en haut d'un écran
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: Colors.red.shade700,
            ),
        ],
      ),
    );
  }
}

/// Snackbar d'erreur stylisé
class ErrorSnackBar {
  static void show(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null
          ? SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Affiche un snackbar d'erreur depuis un Failure
  static void showFromFailure(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
  }) {
    String message;

    if (failure is NetworkFailure) {
      message = 'Vérifiez votre connexion Internet';
    } else if (failure is ServerFailure) {
      message = 'Erreur serveur. Réessayez plus tard.';
    } else if (failure is ApiKeyFailure) {
      message = 'Configuration invalide';
    } else if (failure is RateLimitFailure) {
      message = 'Trop de requêtes. Patientez.';
    } else if (failure is TimeoutFailure) {
      message = 'Délai dépassé. Réessayez.';
    } else {
      message = failure.message;
    }

    show(context, message, onRetry: onRetry);
  }
}

/// Widget inline pour afficher une erreur dans une liste ou formulaire
class InlineError extends StatelessWidget {
  final String message;
  final bool showIcon;

  const InlineError({
    super.key,
    required this.message,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
