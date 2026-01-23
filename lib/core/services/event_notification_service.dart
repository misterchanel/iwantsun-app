import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/event.dart';
import 'package:iwantsun/core/router/app_router.dart';

/// Service pour gérer les notifications d'événements
class EventNotificationService {
  static final EventNotificationService _instance = EventNotificationService._internal();
  factory EventNotificationService() => _instance;
  EventNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AppLogger _logger = AppLogger();
  bool _initialized = false;
  
  // Callback pour la navigation (sera défini par l'app)
  Function(String eventId)? _onNotificationTappedCallback;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialiser les timezones
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));

      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuration d'initialisation
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Créer le canal de notification Android
      const androidChannel = AndroidNotificationChannel(
        'event_notifications',
        'Notifications d\'événements',
        description: 'Notifications pour les événements à venir',
        importance: Importance.high,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _initialized = true;
      _logger.info('EventNotificationService initialized');
    } catch (e, stackTrace) {
      _logger.error('Error initializing EventNotificationService', e, stackTrace);
    }
  }

  /// Définit le callback pour la navigation depuis les notifications
  void setNavigationCallback(Function(String eventId) callback) {
    _onNotificationTappedCallback = callback;
  }

  /// Gère le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    
    if (response.payload == null || response.payload!.isEmpty) {
      _logger.warning('Notification tapped but no payload found');
      return;
    }

    final eventId = response.payload!;
    _logger.info('Navigating to event: $eventId');

    // Utiliser le callback si défini
    if (_onNotificationTappedCallback != null) {
      _onNotificationTappedCallback!(eventId);
      return;
    }

    // Fallback: navigation directe via router
    try {
      _navigateToEvent(eventId);
    } catch (e, stackTrace) {
      _logger.error('Error navigating to event from notification', e, stackTrace);
    }
  }

  /// Navigue vers l'événement (fallback si callback non défini)
  Future<void> _navigateToEvent(String eventId) async {
    try {
      // L'ID de l'événement est stocké dans le payload
      // On va naviguer vers la page de recherche d'événements
      // L'utilisateur pourra rechercher à nouveau ou voir l'historique
      // Pour une meilleure UX, on pourrait aussi naviguer vers l'historique
      // où l'utilisateur pourrait retrouver sa recherche précédente
      AppRouter.router.go('/search/event');
      _logger.info('Navigated to event search screen for event $eventId');
    } catch (e, stackTrace) {
      _logger.error('Error navigating to event screen', e, stackTrace);
    }
  }
  
  /// Récupère les informations d'un événement depuis l'historique (si disponible)
  /// Cette méthode peut être étendue pour rechercher l'événement dans l'historique
  Future<Map<String, dynamic>?> getEventFromHistory(String eventId) async {
    // TODO: Implémenter la recherche dans l'historique si nécessaire
    // Pour l'instant, on retourne null car l'événement n'est pas stocké individuellement
    return null;
  }

  /// Planifie une notification pour un événement
  Future<bool> scheduleEventNotification(Event event, {Duration? reminderBefore}) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Ne planifier que pour les événements à venir
      if (!event.isUpcoming) {
        _logger.warning('Event ${event.id} is not upcoming, skipping notification');
        return false;
      }

      // Calculer l'heure de la notification (par défaut 24h avant)
      final reminderDuration = reminderBefore ?? const Duration(hours: 24);
      final notificationTime = event.startDate.subtract(reminderDuration);

      // Ne pas planifier si la notification est dans le passé
      if (notificationTime.isBefore(DateTime.now())) {
        _logger.warning('Notification time is in the past for event ${event.id}');
        return false;
      }

      // Convertir en TZDateTime
      final tzNotificationTime = tz.TZDateTime.from(notificationTime, tz.local);

      // ID unique pour la notification (basé sur l'ID de l'événement)
      final notificationId = event.id.hashCode.abs() % 2147483647; // Limite Android

      // Détails de la notification
      const androidDetails = AndroidNotificationDetails(
        'event_notifications',
        'Notifications d\'événements',
        channelDescription: 'Notifications pour les événements à venir',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Planifier la notification
      await _notifications.zonedSchedule(
        notificationId,
        'Événement à venir : ${event.name}',
        '${event.type.displayName} - ${event.dateDisplay}${event.locationName != null ? '\n📍 ${event.locationName}' : ''}',
        tzNotificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: event.id,
      );

      _logger.info('Notification scheduled for event ${event.id} at $notificationTime');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error scheduling notification for event ${event.id}', e, stackTrace);
      return false;
    }
  }

  /// Annule une notification pour un événement
  Future<void> cancelEventNotification(Event event) async {
    try {
      final notificationId = event.id.hashCode.abs() % 2147483647;
      await _notifications.cancel(notificationId);
      _logger.info('Notification cancelled for event ${event.id}');
    } catch (e, stackTrace) {
      _logger.error('Error cancelling notification for event ${event.id}', e, stackTrace);
    }
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e, stackTrace) {
      _logger.error('Error cancelling all notifications', e, stackTrace);
    }
  }

  /// Planifie des notifications pour une liste d'événements
  Future<int> scheduleEventNotifications(List<Event> events, {Duration? reminderBefore}) async {
    int scheduledCount = 0;
    for (final event in events) {
      if (await scheduleEventNotification(event, reminderBefore: reminderBefore)) {
        scheduledCount++;
      }
    }
    _logger.info('Scheduled $scheduledCount/${events.length} notifications');
    return scheduledCount;
  }

  /// Vérifie les permissions (Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        _logger.info('Notification permission granted: $granted');
        return granted ?? false;
      }
      return true; // iOS gère les permissions différemment
    } catch (e, stackTrace) {
      _logger.error('Error requesting notification permissions', e, stackTrace);
      return false;
    }
  }
}
