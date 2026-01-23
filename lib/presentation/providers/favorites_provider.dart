import 'package:flutter/material.dart';
import 'package:iwantsun/core/services/favorites_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';
import 'package:iwantsun/domain/entities/favorite.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/event_favorite.dart';
import 'package:iwantsun/domain/entities/event.dart';

/// Provider pour la gestion réactive des favoris et de l'historique
class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();
  final SearchHistoryService _historyService = SearchHistoryService();
  final GamificationService _gamificationService = GamificationService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // État des favoris
  List<Favorite> _favorites = [];
  bool _isLoadingFavorites = false;
  String? _favoritesError;

  // État des favoris d'événements
  List<EventFavorite> _eventFavorites = [];
  bool _isLoadingEventFavorites = false;
  String? _eventFavoritesError;

  // État de l'historique
  List<SearchHistoryEntry> _history = [];
  bool _isLoadingHistory = false;
  String? _historyError;

  // Statistiques
  Map<String, dynamic> _statistics = {};

  // Getters
  List<Favorite> get favorites => _favorites;
  bool get isLoadingFavorites => _isLoadingFavorites;
  String? get favoritesError => _favoritesError;
  int get favoritesCount => _favorites.length;

  // Getters pour événements
  List<EventFavorite> get eventFavorites => _eventFavorites;
  bool get isLoadingEventFavorites => _isLoadingEventFavorites;
  String? get eventFavoritesError => _eventFavoritesError;
  int get eventFavoritesCount => _eventFavorites.length;

  List<SearchHistoryEntry> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get historyError => _historyError;
  int get historyCount => _history.length;

  Map<String, dynamic> get statistics => _statistics;

  // Statistiques calculées
  double get averageScore {
    if (_favorites.isEmpty) return 0;
    return _favorites.fold(0.0, (sum, f) => sum + f.overallScore) / _favorites.length;
  }

  double get averageTemperature {
    if (_favorites.isEmpty) return 0;
    return _favorites.fold(0.0, (sum, f) => sum + f.averageTemperature) / _favorites.length;
  }

  int get totalSunnyDays {
    return _favorites.fold(0, (sum, f) => sum + f.sunnyDays);
  }

  Set<String> get uniqueCountries {
    return _favorites
        .where((f) => f.country != null)
        .map((f) => f.country!)
        .toSet();
  }

  /// Initialiser le provider
  Future<void> init() async {
    await Future.wait([
      loadFavorites(),
      loadEventFavorites(),
      loadHistory(),
      loadStatistics(),
    ]);
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadFavorites();
  }

  /// Rafraîchir les favoris d'événements
  Future<void> refreshEventFavorites() async {
    await loadEventFavorites();
  }

  /// Charger les favoris
  Future<void> loadFavorites() async {
    _isLoadingFavorites = true;
    _favoritesError = null;
    notifyListeners();

    try {
      _favorites = await _favoritesService.getFavorites();
    } catch (e) {
      _favoritesError = 'Impossible de charger les favoris';
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  /// Charger l'historique
  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      _history = await _historyService.getHistory();
    } catch (e) {
      _historyError = 'Impossible de charger l\'historique';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Charger les statistiques
  Future<void> loadStatistics() async {
    try {
      _statistics = await _historyService.getStatistics();
      notifyListeners();
    } catch (e) {
      // Ignorer silencieusement
    }
  }

  /// Ajouter un favori
  Future<bool> addFavorite(SearchResult result, {String? notes}) async {
    final success = await _favoritesService.addFavorite(result, notes: notes);

    if (success) {
      await loadFavorites();

      // Enregistrer dans la gamification
      try {
        await _gamificationService.recordFavoriteAdded();

        // Vérifier si c'est un nouveau pays
        final country = result.location.country;
        if (country != null && !uniqueCountries.contains(country)) {
          await _gamificationService.recordCountryExplored();
        }
      } catch (e) {
        // Ignorer les erreurs de gamification
      }

      // Tracker dans les analytics
      _analyticsService.trackFavoriteAdd(
        result.location.id,
        result.location.name,
      );
    }

    return success;
  }

  /// Retirer un favori
  Future<bool> removeFavorite(String favoriteId) async {
    // Sauvegarder pour undo potentiel
    final removedIndex = _favorites.indexWhere((f) => f.id == favoriteId);
    final removedFavorite = removedIndex >= 0 ? _favorites[removedIndex] : null;

    // Supprimer localement immédiatement pour UX fluide
    if (removedIndex >= 0) {
      _favorites.removeAt(removedIndex);
      notifyListeners();
    }

    final success = await _favoritesService.removeFavorite(favoriteId);

    if (!success && removedFavorite != null) {
      // Restaurer si échec
      _favorites.insert(removedIndex, removedFavorite);
      notifyListeners();
    }

    return success;
  }

  /// Vérifier si une destination est en favoris
  bool isFavorite(String locationId) {
    return _favorites.any((f) => f.id.startsWith(locationId));
  }

  /// Mettre à jour les notes d'un favori
  Future<bool> updateNotes(String favoriteId, String? notes) async {
    final success = await _favoritesService.updateNotes(favoriteId, notes);

    if (success) {
      final index = _favorites.indexWhere((f) => f.id == favoriteId);
      if (index >= 0) {
        _favorites[index] = _favorites[index].copyWith(notes: notes);
        notifyListeners();
      }
    }

    return success;
  }

  /// Vider tous les favoris
  Future<bool> clearAllFavorites() async {
    final success = await _favoritesService.clearAllFavorites();

    if (success) {
      _favorites = [];
      notifyListeners();
    }

    return success;
  }

  /// Exporter les favoris
  Future<String> exportFavorites() async {
    return await _favoritesService.exportFavorites();
  }

  /// Retirer une entrée de l'historique
  Future<bool> removeHistoryEntry(String entryId) async {
    final removedIndex = _history.indexWhere((h) => h.id == entryId);
    final removedEntry = removedIndex >= 0 ? _history[removedIndex] : null;

    if (removedIndex >= 0) {
      _history.removeAt(removedIndex);
      notifyListeners();
    }

    final success = await _historyService.removeEntry(entryId);

    if (!success && removedEntry != null) {
      _history.insert(removedIndex, removedEntry);
      notifyListeners();
    }

    return success;
  }

  /// Vider l'historique
  Future<bool> clearHistory() async {
    final success = await _historyService.clearHistory();

    if (success) {
      _history = [];
      notifyListeners();
    }

    return success;
  }

  /// Obtenir les recherches récentes
  List<SearchHistoryEntry> getRecentSearches({int limit = 5}) {
    return _history.take(limit).toList();
  }

  /// Trier les favoris
  void sortFavorites(FavoritesSortOption option) {
    switch (option) {
      case FavoritesSortOption.dateDesc:
        _favorites.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        break;
      case FavoritesSortOption.dateAsc:
        _favorites.sort((a, b) => a.savedAt.compareTo(b.savedAt));
        break;
      case FavoritesSortOption.scoreDesc:
        _favorites.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        break;
      case FavoritesSortOption.scoreAsc:
        _favorites.sort((a, b) => a.overallScore.compareTo(b.overallScore));
        break;
      case FavoritesSortOption.tempDesc:
        _favorites.sort((a, b) => b.averageTemperature.compareTo(a.averageTemperature));
        break;
      case FavoritesSortOption.tempAsc:
        _favorites.sort((a, b) => a.averageTemperature.compareTo(b.averageTemperature));
        break;
      case FavoritesSortOption.nameAsc:
        _favorites.sort((a, b) => a.locationName.compareTo(b.locationName));
        break;
      case FavoritesSortOption.nameDesc:
        _favorites.sort((a, b) => b.locationName.compareTo(a.locationName));
        break;
    }
    notifyListeners();
  }

  /// Filtrer les favoris par pays
  List<Favorite> filterByCountry(String? country) {
    if (country == null) return _favorites;
    return _favorites.where((f) => f.country == country).toList();
  }

  /// Filtrer par score minimum
  List<Favorite> filterByMinScore(double minScore) {
    return _favorites.where((f) => f.overallScore >= minScore).toList();
  }

  /// Filtrer par température
  List<Favorite> filterByTemperature(double minTemp, double maxTemp) {
    return _favorites.where((f) =>
        f.averageTemperature >= minTemp &&
        f.averageTemperature <= maxTemp
    ).toList();
  }

  // ========== GESTION DES FAVORIS D'ÉVÉNEMENTS ==========

  /// Charger les favoris d'événements
  Future<void> loadEventFavorites() async {
    _isLoadingEventFavorites = true;
    _eventFavoritesError = null;
    notifyListeners();

    try {
      _eventFavorites = await _favoritesService.getEventFavorites();
    } catch (e) {
      _eventFavoritesError = 'Impossible de charger les favoris d\'événements';
    } finally {
      _isLoadingEventFavorites = false;
      notifyListeners();
    }
  }

  /// Ajouter un événement aux favoris
  Future<bool> addEventFavorite(Event event, {String? notes}) async {
    final success = await _favoritesService.addEventFavorite(event, notes: notes);

    if (success) {
      await loadEventFavorites();

      // Tracker dans les analytics
      _analyticsService.trackFavoriteAdd(event.id, event.name);
    }

    return success;
  }

  /// Retirer un événement des favoris
  Future<bool> removeEventFavorite(String favoriteId) async {
    // Sauvegarder pour undo potentiel
    final removedIndex = _eventFavorites.indexWhere((f) => f.id == favoriteId);
    final removedFavorite = removedIndex >= 0 ? _eventFavorites[removedIndex] : null;

    // Supprimer localement immédiatement pour UX fluide
    if (removedIndex >= 0) {
      _eventFavorites.removeAt(removedIndex);
      notifyListeners();
    }

    final success = await _favoritesService.removeEventFavorite(favoriteId);

    if (!success && removedFavorite != null) {
      // Restaurer si échec
      _eventFavorites.insert(removedIndex, removedFavorite);
      notifyListeners();
    }

    return success;
  }

  /// Vérifier si un événement est en favoris
  bool isEventFavorite(String eventId) {
    return _eventFavorites.any((f) => f.eventId == eventId);
  }

  /// Mettre à jour les notes d'un favori d'événement
  Future<bool> updateEventFavoriteNotes(String favoriteId, String? notes) async {
    final success = await _favoritesService.updateEventFavoriteNotes(favoriteId, notes);

    if (success) {
      final index = _eventFavorites.indexWhere((f) => f.id == favoriteId);
      if (index >= 0) {
        _eventFavorites[index] = _eventFavorites[index].copyWith(notes: notes);
        notifyListeners();
      }
    }

    return success;
  }

  /// Vider tous les favoris d'événements
  Future<bool> clearAllEventFavorites() async {
    final success = await _favoritesService.clearAllEventFavorites();

    if (success) {
      _eventFavorites = [];
      notifyListeners();
    }

    return success;
  }

  /// Exporter les favoris d'événements
  Future<String> exportEventFavorites() async {
    return await _favoritesService.exportEventFavorites();
  }

  /// Trier les favoris d'événements
  void sortEventFavorites(EventFavoritesSortOption option) {
    switch (option) {
      case EventFavoritesSortOption.dateDesc:
        _eventFavorites.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        break;
      case EventFavoritesSortOption.dateAsc:
        _eventFavorites.sort((a, b) => a.savedAt.compareTo(b.savedAt));
        break;
      case EventFavoritesSortOption.startDateDesc:
        _eventFavorites.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case EventFavoritesSortOption.startDateAsc:
        _eventFavorites.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case EventFavoritesSortOption.nameAsc:
        _eventFavorites.sort((a, b) => a.eventName.compareTo(b.eventName));
        break;
      case EventFavoritesSortOption.nameDesc:
        _eventFavorites.sort((a, b) => b.eventName.compareTo(a.eventName));
        break;
      case EventFavoritesSortOption.typeAsc:
        _eventFavorites.sort((a, b) => a.eventType.name.compareTo(b.eventType.name));
        break;
      case EventFavoritesSortOption.typeDesc:
        _eventFavorites.sort((a, b) => b.eventType.name.compareTo(a.eventType.name));
        break;
    }
    notifyListeners();
  }

  /// Filtrer les favoris d'événements par type
  List<EventFavorite> filterEventFavoritesByType(EventType? type) {
    if (type == null) return _eventFavorites;
    return _eventFavorites.where((f) => f.eventType == type).toList();
  }

  /// Filtrer les favoris d'événements par pays
  List<EventFavorite> filterEventFavoritesByCountry(String? country) {
    if (country == null) return _eventFavorites;
    return _eventFavorites.where((f) => f.country == country).toList();
  }

  /// Obtenir les événements à venir
  List<EventFavorite> getUpcomingEventFavorites() {
    return _eventFavorites.where((f) => f.isUpcoming).toList();
  }

  /// Obtenir les événements en cours
  List<EventFavorite> getOngoingEventFavorites() {
    return _eventFavorites.where((f) => f.isOngoing).toList();
  }
}

/// Options de tri pour les favoris d'événements
enum EventFavoritesSortOption {
  dateDesc,
  dateAsc,
  startDateDesc,
  startDateAsc,
  nameAsc,
  nameDesc,
  typeAsc,
  typeDesc,
}

/// Extension pour obtenir le label de l'option de tri
extension EventFavoritesSortOptionExtension on EventFavoritesSortOption {
  String get label {
    switch (this) {
      case EventFavoritesSortOption.dateDesc:
        return 'Plus récent';
      case EventFavoritesSortOption.dateAsc:
        return 'Plus ancien';
      case EventFavoritesSortOption.startDateDesc:
        return 'Date événement (récent)';
      case EventFavoritesSortOption.startDateAsc:
        return 'Date événement (proche)';
      case EventFavoritesSortOption.nameAsc:
        return 'A → Z';
      case EventFavoritesSortOption.nameDesc:
        return 'Z → A';
      case EventFavoritesSortOption.typeAsc:
        return 'Type (A → Z)';
      case EventFavoritesSortOption.typeDesc:
        return 'Type (Z → A)';
    }
  }

  IconData get icon {
    switch (this) {
      case EventFavoritesSortOption.dateDesc:
      case EventFavoritesSortOption.dateAsc:
        return Icons.calendar_today;
      case EventFavoritesSortOption.startDateDesc:
      case EventFavoritesSortOption.startDateAsc:
        return Icons.event;
      case EventFavoritesSortOption.nameAsc:
      case EventFavoritesSortOption.nameDesc:
        return Icons.sort_by_alpha;
      case EventFavoritesSortOption.typeAsc:
      case EventFavoritesSortOption.typeDesc:
        return Icons.category;
    }
  }
}

/// Options de tri pour les favoris
enum FavoritesSortOption {
  dateDesc,
  dateAsc,
  scoreDesc,
  scoreAsc,
  tempDesc,
  tempAsc,
  nameAsc,
  nameDesc,
}

/// Extension pour obtenir le label de l'option de tri
extension FavoritesSortOptionExtension on FavoritesSortOption {
  String get label {
    switch (this) {
      case FavoritesSortOption.dateDesc:
        return 'Plus récent';
      case FavoritesSortOption.dateAsc:
        return 'Plus ancien';
      case FavoritesSortOption.scoreDesc:
        return 'Meilleur score';
      case FavoritesSortOption.scoreAsc:
        return 'Score croissant';
      case FavoritesSortOption.tempDesc:
        return 'Plus chaud';
      case FavoritesSortOption.tempAsc:
        return 'Plus frais';
      case FavoritesSortOption.nameAsc:
        return 'A → Z';
      case FavoritesSortOption.nameDesc:
        return 'Z → A';
    }
  }

  IconData get icon {
    switch (this) {
      case FavoritesSortOption.dateDesc:
      case FavoritesSortOption.dateAsc:
        return Icons.calendar_today;
      case FavoritesSortOption.scoreDesc:
      case FavoritesSortOption.scoreAsc:
        return Icons.star;
      case FavoritesSortOption.tempDesc:
      case FavoritesSortOption.tempAsc:
        return Icons.thermostat;
      case FavoritesSortOption.nameAsc:
      case FavoritesSortOption.nameDesc:
        return Icons.sort_by_alpha;
    }
  }
}
