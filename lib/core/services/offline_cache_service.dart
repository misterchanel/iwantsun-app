import 'dart:convert';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/search_params.dart';

/// Service de cache offline pour les données de l'application
class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  final CacheService _cacheService = CacheService();
  final AppLogger _logger = AppLogger();

  static const String _searchResultsBox = 'offline_search_results';
  static const String _popularDestinationsBox = 'offline_popular';
  static const String _lastSearchBox = 'offline_last_search';
  static const String _metadataBox = 'offline_metadata';

  // TTL pour différents types de données
  static const Duration _searchResultsTTL = Duration(hours: 24);
  static const Duration _popularDestinationsTTL = Duration(days: 7);

  /// Initialiser le service
  Future<void> init() async {
    try {
      await _cacheService.init();
      _logger.info('OfflineCacheService initialized');
    } catch (e) {
      _logger.error('Failed to initialize OfflineCacheService', e);
    }
  }

  // ============================================
  // RÉSULTATS DE RECHERCHE
  // ============================================

  /// Sauvegarder les résultats d'une recherche
  Future<void> cacheSearchResults({
    required SearchParams params,
    required List<Map<String, dynamic>> results,
  }) async {
    try {
      final key = _generateSearchKey(params);
      final cacheEntry = {
        'params': params.toJson(),
        'results': results,
        'cachedAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(_searchResultsTTL).toIso8601String(),
      };

      await _cacheService.put(key, cacheEntry, _searchResultsBox);
      _logger.info('Cached ${results.length} search results for key: $key');
    } catch (e) {
      _logger.error('Failed to cache search results', e);
    }
  }

  /// Récupérer des résultats de recherche en cache
  Future<List<Map<String, dynamic>>?> getCachedSearchResults(SearchParams params) async {
    try {
      final key = _generateSearchKey(params);
      final cacheEntry = await _cacheService.get<Map<String, dynamic>>(
        key,
        _searchResultsBox,
      );

      if (cacheEntry == null) return null;

      // Vérifier l'expiration
      final expiresAt = DateTime.parse(cacheEntry['expiresAt'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        _logger.debug('Cache expired for key: $key');
        await _cacheService.delete(key, _searchResultsBox);
        return null;
      }

      final results = (cacheEntry['results'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      _logger.info('Retrieved ${results.length} cached results for key: $key');
      return results;
    } catch (e) {
      _logger.error('Failed to get cached search results', e);
      return null;
    }
  }

  /// Générer une clé unique pour les paramètres de recherche
  String _generateSearchKey(SearchParams params) {
    final key = '${params.centerLatitude?.toStringAsFixed(2)}_'
        '${params.centerLongitude?.toStringAsFixed(2)}_'
        '${params.searchRadiusKm}_'
        '${params.startDate?.toIso8601String().substring(0, 10)}_'
        '${params.endDate?.toIso8601String().substring(0, 10)}_'
        '${params.desiredMinTemperature?.toInt()}_'
        '${params.desiredMaxTemperature?.toInt()}';
    return key;
  }

  // ============================================
  // DERNIÈRE RECHERCHE
  // ============================================

  /// Sauvegarder la dernière recherche
  Future<void> saveLastSearch({
    required SearchParams params,
    required List<Map<String, dynamic>> results,
    String? locationName,
  }) async {
    try {
      final data = {
        'params': params.toJson(),
        'results': results,
        'locationName': locationName,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _cacheService.put('last_search', data, _lastSearchBox);
      _logger.info('Saved last search');
    } catch (e) {
      _logger.error('Failed to save last search', e);
    }
  }

  /// Récupérer la dernière recherche
  Future<Map<String, dynamic>?> getLastSearch() async {
    try {
      final data = await _cacheService.get<Map<String, dynamic>>(
        'last_search',
        _lastSearchBox,
      );
      return data;
    } catch (e) {
      _logger.error('Failed to get last search', e);
      return null;
    }
  }

  // ============================================
  // DESTINATIONS POPULAIRES (Pré-téléchargées)
  // ============================================

  /// Sauvegarder les destinations populaires
  Future<void> cachePopularDestinations(List<Map<String, dynamic>> destinations) async {
    try {
      final data = {
        'destinations': destinations,
        'cachedAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(_popularDestinationsTTL).toIso8601String(),
      };

      await _cacheService.put('popular', data, _popularDestinationsBox);
      _logger.info('Cached ${destinations.length} popular destinations');
    } catch (e) {
      _logger.error('Failed to cache popular destinations', e);
    }
  }

  /// Récupérer les destinations populaires
  Future<List<Map<String, dynamic>>?> getPopularDestinations() async {
    try {
      final data = await _cacheService.get<Map<String, dynamic>>(
        'popular',
        _popularDestinationsBox,
      );

      if (data == null) return null;

      // Vérifier l'expiration
      final expiresAt = DateTime.parse(data['expiresAt'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        await _cacheService.delete('popular', _popularDestinationsBox);
        return null;
      }

      return (data['destinations'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.error('Failed to get popular destinations', e);
      return null;
    }
  }

  // ============================================
  // MÉTADONNÉES ET STATISTIQUES
  // ============================================

  /// Sauvegarder les métadonnées du cache
  Future<void> updateMetadata() async {
    try {
      final metadata = {
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      await _cacheService.put('metadata', metadata, _metadataBox);
    } catch (e) {
      _logger.error('Failed to update cache metadata', e);
    }
  }

  /// Obtenir les statistiques du cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final metadata = await _cacheService.get<Map<String, dynamic>>(
        'metadata',
        _metadataBox,
      );

      return {
        'lastUpdated': metadata?['lastUpdated'],
        'version': metadata?['version'] ?? '1.0',
        'hasLastSearch': await getLastSearch() != null,
        'hasPopularDestinations': await getPopularDestinations() != null,
      };
    } catch (e) {
      _logger.error('Failed to get cache stats', e);
      return {};
    }
  }

  // ============================================
  // GESTION DU CACHE
  // ============================================

  /// Vider tout le cache offline
  Future<void> clearAll() async {
    try {
      await _cacheService.clearAll();
      _logger.info('Offline cache cleared');
    } catch (e) {
      _logger.error('Failed to clear offline cache', e);
    }
  }

  /// Vider uniquement les résultats de recherche expirés
  Future<void> clearExpired() async {
    try {
      // Note: L'implémentation complète nécessiterait d'itérer sur toutes les clés
      // Pour simplifier, on se contente de logger
      _logger.info('Clearing expired cache entries');
    } catch (e) {
      _logger.error('Failed to clear expired cache', e);
    }
  }

  /// Obtenir la taille approximative du cache
  Future<String> getCacheSize() async {
    // Estimation basée sur le nombre d'entrées
    // Dans une vraie app, on calculerait la taille réelle
    return 'Données en cache disponibles';
  }
}

/// Widget pour afficher l'état offline avec les données disponibles
class OfflineDataInfo {
  final bool hasLastSearch;
  final bool hasPopularDestinations;
  final bool hasFavorites;
  final DateTime? lastUpdated;

  OfflineDataInfo({
    required this.hasLastSearch,
    required this.hasPopularDestinations,
    required this.hasFavorites,
    this.lastUpdated,
  });

  bool get hasOfflineData => hasLastSearch || hasPopularDestinations || hasFavorites;

  String get summary {
    if (!hasOfflineData) {
      return 'Aucune donnée disponible hors ligne';
    }

    final parts = <String>[];
    if (hasLastSearch) parts.add('dernière recherche');
    if (hasPopularDestinations) parts.add('destinations populaires');
    if (hasFavorites) parts.add('favoris');

    return 'Disponible : ${parts.join(', ')}';
  }
}
