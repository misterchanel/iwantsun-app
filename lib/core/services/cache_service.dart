import 'package:hive/hive.dart';
import 'package:iwantsun/core/config/env_config.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/error/exceptions.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Service de cache utilisant Hive avec stratégie LRU
class CacheService {
  static final CacheService _instance = CacheService._internal();
  final AppLogger _logger = AppLogger();

  static const String _weatherCacheBox = 'weather_cache';
  static const String _locationCacheBox = 'location_cache';
  static const String _hotelCacheBox = 'hotel_cache';
  static const String _activityCacheBox = 'activity_cache';
  static const String _userPreferencesBox = 'user_preferences';
  static const String _favoritesBox = 'favorites';
  static const String _searchHistoryBox = 'search_history';

  // Statistiques de cache
  int _hits = 0;
  int _misses = 0;

  // Limites de taille par box (nombre d'entrées)
  static const int _maxCacheSize = 100;

  factory CacheService() => _instance;

  CacheService._internal();

  /// Initialise Hive
  Future<void> init() async {
    try {
      final appDocDir = await path_provider.getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);

      await Hive.openBox(_weatherCacheBox);
      await Hive.openBox(_locationCacheBox);
      await Hive.openBox(_hotelCacheBox);
      await Hive.openBox(_activityCacheBox);
      await Hive.openBox(_userPreferencesBox);
      await Hive.openBox(_favoritesBox);
      await Hive.openBox(_searchHistoryBox);

      _logger.info('Cache service initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize cache service', e, stackTrace);
      throw CacheException('Failed to initialize cache: $e');
    }
  }

  /// Récupère une valeur du cache
  /// [customTtlHours] permet de spécifier un TTL personnalisé au lieu d'utiliser la config par défaut
  Future<T?> get<T>(String key, String boxName, {int? customTtlHours}) async {
    try {
      final box = Hive.box(boxName);
      final cached = box.get(key);

      if (cached == null) {
        _misses++;
        _logger.debug('Cache miss for key: $key in box: $boxName');
        return null;
      }

      // Vérifier si le cache est expiré
      final cacheEntry = cached as Map<dynamic, dynamic>;
      
      // Sécuriser le cast du timestamp
      final timestampStr = cacheEntry['timestamp'];
      if (timestampStr == null || timestampStr is! String) {
        _logger.warning('Invalid cache entry format for key: $key in box: $boxName, deleting');
        await delete(key, boxName);
        _misses++;
        return null;
      }
      
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (e) {
        _logger.warning('Invalid timestamp format for key: $key in box: $boxName, deleting', e);
        await delete(key, boxName);
        _misses++;
        return null;
      }
      
      final expiryHours = customTtlHours ?? EnvConfig.cacheDurationHours;

      if (DateTime.now().difference(timestamp).inHours > expiryHours) {
        _logger.debug('Cache expired for key: $key in box: $boxName (TTL: ${expiryHours}h)');
        await delete(key, boxName);
        _misses++;
        return null;
      }

      // Mettre à jour le lastAccessed pour LRU
      await _updateLastAccessed(key, boxName);

      // Vérifier que les données existent
      if (!cacheEntry.containsKey('data')) {
        _logger.warning('Cache entry missing data field for key: $key in box: $boxName, deleting');
        await delete(key, boxName);
        _misses++;
        return null;
      }

      _hits++;
      _logger.debug('Cache hit for key: $key in box: $boxName (hit rate: ${cacheHitRate.toStringAsFixed(2)}%)');
      
      try {
        return cacheEntry['data'] as T;
      } catch (e) {
        _logger.warning('Failed to cast cache data for key: $key in box: $boxName, deleting', e);
        await delete(key, boxName);
        _misses++;
        return null;
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to get from cache', e, stackTrace);
      return null;
    }
  }

  /// Stocke une valeur dans le cache
  Future<void> put<T>(String key, T value, String boxName) async {
    try {
      final box = Hive.box(boxName);

      // Vérifier la limite de taille et supprimer les entrées LRU si nécessaire
      if (box.length >= _maxCacheSize) {
        await _evictLRU(boxName);
      }

      final now = DateTime.now();
      await box.put(key, {
        'data': value,
        'timestamp': now.toIso8601String(),
        'lastAccessed': now.toIso8601String(),
      });
      _logger.debug('Cached data for key: $key in box: $boxName');
    } catch (e, stackTrace) {
      _logger.error('Failed to put in cache', e, stackTrace);
      throw CacheException('Failed to cache data: $e');
    }
  }

  /// Met à jour le timestamp lastAccessed pour LRU
  Future<void> _updateLastAccessed(String key, String boxName) async {
    try {
      final box = Hive.box(boxName);
      final cached = box.get(key) as Map<dynamic, dynamic>?;
      if (cached != null) {
        cached['lastAccessed'] = DateTime.now().toIso8601String();
        await box.put(key, cached);
      }
    } catch (e) {
      _logger.warning('Failed to update lastAccessed', e);
    }
  }

  /// Supprime l'entrée la moins récemment utilisée (LRU)
  Future<void> _evictLRU(String boxName) async {
    try {
      final box = Hive.box(boxName);
      String? oldestKey;
      DateTime? oldestTime;

      for (var key in box.keys) {
        final entry = box.get(key) as Map<dynamic, dynamic>?;
        if (entry != null) {
          try {
            final lastAccessedStr = entry['lastAccessed'] as String? ?? entry['timestamp'] as String?;
            if (lastAccessedStr == null || lastAccessedStr is! String) {
              // Entrée invalide, la supprimer
              await box.delete(key);
              _logger.warning('Invalid lastAccessed/timestamp for key: $key in box: $boxName, deleting');
              continue;
            }
            
            final lastAccessed = DateTime.parse(lastAccessedStr);
            if (oldestTime == null || lastAccessed.isBefore(oldestTime)) {
              oldestTime = lastAccessed;
              oldestKey = key as String;
            }
          } catch (e) {
            // Timestamp invalide, supprimer l'entrée
            _logger.warning('Invalid timestamp format for key: $key in box: $boxName, deleting', e);
            await box.delete(key);
          }
        }
      }

      if (oldestKey != null) {
        await box.delete(oldestKey);
        _logger.debug('Evicted LRU entry: $oldestKey from box: $boxName');
      }
    } catch (e) {
      _logger.warning('Failed to evict LRU', e);
    }
  }

  /// Supprime une valeur du cache
  Future<void> delete(String key, String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
      _logger.debug('Deleted cache for key: $key in box: $boxName');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete from cache', e, stackTrace);
    }
  }

  /// Vide complètement un box de cache
  Future<void> clearBox(String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
      _logger.info('Cleared cache box: $boxName');
    } catch (e, stackTrace) {
      _logger.error('Failed to clear cache box', e, stackTrace);
    }
  }

  /// Vide tout le cache
  Future<void> clearAll() async {
    try {
      await clearBox(_weatherCacheBox);
      await clearBox(_locationCacheBox);
      await clearBox(_hotelCacheBox);
      await clearBox(_activityCacheBox);
      _logger.info('Cleared all cache');
    } catch (e, stackTrace) {
      _logger.error('Failed to clear all cache', e, stackTrace);
    }
  }

  /// Nettoie les entrées expirées de tous les box
  Future<int> cleanExpiredEntries() async {
    int cleaned = 0;
    try {
      final boxes = [
        _weatherCacheBox,
        _locationCacheBox,
        _hotelCacheBox,
        _activityCacheBox,
      ];

      for (final boxName in boxes) {
        cleaned += await _cleanExpiredEntriesInBox(boxName);
      }

      _logger.info('Cleaned $cleaned expired cache entries');
      return cleaned;
    } catch (e, stackTrace) {
      _logger.error('Failed to clean expired entries', e, stackTrace);
      return cleaned;
    }
  }

  /// Nettoie les entrées expirées dans un box spécifique
  Future<int> _cleanExpiredEntriesInBox(String boxName) async {
    int cleaned = 0;
    try {
      final box = Hive.box(boxName);
      final keysToDelete = <String>[];
      final expiryHours = EnvConfig.cacheDurationHours;

      for (var key in box.keys) {
        final entry = box.get(key) as Map<dynamic, dynamic>?;
        if (entry != null) {
          final timestampStr = entry['timestamp'];
          if (timestampStr == null || timestampStr is! String) {
            // Entrée invalide, la supprimer
            keysToDelete.add(key as String);
            continue;
          }
          
          try {
            final timestamp = DateTime.parse(timestampStr);
            if (DateTime.now().difference(timestamp).inHours > expiryHours) {
              keysToDelete.add(key as String);
            }
          } catch (e) {
            // Timestamp invalide, supprimer l'entrée
            _logger.warning('Invalid timestamp format for key: $key in box: $boxName, deleting', e);
            keysToDelete.add(key as String);
          }
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
        cleaned++;
      }

      return cleaned;
    } catch (e) {
      _logger.warning('Failed to clean expired entries in box: $boxName', e);
      return cleaned;
    }
  }

  /// Obtient les statistiques du cache
  Map<String, dynamic> getStatistics() {
    final total = _hits + _misses;
    return {
      'hits': _hits,
      'misses': _misses,
      'total': total,
      'hitRate': total > 0 ? (_hits / total * 100) : 0.0,
      'weatherCacheSize': _getBoxSize(_weatherCacheBox),
      'locationCacheSize': _getBoxSize(_locationCacheBox),
      'hotelCacheSize': _getBoxSize(_hotelCacheBox),
      'activityCacheSize': _getBoxSize(_activityCacheBox),
    };
  }

  /// Obtient la taille d'un box
  int _getBoxSize(String boxName) {
    try {
      return Hive.box(boxName).length;
    } catch (e) {
      return 0;
    }
  }

  /// Réinitialise les statistiques
  void resetStatistics() {
    _hits = 0;
    _misses = 0;
    _logger.info('Cache statistics reset');
  }

  /// Taux de hit du cache (%)
  double get cacheHitRate {
    final total = _hits + _misses;
    return total > 0 ? (_hits / total * 100) : 0.0;
  }

  // Constantes pour les noms de box
  static String get weatherCacheBox => _weatherCacheBox;
  static String get locationCacheBox => _locationCacheBox;
  static String get hotelCacheBox => _hotelCacheBox;
  static String get activityCacheBox => _activityCacheBox;
}
