import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/error/exceptions.dart';

/// Service de gestion du rate limiting
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  final AppLogger _logger = AppLogger();

  // Map pour stocker les timestamps des dernières requêtes
  final Map<String, List<DateTime>> _requestTimestamps = {};

  factory RateLimiterService() => _instance;

  RateLimiterService._internal();

  /// Vérifie si une requête peut être effectuée
  /// [apiName] Nom de l'API
  /// [maxRequests] Nombre maximum de requêtes
  /// [duration] Durée de la fenêtre de temps
  Future<void> checkRateLimit(
    String apiName, {
    required int maxRequests,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    final timestamps = _requestTimestamps[apiName] ?? [];

    // Supprimer les timestamps trop anciens
    timestamps.removeWhere(
      (timestamp) => now.difference(timestamp) > duration,
    );

    // Vérifier si on a dépassé la limite
    if (timestamps.length >= maxRequests) {
      final oldestTimestamp = timestamps.first;
      final retryAfter = oldestTimestamp.add(duration);

      _logger.warning(
        'Rate limit exceeded for $apiName. Retry after: $retryAfter',
      );

      throw RateLimitException(
        'Limite de requêtes atteinte pour $apiName. Réessayez dans ${retryAfter.difference(now).inSeconds} secondes.',
        retryAfter,
      );
    }

    // Ajouter le timestamp actuel
    timestamps.add(now);
    _requestTimestamps[apiName] = timestamps;

    _logger.debug(
      'Rate limit check passed for $apiName: ${timestamps.length}/$maxRequests requests in ${duration.inSeconds}s',
    );
  }

  /// Réinitialise le rate limiter pour une API spécifique
  void reset(String apiName) {
    _requestTimestamps.remove(apiName);
    _logger.debug('Rate limiter reset for $apiName');
  }

  /// Réinitialise tous les rate limiters
  void resetAll() {
    _requestTimestamps.clear();
    _logger.debug('All rate limiters reset');
  }

  /// Attend jusqu'à ce qu'une requête soit autorisée
  Future<void> waitForAvailability(
    String apiName, {
    required int maxRequests,
    required Duration duration,
  }) async {
    while (true) {
      try {
        await checkRateLimit(
          apiName,
          maxRequests: maxRequests,
          duration: duration,
        );
        return;
      } on RateLimitException catch (e) {
        if (e.retryAfter != null) {
          final waitTime = e.retryAfter!.difference(DateTime.now());
          if (waitTime.inSeconds > 0) {
            _logger.info('Waiting ${waitTime.inSeconds}s before retrying $apiName');
            await Future.delayed(waitTime);
          }
        } else {
          // Si pas de retryAfter, attendre 1 seconde par défaut
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }
}
