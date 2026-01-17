import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/favorite.dart';
import 'package:iwantsun/domain/entities/search_result.dart';

/// Service pour gérer les destinations favorites
class FavoritesService {
  static const String _favoritesBoxName = 'favorites';
  static const String _favoritesKey = 'user_favorites';

  final CacheService _cacheService;
  final AppLogger _logger;

  // Singleton
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;

  FavoritesService._internal()
      : _cacheService = CacheService(),
        _logger = AppLogger();

  /// Initialiser le service
  Future<void> init() async {
    try {
      await _cacheService.init();
      _logger.info('FavoritesService initialized');
    } catch (e) {
      _logger.error('Failed to initialize FavoritesService', e);
    }
  }

  /// Récupérer tous les favoris
  Future<List<Favorite>> getFavorites() async {
    try {
      final data = await _cacheService.get<List<dynamic>>(
        _favoritesKey,
        _favoritesBoxName,
      );

      if (data == null) {
        return [];
      }

      final favorites = data
          .map((json) => Favorite.fromJson(json as Map<String, dynamic>))
          .toList();

      // Trier par date de sauvegarde (plus récent en premier)
      favorites.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      _logger.debug('Loaded ${favorites.length} favorites');
      return favorites;
    } catch (e) {
      _logger.error('Failed to load favorites', e);
      return [];
    }
  }

  /// Ajouter une destination aux favoris
  Future<bool> addFavorite(SearchResult result, {String? notes}) async {
    try {
      // Vérifier si déjà en favoris
      if (await isFavorite(result.location.id)) {
        _logger.info('Location already in favorites: ${result.location.name}');
        return false;
      }

      final favorite = Favorite.fromSearchResult(result, notes: notes);
      final favorites = await getFavorites();

      favorites.insert(0, favorite); // Ajouter en première position

      await _saveFavorites(favorites);
      _logger.info('Added favorite: ${favorite.locationName}');
      return true;
    } catch (e) {
      _logger.error('Failed to add favorite', e);
      return false;
    }
  }

  /// Retirer une destination des favoris
  Future<bool> removeFavorite(String favoriteId) async {
    try {
      final favorites = await getFavorites();
      final initialLength = favorites.length;

      favorites.removeWhere((f) => f.id == favoriteId);

      if (favorites.length == initialLength) {
        _logger.warning('Favorite not found: $favoriteId');
        return false;
      }

      await _saveFavorites(favorites);
      _logger.info('Removed favorite: $favoriteId');
      return true;
    } catch (e) {
      _logger.error('Failed to remove favorite', e);
      return false;
    }
  }

  /// Retirer par location ID
  Future<bool> removeFavoriteByLocationId(String locationId) async {
    try {
      final favorites = await getFavorites();
      final toRemove = favorites.where((f) => f.id.startsWith(locationId)).toList();

      if (toRemove.isEmpty) {
        return false;
      }

      for (final fav in toRemove) {
        favorites.removeWhere((f) => f.id == fav.id);
      }

      await _saveFavorites(favorites);
      _logger.info('Removed ${toRemove.length} favorite(s) for location: $locationId');
      return true;
    } catch (e) {
      _logger.error('Failed to remove favorite by location ID', e);
      return false;
    }
  }

  /// Vérifier si une destination est en favoris
  Future<bool> isFavorite(String locationId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((f) => f.id.startsWith(locationId));
    } catch (e) {
      _logger.error('Failed to check if favorite', e);
      return false;
    }
  }

  /// Mettre à jour les notes d'un favori
  Future<bool> updateNotes(String favoriteId, String? notes) async {
    try {
      final favorites = await getFavorites();
      final index = favorites.indexWhere((f) => f.id == favoriteId);

      if (index == -1) {
        _logger.warning('Favorite not found: $favoriteId');
        return false;
      }

      favorites[index] = favorites[index].copyWith(notes: notes);
      await _saveFavorites(favorites);
      _logger.info('Updated notes for favorite: $favoriteId');
      return true;
    } catch (e) {
      _logger.error('Failed to update favorite notes', e);
      return false;
    }
  }

  /// Obtenir le nombre de favoris
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }

  /// Vider tous les favoris
  Future<bool> clearAllFavorites() async {
    try {
      await _saveFavorites([]);
      _logger.info('Cleared all favorites');
      return true;
    } catch (e) {
      _logger.error('Failed to clear favorites', e);
      return false;
    }
  }

  /// Sauvegarder la liste des favoris
  Future<void> _saveFavorites(List<Favorite> favorites) async {
    final data = favorites.map((f) => f.toJson()).toList();
    await _cacheService.put(
      _favoritesKey,
      data,
      _favoritesBoxName,
    );
  }

  /// Exporter les favoris (pour partage futur)
  Future<String> exportFavorites() async {
    final favorites = await getFavorites();
    final buffer = StringBuffer();

    buffer.writeln('Mes destinations favorites - IWantSun\n');

    for (final fav in favorites) {
      buffer.writeln('📍 ${fav.locationName}${fav.country != null ? ', ${fav.country}' : ''}');
      buffer.writeln('   Score: ${fav.overallScore.toInt()}% | Temp: ${fav.averageTemperature.toStringAsFixed(1)}°C');
      buffer.writeln('   ${fav.sunnyDays} jours ensoleillés');
      if (fav.notes != null && fav.notes!.isNotEmpty) {
        buffer.writeln('   Notes: ${fav.notes}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
