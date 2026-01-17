import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// Widget pour afficher un état vide
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.1),
                    AppColors.warmPeach.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkGray.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
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
}

/// État vide pour aucun résultat de recherche
class NoResultsFound extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoResultsFound({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Aucun résultat trouvé',
      message: 'Essayez d\'ajuster vos critères de recherche\n'
          'ou d\'élargir votre zone de recherche.',
      actionLabel: onRetry != null ? 'Nouvelle recherche' : null,
      onAction: onRetry,
    );
  }
}

/// État vide pour aucune donnée disponible
class NoDataAvailable extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoDataAvailable({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: 'Aucune donnée disponible',
      message: 'Impossible de récupérer les données.\n'
          'Vérifiez votre connexion Internet.',
      actionLabel: onRefresh != null ? 'Réessayer' : null,
      onAction: onRefresh,
    );
  }
}

/// État vide pour commencer une recherche
class StartSearchPrompt extends StatelessWidget {
  const StartSearchPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.explore,
      title: 'Prêt à explorer ?',
      message: 'Définissez vos critères de recherche ci-dessus\n'
          'pour trouver votre destination idéale.',
    );
  }
}

/// État vide pour aucun hôtel trouvé
class NoHotelsFound extends StatelessWidget {
  const NoHotelsFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.hotel_outlined,
      title: 'Aucun hôtel disponible',
      message: 'Aucun hôtel trouvé pour cette destination.\n'
          'Essayez une autre ville ou période.',
    );
  }
}

/// État vide pour aucune activité trouvée
class NoActivitiesFound extends StatelessWidget {
  const NoActivitiesFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.sports_soccer,
      title: 'Aucune activité trouvée',
      message: 'Aucune activité disponible dans cette zone.\n'
          'Essayez d\'élargir le rayon de recherche.',
    );
  }
}
