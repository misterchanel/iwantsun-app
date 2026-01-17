import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iwantsun/core/services/logger_service.dart';

/// Types d'événements analytics
enum AnalyticsEventType {
  screenView,
  search,
  resultView,
  favoriteAdd,
  favoriteRemove,
  share,
  error,
  buttonClick,
  featureUsed,
}

/// Événement analytics
class AnalyticsEvent {
  final String name;
  final AnalyticsEventType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.type,
    this.parameters = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Configuration A/B testing
class ABTestConfig {
  final String testId;
  final String variant;
  final DateTime assignedAt;

  ABTestConfig({
    required this.testId,
    required this.variant,
    required this.assignedAt,
  });

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'variant': variant,
    'assignedAt': assignedAt.toIso8601String(),
  };

  factory ABTestConfig.fromJson(Map<String, dynamic> json) {
    return ABTestConfig(
      testId: json['testId'] as String,
      variant: json['variant'] as String,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
    );
  }
}

/// Service d'analytics et A/B testing
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final AppLogger _logger = AppLogger();
  static const String _abTestsKey = 'ab_tests';
  static const String _userIdKey = 'analytics_user_id';
  static const int _maxLocalEvents = 100;

  final List<AnalyticsEvent> _localEvents = [];
  final Map<String, ABTestConfig> _abTests = {};
  String? _userId;
  bool _isInitialized = false;
  bool _analyticsEnabled = true;

  bool get isInitialized => _isInitialized;
  bool get analyticsEnabled => _analyticsEnabled;

  /// Initialiser le service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Récupérer ou générer l'ID utilisateur
      _userId = prefs.getString(_userIdKey);
      if (_userId == null) {
        _userId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString(_userIdKey, _userId!);
      }

      // Charger les tests A/B
      final abTestsJson = prefs.getString(_abTestsKey);
      if (abTestsJson != null) {
        final data = jsonDecode(abTestsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _abTests[entry.key] = ABTestConfig.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }

      _isInitialized = true;
      _logger.info('AnalyticsService initialized with user: $_userId');
    } catch (e) {
      _logger.error('Failed to initialize AnalyticsService', e);
      _isInitialized = true;
    }
  }

  /// Activer/désactiver les analytics
  void setAnalyticsEnabled(bool enabled) {
    _analyticsEnabled = enabled;
    _logger.info('Analytics ${enabled ? "enabled" : "disabled"}');
  }

  // ============================================
  // TRACKING D'ÉVÉNEMENTS
  // ============================================

  /// Tracker un événement
  void trackEvent(AnalyticsEvent event) {
    if (!_analyticsEnabled) return;

    _localEvents.add(event);
    if (_localEvents.length > _maxLocalEvents) {
      _localEvents.removeAt(0);
    }

    _logger.debug('Analytics event: ${event.name} - ${event.parameters}');

    // TODO: Envoyer à un backend d'analytics (Firebase, Mixpanel, etc.)
  }

  /// Tracker une vue d'écran
  void trackScreenView(String screenName, {Map<String, dynamic>? params}) {
    trackEvent(AnalyticsEvent(
      name: 'screen_view',
      type: AnalyticsEventType.screenView,
      parameters: {
        'screen_name': screenName,
        ...?params,
      },
    ));
  }

  /// Tracker une recherche
  void trackSearch({
    required String location,
    required double minTemp,
    required double maxTemp,
    required int radius,
    int? resultsCount,
  }) {
    trackEvent(AnalyticsEvent(
      name: 'search',
      type: AnalyticsEventType.search,
      parameters: {
        'location': location,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'radius_km': radius,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    ));
  }

  /// Tracker un ajout aux favoris
  void trackFavoriteAdd(String destinationId, String destinationName) {
    trackEvent(AnalyticsEvent(
      name: 'favorite_add',
      type: AnalyticsEventType.favoriteAdd,
      parameters: {
        'destination_id': destinationId,
        'destination_name': destinationName,
      },
    ));
  }

  /// Tracker un partage
  void trackShare(String destinationId, String method) {
    trackEvent(AnalyticsEvent(
      name: 'share',
      type: AnalyticsEventType.share,
      parameters: {
        'destination_id': destinationId,
        'method': method,
      },
    ));
  }

  /// Tracker un clic bouton
  void trackButtonClick(String buttonName, {String? screen}) {
    trackEvent(AnalyticsEvent(
      name: 'button_click',
      type: AnalyticsEventType.buttonClick,
      parameters: {
        'button_name': buttonName,
        if (screen != null) 'screen': screen,
      },
    ));
  }

  /// Tracker une erreur
  void trackError(String errorType, String errorMessage, {String? screen}) {
    trackEvent(AnalyticsEvent(
      name: 'error',
      type: AnalyticsEventType.error,
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screen != null) 'screen': screen,
      },
    ));
  }

  // ============================================
  // A/B TESTING
  // ============================================

  /// Obtenir le variant pour un test A/B
  String getABTestVariant(String testId, List<String> variants) {
    // Vérifier si déjà assigné
    if (_abTests.containsKey(testId)) {
      return _abTests[testId]!.variant;
    }

    // Assigner un variant basé sur l'ID utilisateur
    final userHash = _userId.hashCode.abs();
    final variantIndex = userHash % variants.length;
    final variant = variants[variantIndex];

    // Sauvegarder
    _abTests[testId] = ABTestConfig(
      testId: testId,
      variant: variant,
      assignedAt: DateTime.now(),
    );
    _saveABTests();

    _logger.info('A/B Test "$testId" assigned variant: $variant');
    return variant;
  }

  /// Vérifier si l'utilisateur est dans un variant spécifique
  bool isInVariant(String testId, String variant) {
    return _abTests[testId]?.variant == variant;
  }

  Future<void> _saveABTests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      for (final entry in _abTests.entries) {
        data[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_abTestsKey, jsonEncode(data));
    } catch (e) {
      _logger.error('Failed to save A/B tests', e);
    }
  }

  // ============================================
  // RAPPORTS
  // ============================================

  /// Obtenir les événements récents
  List<AnalyticsEvent> getRecentEvents({int limit = 50}) {
    return _localEvents.reversed.take(limit).toList();
  }

  /// Obtenir les statistiques de session
  Map<String, dynamic> getSessionStats() {
    final screenViews = _localEvents
        .where((e) => e.type == AnalyticsEventType.screenView)
        .length;
    final searches = _localEvents
        .where((e) => e.type == AnalyticsEventType.search)
        .length;
    final favorites = _localEvents
        .where((e) => e.type == AnalyticsEventType.favoriteAdd)
        .length;

    return {
      'total_events': _localEvents.length,
      'screen_views': screenViews,
      'searches': searches,
      'favorites_added': favorites,
      'session_start': _localEvents.isNotEmpty
          ? _localEvents.first.timestamp.toIso8601String()
          : null,
    };
  }

  /// Exporter les données analytics
  String exportAnalytics() {
    final data = {
      'user_id': _userId,
      'ab_tests': _abTests.map((k, v) => MapEntry(k, v.toJson())),
      'events': _localEvents.map((e) => e.toJson()).toList(),
      'session_stats': getSessionStats(),
      'exported_at': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

/// Mixin pour tracker automatiquement les vues d'écran
mixin AnalyticsScreenMixin<T extends StatefulWidget> on State<T> {
  String get screenName;

  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreenView(screenName);
  }
}

/// Tests A/B prédéfinis
class ABTests {
  static const String searchButtonStyle = 'search_button_style';
  static const String resultCardLayout = 'result_card_layout';
  static const String onboardingFlow = 'onboarding_flow';

  /// Variants pour le style du bouton de recherche
  static const List<String> searchButtonVariants = ['primary', 'gradient', 'outlined'];

  /// Variants pour le layout des cartes de résultat
  static const List<String> resultCardVariants = ['compact', 'expanded', 'minimal'];
}
