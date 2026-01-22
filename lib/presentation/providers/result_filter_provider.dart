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
        // Filtre par prix - Désactivé car pas de données hôtels disponibles
        // Les filtres de prix seront masqués dans l'UI
        if (_filters.priceRanges.isNotEmpty) {
          // Pas de données de prix disponibles actuellement
          // On accepte tous les résultats
        }

        // Filtre par note - Désactivé car pas de données hôtels disponibles
        if (_filters.minRating != null) {
          // Pas de données de note disponibles actuellement
          // On accepte tous les résultats
        }

        // Filtre par nombre d'activités - IMPLÉMENTÉ
        if (_filters.minActivities != null) {
          final activityCount = result.activities?.length ?? 0;
          if (activityCount < _filters.minActivities!) {
            return false;
          }
        }

        // Filtre par type d'hébergement - Désactivé car pas de données hôtels disponibles
        if (_filters.accommodationTypes.isNotEmpty) {
          // Pas de données d'hébergement disponibles actuellement
          // On accepte tous les résultats
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
          // Trier par conditions météo (du mieux au pire) - AMÉLIORÉ
          // Utilise la condition dominante sur toute la période au lieu du premier jour
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
          
          // Calculer la condition dominante pour chaque résultat
          String getDominantCondition(List<dynamic> forecasts) {
            if (forecasts.isEmpty) return 'unknown';
            
            final conditionCounts = <String, int>{};
            for (final forecast in forecasts) {
              final condition = (forecast as dynamic).condition?.toString() ?? 'unknown';
              conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
            }
            
            // Retourner la condition la plus fréquente
            String dominant = 'unknown';
            int maxCount = 0;
            conditionCounts.forEach((condition, count) {
              if (count > maxCount) {
                maxCount = count;
                dominant = condition;
              }
            });
            
            return dominant;
          }
          
          final condA = conditionScore(getDominantCondition(a.weatherForecast.forecasts));
          final condB = conditionScore(getDominantCondition(b.weatherForecast.forecasts));
          return condB.compareTo(condA);

        case SortOption.distance:
          final distA = a.location.distanceFromCenter ?? double.infinity;
          final distB = b.location.distanceFromCenter ?? double.infinity;
          return distA.compareTo(distB);
      }
    });

    _filteredResults = results;
  }
}
