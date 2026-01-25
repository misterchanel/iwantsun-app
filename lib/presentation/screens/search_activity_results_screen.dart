import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/domain/entities/search_params.dart';

/// Écran d'affichage des résultats de recherche d'activités
class SearchActivityResultsScreen extends StatelessWidget {
  final AdvancedSearchParams? params;
  final List<Activity> activities;

  const SearchActivityResultsScreen({
    super.key,
    this.params,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  size: 24,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${activities.length} activité${activities.length > 1 ? 's' : ''} trouvée${activities.length > 1 ? 's' : ''}'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: activities.isEmpty
          ? _buildEmptyState(context)
          : _buildResultsList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/terrasse.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cream.withOpacity(0.85),
              AppColors.cream.withOpacity(0.90),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 64,
                color: AppColors.mediumGray.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune activité trouvée',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez d\'élargir votre zone de recherche\nou de sélectionner d\'autres types d\'activités',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour à la recherche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    // Grouper les activités par type
    final groupedActivities = <ActivityType, List<Activity>>{};
    for (final activity in activities) {
      groupedActivities.putIfAbsent(activity.type, () => []).add(activity);
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/terrasse.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cream.withOpacity(0.85),
              AppColors.cream.withOpacity(0.90),
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildActivityCard(context, activities[index]);
          },
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showActivityDetails(context, activity),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône de l'activité
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getActivityColor(activity.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: _getActivityColor(activity.type),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getActivityColor(activity.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getActivityTypeName(activity.type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getActivityColor(activity.type),
                            ),
                          ),
                        ),
                        if (activity.distanceFromLocation != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.darkGray,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${activity.distanceFromLocation!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (activity.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.mediumGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getActivityColor(activity.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getActivityIcon(activity.type),
                    size: 16,
                    color: _getActivityColor(activity.type),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getActivityTypeName(activity.type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getActivityColor(activity.type),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Nom
            Text(
              activity.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (activity.description != null) ...[
              const SizedBox(height: 12),
              Text(
                activity.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Distance
            if (activity.distanceFromLocation != null)
              _buildDetailRow(
                Icons.location_on,
                'Distance',
                '${activity.distanceFromLocation!.toStringAsFixed(1)} km du centre',
              ),
            // Coordonnées
            if (activity.latitude != null && activity.longitude != null)
              _buildDetailRow(
                Icons.map,
                'Coordonnées',
                '${activity.latitude!.toStringAsFixed(4)}, ${activity.longitude!.toStringAsFixed(4)}',
              ),
            const SizedBox(height: 24),
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Fermer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: BorderSide(color: AppColors.mediumGray),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: activity.latitude != null && activity.longitude != null
                        ? () => _openInMaps(activity)
                        : null,
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(Activity activity) async {
    if (activity.latitude == null || activity.longitude == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${activity.latitude},${activity.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.beach:
        return Icons.beach_access;
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.skiing:
        return Icons.snowboarding;
      case ActivityType.surfing:
        return Icons.surfing;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.golf:
        return Icons.sports_golf;
      case ActivityType.camping:
        return Icons.cabin;
      case ActivityType.other:
        return Icons.sports_soccer;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.beach:
        return Colors.blue;
      case ActivityType.hiking:
        return Colors.green;
      case ActivityType.skiing:
        return Colors.indigo;
      case ActivityType.surfing:
        return Colors.cyan;
      case ActivityType.cycling:
        return Colors.orange;
      case ActivityType.golf:
        return Colors.teal;
      case ActivityType.camping:
        return Colors.brown;
      case ActivityType.other:
        return AppColors.primaryOrange;
    }
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.beach:
        return 'Plage / Baignade';
      case ActivityType.hiking:
        return 'Randonnée';
      case ActivityType.skiing:
        return 'Ski';
      case ActivityType.surfing:
        return 'Surf';
      case ActivityType.cycling:
        return 'Vélo';
      case ActivityType.golf:
        return 'Golf';
      case ActivityType.camping:
        return 'Camping';
      case ActivityType.other:
        return 'Autre';
    }
  }
}
