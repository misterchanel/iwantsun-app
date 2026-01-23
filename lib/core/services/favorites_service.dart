import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/favorite.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/event_favorite.dart';
import 'package:iwantsun/domain/entities/event.dart';

/// Service pour gérer les destinations favorites
class FavoritesService {
  static const String _favoritesBoxName = 'favorites';
  static const String _favoritesKey = 'user_favorites';
  static const String _eventFavoritesKey = 'user_event_favorites';

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

  /// Réajouter un favori (pour undo) - Point 19
  Future<bool> addFavoriteFromFavorite(Favorite favorite) async {
    try {
      final favorites = await getFavorites();
      
      // Vérifier si déjà présent
      if (favorites.any((f) => f.id == favorite.id)) {
        _logger.info('Favorite already exists: ${favorite.locationName}');
        return false;
      }

      // Créer un nouveau favori avec la date actuelle
      final newFavorite = favorite.copyWith(
        id: '${favorite.locationName}_${DateTime.now().millisecondsSinceEpoch}',
        savedAt: DateTime.now(),
      );

      favorites.insert(0, newFavorite); // Ajouter en première position

      await _saveFavorites(favorites);
      _logger.info('Re-added favorite: ${newFavorite.locationName}');
      return true;
    } catch (e) {
      _logger.error('Failed to re-add favorite', e);
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

  // ========== GESTION DES FAVORIS D'ÉVÉNEMENTS ==========

  /// Récupérer tous les favoris d'événements
  Future<List<EventFavorite>> getEventFavorites() async {
    try {
      final data = await _cacheService.get<List<dynamic>>(
        _eventFavoritesKey,
        _favoritesBoxName,
      );

      if (data == null) {
        return [];
      }

      final favorites = data
          .map((json) {
            final map = json as Map<String, dynamic>;
            // Vérifier le type pour ne garder que les événements
            if (map['type'] == 'event') {
              return EventFavorite.fromJson(map);
            }
            return null;
          })
          .whereType<EventFavorite>()
          .toList();

      // Trier par date de sauvegarde (plus récent en premier)
      favorites.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      _logger.debug('Loaded ${favorites.length} event favorites');
      return favorites;
    } catch (e) {
      _logger.error('Failed to load event favorites', e);
      return [];
    }
  }

  /// Ajouter un événement aux favoris
  Future<bool> addEventFavorite(Event event, {String? notes}) async {
    try {
      // Vérifier si déjà en favoris
      if (await isEventFavorite(event.id)) {
        _logger.info('Event already in favorites: ${event.name}');
        return false;
      }

      final favorite = EventFavorite.fromEvent(event, notes: notes);
      final favorites = await getEventFavorites();

      favorites.insert(0, favorite); // Ajouter en première position

      await _saveEventFavorites(favorites);
      _logger.info('Added event favorite: ${favorite.eventName}');
      return true;
    } catch (e) {
      _logger.error('Failed to add event favorite', e);
      return false;
    }
  }

  /// Retirer un événement des favoris
  Future<bool> removeEventFavorite(String favoriteId) async {
    try {
      final favorites = await getEventFavorites();
      final initialLength = favorites.length;

      favorites.removeWhere((f) => f.id == favoriteId);

      if (favorites.length == initialLength) {
        _logger.warning('Event favorite not found: $favoriteId');
        return false;
      }

      await _saveEventFavorites(favorites);
      _logger.info('Removed event favorite: $favoriteId');
      return true;
    } catch (e) {
      _logger.error('Failed to remove event favorite', e);
      return false;
    }
  }

  /// Retirer par event ID
  Future<bool> removeEventFavoriteByEventId(String eventId) async {
    try {
      final favorites = await getEventFavorites();
      final toRemove = favorites.where((f) => f.eventId == eventId).toList();

      if (toRemove.isEmpty) {
        return false;
      }

      for (final fav in toRemove) {
        favorites.removeWhere((f) => f.id == fav.id);
      }

      await _saveEventFavorites(favorites);
      _logger.info('Removed ${toRemove.length} event favorite(s) for event: $eventId');
      return true;
    } catch (e) {
      _logger.error('Failed to remove event favorite by event ID', e);
      return false;
    }
  }

  /// Vérifier si un événement est en favoris
  Future<bool> isEventFavorite(String eventId) async {
    try {
      final favorites = await getEventFavorites();
      return favorites.any((f) => f.eventId == eventId);
    } catch (e) {
      _logger.error('Failed to check if event favorite', e);
      return false;
    }
  }

  /// Mettre à jour les notes d'un favori d'événement
  Future<bool> updateEventFavoriteNotes(String favoriteId, String? notes) async {
    try {
      final favorites = await getEventFavorites();
      final index = favorites.indexWhere((f) => f.id == favoriteId);

      if (index == -1) {
        _logger.warning('Event favorite not found: $favoriteId');
        return false;
      }

      favorites[index] = favorites[index].copyWith(notes: notes);
      await _saveEventFavorites(favorites);
      _logger.info('Updated notes for event favorite: $favoriteId');
      return true;
    } catch (e) {
      _logger.error('Failed to update event favorite notes', e);
      return false;
    }
  }

  /// Obtenir le nombre de favoris d'événements
  Future<int> getEventFavoritesCount() async {
    final favorites = await getEventFavorites();
    return favorites.length;
  }

  /// Vider tous les favoris d'événements
  Future<bool> clearAllEventFavorites() async {
    try {
      await _saveEventFavorites([]);
      _logger.info('Cleared all event favorites');
      return true;
    } catch (e) {
      _logger.error('Failed to clear event favorites', e);
      return false;
    }
  }

  /// Sauvegarder la liste des favoris d'événements
  Future<void> _saveEventFavorites(List<EventFavorite> favorites) async {
    final data = favorites.map((f) => f.toJson()).toList();
    await _cacheService.put(
      _eventFavoritesKey,
      data,
      _favoritesBoxName,
    );
  }

  /// Exporter les favoris d'événements
  Future<String> exportEventFavorites() async {
    final favorites = await getEventFavorites();
    final buffer = StringBuffer();

    buffer.writeln('Mes événements favoris - IWantSun\n');

    for (final fav in favorites) {
      buffer.writeln('🎭 ${fav.eventName}');
      buffer.writeln('   Type: ${fav.eventType.displayName}');
      buffer.writeln('   Date: ${fav.dateDisplay}');
      if (fav.locationName != null || fav.city != null) {
        buffer.writeln('   📍 ${fav.locationName ?? fav.city ?? ''}${fav.country != null ? ', ${fav.country}' : ''}');
      }
      if (fav.price != null) {
        buffer.writeln('   Prix: ${fav.price!.toStringAsFixed(2)} ${fav.priceCurrency ?? 'EUR'}');
      }
      if (fav.notes != null && fav.notes!.isNotEmpty) {
        buffer.writeln('   Notes: ${fav.notes}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
