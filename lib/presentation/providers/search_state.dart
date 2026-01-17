import 'package:equatable/equatable.dart';
import 'package:iwantsun/core/error/failures.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/search_params.dart';

/// États possibles de la recherche
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// État initial (aucune recherche effectuée)
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// État de chargement avec contexte détaillé
class SearchLoading extends SearchState {
  final String? message;
  final int? currentStep;
  final int? totalSteps;
  final String? detailedInfo; // Information détaillée (ex: "127 villes analysées")
  final double? progress; // Progression en pourcentage (0.0 à 1.0)

  const SearchLoading({
    this.message,
    this.currentStep,
    this.totalSteps,
    this.detailedInfo,
    this.progress,
  });

  @override
  List<Object?> get props => [
        message,
        currentStep,
        totalSteps,
        detailedInfo,
        progress,
      ];

  /// Crée un état de chargement pour l'étape 1 (recherche de villes)
  factory SearchLoading.searchingCities({int? citiesFound}) {
    return SearchLoading(
      message: 'Recherche de destinations...',
      detailedInfo: citiesFound != null
          ? '🌍 Analyse de $citiesFound villes dans votre rayon de recherche'
          : '🌍 Recherche des villes à proximité...',
      currentStep: 1,
      totalSteps: 3,
      progress: 0.33,
    );
  }

  /// Crée un état de chargement pour l'étape 2 (vérification météo)
  factory SearchLoading.checkingWeather({int? locationsChecked, int? totalLocations}) {
    final progressDetail = locationsChecked != null && totalLocations != null
        ? '$locationsChecked/$totalLocations destinations'
        : 'Consultation en cours...';

    return SearchLoading(
      message: 'Vérification de la météo...',
      detailedInfo: '☀️ Consultation des prévisions sur 7 jours\n$progressDetail',
      currentStep: 2,
      totalSteps: 3,
      progress: locationsChecked != null && totalLocations != null && totalLocations > 0
          ? 0.33 + (0.34 * (locationsChecked / totalLocations))
          : 0.5,
    );
  }

  /// Crée un état de chargement pour l'étape 3 (recherche d'hôtels)
  factory SearchLoading.searchingHotels({int? hotelsFound}) {
    return SearchLoading(
      message: 'Recherche d\'hébergements...',
      detailedInfo: hotelsFound != null
          ? '🏨 $hotelsFound établissements trouvés'
          : '🏨 Recherche des meilleurs hébergements...',
      currentStep: 3,
      totalSteps: 3,
      progress: 0.80,
    );
  }

  /// Crée un état de chargement pour l'étape finale (finalisation)
  factory SearchLoading.finalizing() {
    return const SearchLoading(
      message: 'Finalisation...',
      detailedInfo: '✨ Préparation de vos résultats',
      currentStep: 3,
      totalSteps: 3,
      progress: 0.95,
    );
  }
}

/// État de succès avec résultats
class SearchSuccess extends SearchState {
  final List<SearchResult> results;
  final DateTime searchTimestamp;
  final SearchParams? searchParams; // Ajout des paramètres de recherche

  const SearchSuccess({
    required this.results,
    required this.searchTimestamp,
    this.searchParams,
  });

  @override
  List<Object?> get props => [results, searchTimestamp, searchParams];

  bool get hasResults => results.isNotEmpty;
}

/// État d'erreur
class SearchError extends SearchState {
  final Failure failure;
  final String message;

  const SearchError({
    required this.failure,
    required this.message,
  });

  @override
  List<Object?> get props => [failure, message];
}

/// État vide (aucun résultat trouvé)
class SearchEmpty extends SearchState {
  final String message;

  const SearchEmpty({
    this.message = 'Aucun résultat trouvé pour vos critères',
  });

  @override
  List<Object?> get props => [message];
}
