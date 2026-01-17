import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/search_params.dart';

/// Représente une entrée dans l'historique de recherche
class SearchHistoryEntry {
  final String id;
  final SearchParams params;
  final DateTime searchedAt;
  final int resultsCount;
  final String? locationName; // Nom lisible de la localisation

  const SearchHistoryEntry({
    required this.id,
    required this.params,
    required this.searchedAt,
    required this.resultsCount,
    this.locationName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'params': params.toJson(),
      'searchedAt': searchedAt.toIso8601String(),
      'resultsCount': resultsCount,
      'locationName': locationName,
    };
  }

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id'] as String,
      params: SearchParams.fromJson(json['params'] as Map<String, dynamic>),
      searchedAt: DateTime.parse(json['searchedAt'] as String),
      resultsCount: json['resultsCount'] as int,
      locationName: json['locationName'] as String?,
    );
  }

  /// Description lisible de la recherche
  String get displayDescription {
    final location = locationName ?? 'Localisation';
    final minTemp = params.desiredMinTemperature?.toInt() ?? 20;
    final maxTemp = params.desiredMaxTemperature?.toInt() ?? 30;
    final temp = '$minTemp-$maxTemp°C';
    return '$location • $temp';
  }
}

/// Service pour gérer l'historique des recherches
class SearchHistoryService {
  static const String _historyBoxName = 'search_history';
  static const String _historyKey = 'user_search_history';
  static const int _maxHistorySize = 20; // Garder les 20 dernières recherches

  final CacheService _cacheService;
  final AppLogger _logger;

  // Singleton
  static final SearchHistoryService _instance = SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;

  SearchHistoryService._internal()
      : _cacheService = CacheService(),
        _logger = AppLogger();

  /// Initialiser le service
  Future<void> init() async {
    try {
      await _cacheService.init();
      _logger.info('SearchHistoryService initialized');
    } catch (e) {
      _logger.error('Failed to initialize SearchHistoryService', e);
    }
  }

  /// Récupérer l'historique complet
  Future<List<SearchHistoryEntry>> getHistory() async {
    try {
      final data = await _cacheService.get<List<dynamic>>(
        _historyKey,
        _historyBoxName,
      );

      if (data == null) {
        return [];
      }

      final history = data
          .map((json) => SearchHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      // Trier par date (plus récent en premier)
      history.sort((a, b) => b.searchedAt.compareTo(a.searchedAt));

      _logger.debug('Loaded ${history.length} history entries');
      return history;
    } catch (e) {
      _logger.error('Failed to load search history', e);
      return [];
    }
  }

  /// Ajouter une recherche à l'historique
  Future<bool> addSearch({
    required SearchParams params,
    required int resultsCount,
    String? locationName,
  }) async {
    try {
      final entry = SearchHistoryEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        params: params,
        searchedAt: DateTime.now(),
        resultsCount: resultsCount,
        locationName: locationName,
      );

      final history = await getHistory();

      // Vérifier si une recherche similaire existe déjà (même localisation et dates)
      history.removeWhere((h) =>
          h.params.centerLatitude == params.centerLatitude &&
          h.params.centerLongitude == params.centerLongitude &&
          h.params.startDate == params.startDate &&
          h.params.endDate == params.endDate);

      // Ajouter en première position
      history.insert(0, entry);

      // Limiter la taille de l'historique
      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }

      await _saveHistory(history);
      _logger.info('Added search to history: $locationName');
      return true;
    } catch (e) {
      _logger.error('Failed to add search to history', e);
      return false;
    }
  }

  /// Retirer une entrée de l'historique
  Future<bool> removeEntry(String entryId) async {
    try {
      final history = await getHistory();
      final initialLength = history.length;

      history.removeWhere((e) => e.id == entryId);

      if (history.length == initialLength) {
        _logger.warning('History entry not found: $entryId');
        return false;
      }

      await _saveHistory(history);
      _logger.info('Removed history entry: $entryId');
      return true;
    } catch (e) {
      _logger.error('Failed to remove history entry', e);
      return false;
    }
  }

  /// Obtenir les recherches récentes (5 dernières)
  Future<List<SearchHistoryEntry>> getRecentSearches({int limit = 5}) async {
    final history = await getHistory();
    return history.take(limit).toList();
  }

  /// Vider tout l'historique
  Future<bool> clearHistory() async {
    try {
      await _saveHistory([]);
      _logger.info('Cleared search history');
      return true;
    } catch (e) {
      _logger.error('Failed to clear history', e);
      return false;
    }
  }

  /// Obtenir le nombre d'entrées dans l'historique
  Future<int> getHistoryCount() async {
    final history = await getHistory();
    return history.length;
  }

  /// Sauvegarder l'historique
  Future<void> _saveHistory(List<SearchHistoryEntry> history) async {
    final data = history.map((e) => e.toJson()).toList();
    await _cacheService.put(
      _historyKey,
      data,
      _historyBoxName,
    );
  }

  /// Obtenir les statistiques de recherche
  Future<Map<String, dynamic>> getStatistics() async {
    final history = await getHistory();

    if (history.isEmpty) {
      return {
        'totalSearches': 0,
        'averageResults': 0.0,
        'mostSearchedLocation': null,
      };
    }

    final totalResults = history.fold<int>(0, (sum, e) => sum + e.resultsCount);
    final averageResults = totalResults / history.length;

    // Trouver la localisation la plus recherchée
    final locationCounts = <String, int>{};
    for (final entry in history) {
      final loc = entry.locationName ?? 'Inconnue';
      locationCounts[loc] = (locationCounts[loc] ?? 0) + 1;
    }

    String? mostSearched;
    int maxCount = 0;
    locationCounts.forEach((location, count) {
      if (count > maxCount) {
        maxCount = count;
        mostSearched = location;
      }
    });

    return {
      'totalSearches': history.length,
      'averageResults': averageResults,
      'mostSearchedLocation': mostSearched,
    };
  }
}
