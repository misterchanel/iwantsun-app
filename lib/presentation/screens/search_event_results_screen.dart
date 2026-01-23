import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/domain/entities/event.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/core/services/event_notification_service.dart';
import 'package:iwantsun/presentation/widgets/event_favorite_button.dart';

/// Écran d'affichage des résultats de recherche d'événements
class SearchEventResultsScreen extends StatelessWidget {
  final EventSearchParams? params;
  final List<Event> events;

  const SearchEventResultsScreen({
    super.key,
    this.params,
    required this.events,
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
            const Text('Événements trouvés'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: events.isEmpty
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
                Icons.event_busy,
                size: 64,
                color: AppColors.mediumGray.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun événement trouvé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez d\'élargir votre zone de recherche\nou de modifier les critères',
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
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(context, events[index]);
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openEventDetails(context, event),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      event.type.icon,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  EventFavoriteButton(
                    event: event,
                    size: 24,
                    activeColor: AppColors.errorRed,
                    inactiveColor: AppColors.mediumGray,
                  ),
                ],
              ),
              if (event.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.dateDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
              if (event.locationName != null || event.city != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.locationName ?? event.city ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (event.distanceFromCenter != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: AppColors.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.distanceFromCenter!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ],
              if (event.price != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.euro,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'À partir de ${event.price!.toStringAsFixed(0)} ${event.priceCurrency ?? '€'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
              // Badge statut (à venir, en cours, passé)
              const SizedBox(height: 8),
              _buildStatusBadge(event),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (event.websiteUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openWebsite(event.websiteUrl!),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Infos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          side: BorderSide(color: AppColors.primaryOrange),
                        ),
                      ),
                    ),
                  if (event.websiteUrl != null) const SizedBox(width: 8),
                  if (event.isUpcoming)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _scheduleNotification(context, event),
                        icon: const Icon(Icons.notifications_outlined, size: 16),
                        label: const Text('Rappel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(event.type.icon, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
            content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(event.type.icon, color: AppColors.primaryOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Type: ${event.type.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusBadge(event),
              const SizedBox(height: 12),
              if (event.description != null) ...[
                Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  style: TextStyle(color: AppColors.darkGray),
                ),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(Icons.calendar_today, 'Date', event.dateDisplay),
              if (event.locationName != null)
                _buildDetailRow(Icons.location_on, 'Lieu', event.locationName!),
              if (event.city != null)
                _buildDetailRow(Icons.location_city, 'Ville', event.city!),
              if (event.distanceFromCenter != null)
                _buildDetailRow(
                  Icons.straighten,
                  'Distance',
                  '${event.distanceFromCenter!.toStringAsFixed(1)} km',
                ),
              if (event.price != null)
                _buildDetailRow(
                  Icons.euro,
                  'Prix',
                  'À partir de ${event.price!.toStringAsFixed(0)} ${event.priceCurrency ?? '€'}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (event.websiteUrl != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openWebsite(event.websiteUrl!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Voir le site'),
            ),
        ],
      ),
    );
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _scheduleNotification(BuildContext context, Event event) async {
    try {
      final notificationService = EventNotificationService();
      await notificationService.initialize();
      
      // Demander les permissions si nécessaire
      final hasPermission = await notificationService.requestPermissions();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les permissions de notification sont nécessaires'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Planifier la notification
      final scheduled = await notificationService.scheduleEventNotification(event);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scheduled
                  ? 'Rappel programmé pour ${event.name}'
                  : 'Impossible de programmer le rappel',
            ),
            backgroundColor: scheduled ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(Event event) {
    String label;
    Color color;
    IconData icon;

    if (event.isUpcoming) {
      label = 'À venir';
      color = Colors.blue;
      icon = Icons.schedule;
    } else if (event.isOngoing) {
      label = 'En cours';
      color = Colors.green;
      icon = Icons.play_circle;
    } else {
      label = 'Terminé';
      color = AppColors.mediumGray;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.mediumGray),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mediumGray,
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
          ),
        ],
      ),
    );
  }
}
