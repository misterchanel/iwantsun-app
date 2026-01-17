import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Options de tri pour les résultats
enum SortOption {
  bestScore, // Meilleur score météo (par défaut)
  temperature, // Température décroissante (du plus chaud au moins chaud)
  weatherCondition, // Conditions météo (du mieux au pire)
  distance, // Distance croissante (du plus proche au plus loin)
}

/// Gamme de prix
enum PriceRange {
  budget, // € - Moins de 75€/nuit
  moderate, // €€ - 75-150€/nuit
  luxury, // €€€ - Plus de 150€/nuit
}

/// Type d'hébergement
enum AccommodationType {
  hotel,
  apartment,
  resort,
  hostel,
  bnb,
}

/// Filtres appliqués aux résultats de recherche
class ResultFilters extends Equatable {
  final SortOption sortBy;
  final Set<PriceRange> priceRanges;
  final double? minRating;
  final int? minActivities;
  final Set<AccommodationType> accommodationTypes;

  const ResultFilters({
    this.sortBy = SortOption.bestScore,
    this.priceRanges = const {},
    this.minRating,
    this.minActivities,
    this.accommodationTypes = const {},
  });

  /// Crée une copie avec des valeurs modifiées
  ResultFilters copyWith({
    SortOption? sortBy,
    Set<PriceRange>? priceRanges,
    double? minRating,
    int? minActivities,
    Set<AccommodationType>? accommodationTypes,
  }) {
    return ResultFilters(
      sortBy: sortBy ?? this.sortBy,
      priceRanges: priceRanges ?? this.priceRanges,
      minRating: minRating ?? this.minRating,
      minActivities: minActivities ?? this.minActivities,
      accommodationTypes: accommodationTypes ?? this.accommodationTypes,
    );
  }

  /// Réinitialise tous les filtres
  ResultFilters reset() {
    return const ResultFilters();
  }

  /// Compte le nombre de filtres actifs (hors tri)
  int get activeFiltersCount {
    int count = 0;
    if (priceRanges.isNotEmpty) count++;
    if (minRating != null) count++;
    if (minActivities != null) count++;
    if (accommodationTypes.isNotEmpty) count++;
    return count;
  }

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters => activeFiltersCount > 0;

  @override
  List<Object?> get props => [
        sortBy,
        priceRanges,
        minRating,
        minActivities,
        accommodationTypes,
      ];
}

/// Extensions pour les énumérations
extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.bestScore:
        return 'Score';
      case SortOption.temperature:
        return 'Température';
      case SortOption.weatherCondition:
        return 'Conditions météo';
      case SortOption.distance:
        return 'Distance';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.bestScore:
        return Icons.wb_sunny;
      case SortOption.temperature:
        return Icons.thermostat;
      case SortOption.weatherCondition:
        return Icons.cloud;
      case SortOption.distance:
        return Icons.near_me;
    }
  }
}

extension PriceRangeExtension on PriceRange {
  String get label {
    switch (this) {
      case PriceRange.budget:
        return '€ Budget';
      case PriceRange.moderate:
        return '€€ Modéré';
      case PriceRange.luxury:
        return '€€€ Luxe';
    }
  }

  String get symbol {
    switch (this) {
      case PriceRange.budget:
        return '€';
      case PriceRange.moderate:
        return '€€';
      case PriceRange.luxury:
        return '€€€';
    }
  }

  double get minPrice {
    switch (this) {
      case PriceRange.budget:
        return 0;
      case PriceRange.moderate:
        return 75;
      case PriceRange.luxury:
        return 150;
    }
  }

  double get maxPrice {
    switch (this) {
      case PriceRange.budget:
        return 75;
      case PriceRange.moderate:
        return 150;
      case PriceRange.luxury:
        return double.infinity;
    }
  }

  bool includes(double price) {
    return price >= minPrice && price < maxPrice;
  }
}

extension AccommodationTypeExtension on AccommodationType {
  String get label {
    switch (this) {
      case AccommodationType.hotel:
        return 'Hôtel';
      case AccommodationType.apartment:
        return 'Appartement';
      case AccommodationType.resort:
        return 'Resort';
      case AccommodationType.hostel:
        return 'Auberge';
      case AccommodationType.bnb:
        return 'Chambre d\'hôtes';
    }
  }

  IconData get icon {
    switch (this) {
      case AccommodationType.hotel:
        return Icons.hotel;
      case AccommodationType.apartment:
        return Icons.apartment;
      case AccommodationType.resort:
        return Icons.pool;
      case AccommodationType.hostel:
        return Icons.bed;
      case AccommodationType.bnb:
        return Icons.house;
    }
  }
}
