import 'package:flutter/foundation.dart';
import 'package:iwantsun/domain/entities/result_filters.dart';
import 'package:iwantsun/domain/entities/search_result.dart';

/// Provider pour gérer les filtres et le tri des résultats
class ResultFilterProvider extends ChangeNotifier {
  ResultFilters _filters = const ResultFilters();
  List<SearchResult>? _originalResults;
  List<SearchResult>? _filteredResults;

  ResultFilters get filters => _filters;
  List<SearchResult>? get filteredResults => _filteredResults;
  bool get hasFilters => _filters.hasActiveFilters;
  int get activeFiltersCount => _filters.activeFiltersCount;

  /// Définit les résultats originaux à filtrer
  void setResults(List<SearchResult> results) {
    _originalResults = results;
    _applyFilters();
  }

  /// Change l'option de tri
  void setSortOption(SortOption sortOption) {
    _filters = _filters.copyWith(sortBy: sortOption);
    _applyFilters();
    notifyListeners();
  }

  /// Toggle une gamme de prix
  void togglePriceRange(PriceRange priceRange) {
    final newPriceRanges = Set<PriceRange>.from(_filters.priceRanges);
    if (newPriceRanges.contains(priceRange)) {
      newPriceRanges.remove(priceRange);
    } else {
      newPriceRanges.add(priceRange);
    }
    _filters = _filters.copyWith(priceRanges: newPriceRanges);
    _applyFilters();
    notifyListeners();
  }

  /// Définit la note minimum
  void setMinRating(double? rating) {
    _filters = _filters.copyWith(minRating: rating);
    _applyFilters();
    notifyListeners();
  }

  /// Définit la distance maximum
  void setMaxDistance(double? distance) {
    _filters = _filters.copyWith(maxDistance: distance);
    _applyFilters();
    notifyListeners();
  }

  /// Définit le nombre d'activités minimum
  void setMinActivities(int? activities) {
    _filters = _filters.copyWith(minActivities: activities);
    _applyFilters();
    notifyListeners();
  }

  /// Toggle un type d'hébergement
  void toggleAccommodationType(AccommodationType type) {
    final newTypes = Set<AccommodationType>.from(_filters.accommodationTypes);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    _filters = _filters.copyWith(accommodationTypes: newTypes);
    _applyFilters();
    notifyListeners();
  }

  /// Réinitialise tous les filtres
  void resetFilters() {
    _filters = _filters.reset();
    _applyFilters();
    notifyListeners();
  }

  /// Applique les filtres et le tri aux résultats
  void _applyFilters() {
    if (_originalResults == null) {
      _filteredResults = null;
      return;
    }

    List<SearchResult> results = List.from(_originalResults!);

    // Appliquer les filtres
    if (_filters.hasActiveFilters) {
      results = results.where((result) {
        // Filtre par prix (simulé car pas de données de prix actuellement)
        // Dans une vraie implémentation, vous récupéreriez le prix depuis les hôtels
        if (_filters.priceRanges.isNotEmpty) {
          // TODO: Filtrer par prix réel des hôtels
          // Pour l'instant, on accepte tous les résultats
        }

        // Filtre par note (simulé)
        if (_filters.minRating != null) {
          // TODO: Filtrer par note réelle des hôtels
        }

        // Filtre par distance
        if (_filters.maxDistance != null) {
          if (result.location.distanceFromCenter != null &&
              result.location.distanceFromCenter! > _filters.maxDistance!) {
            return false;
          }
        }

        // Filtre par nombre d'activités (simulé)
        if (_filters.minActivities != null) {
          // TODO: Filtrer par nombre réel d'activités
          // Pour l'instant, on accepte tous les résultats
        }

        // Filtre par type d'hébergement (simulé)
        if (_filters.accommodationTypes.isNotEmpty) {
          // TODO: Filtrer par type réel d'hébergement
        }

        return true;
      }).toList();
    }

    // Appliquer le tri
    results.sort((a, b) {
      switch (_filters.sortBy) {
        case SortOption.bestScore:
          return b.overallScore.compareTo(a.overallScore);

        case SortOption.temperature:
          // Trier par température moyenne (du plus chaud au moins chaud)
          final tempA = a.weatherForecast.averageTemperature;
          final tempB = b.weatherForecast.averageTemperature;
          return tempB.compareTo(tempA);

        case SortOption.weatherCondition:
          // Trier par conditions météo (du mieux au pire)
          // clear > partly_cloudy > cloudy > rain > snow
          int conditionScore(String condition) {
            switch (condition.toLowerCase()) {
              case 'clear':
                return 5;
              case 'partly_cloudy':
                return 4;
              case 'cloudy':
                return 3;
              case 'rain':
                return 2;
              case 'snow':
                return 1;
              default:
                return 0;
            }
          }
          final condA = a.weatherForecast.forecasts.isNotEmpty
              ? conditionScore(a.weatherForecast.forecasts.first.condition)
              : 0;
          final condB = b.weatherForecast.forecasts.isNotEmpty
              ? conditionScore(b.weatherForecast.forecasts.first.condition)
              : 0;
          return condB.compareTo(condA);
      }
    });

    _filteredResults = results;
  }
}
