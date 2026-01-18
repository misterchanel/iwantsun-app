import 'dart:async';
import 'dart:math';
import 'package:iwantsun/core/utils/score_calculator.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/weather.dart';
import 'package:iwantsun/domain/repositories/activity_repository.dart';
import 'package:iwantsun/domain/repositories/location_repository.dart';
import 'package:iwantsun/domain/repositories/weather_repository.dart';

/// Use case pour rechercher des localités
class SearchLocationsUseCase {
  final LocationRepository _locationRepository;
  final WeatherRepository _weatherRepository;
  final ActivityRepository? _activityRepository;

  SearchLocationsUseCase({
    required LocationRepository locationRepository,
    required WeatherRepository weatherRepository,
    ActivityRepository? activityRepository,
  })  : _locationRepository = locationRepository,
        _weatherRepository = weatherRepository,
        _activityRepository = activityRepository;

  Future<List<SearchResult>> execute(SearchParams params) async {
    // 1. Récupérer les villes proches (ou utiliser la localisation centrale si échec)
    List<Location> locationsToSearch = [];
    try {
      final nearbyCities = await _locationRepository.getNearbyCities(
        latitude: params.centerLatitude,
        longitude: params.centerLongitude,
        radiusKm: params.searchRadius,
      );
      locationsToSearch = nearbyCities;
    } catch (e) {
      // Si getNearbyCities échoue, utiliser la localisation centrale comme fallback
      final centerLocation = await _locationRepository.geocodeLocation(
        params.centerLatitude,
        params.centerLongitude,
      );
      if (centerLocation != null) {
        locationsToSearch = [centerLocation];
      }
    }

    // Si aucune localisation trouvée, utiliser la localisation centrale avec distance 0
    if (locationsToSearch.isEmpty) {
      final centerLocation = await _locationRepository.geocodeLocation(
        params.centerLatitude,
        params.centerLongitude,
      );
      if (centerLocation != null) {
        locationsToSearch = [centerLocation];
      } else {
        locationsToSearch = [
          Location(
            id: 'center',
            name: 'Localisation centrale',
            latitude: params.centerLatitude,
            longitude: params.centerLongitude,
            distanceFromCenter: 0.0,
          ),
        ];
      }
    } else {
      // Dédupliquer les localisations (par ID ou coordonnées proches)
      final uniqueLocations = <String, Location>{};
      for (final loc in locationsToSearch) {
        final key = loc.id.isNotEmpty ? loc.id : '${loc.latitude.toStringAsFixed(4)}_${loc.longitude.toStringAsFixed(4)}';
        if (!uniqueLocations.containsKey(key)) {
          uniqueLocations[key] = loc;
        } else {
          // Si on trouve la localisation centrale, s'assurer qu'elle a distance 0
          final existingLoc = uniqueLocations[key]!;
          if (existingLoc.latitude == params.centerLatitude && 
              existingLoc.longitude == params.centerLongitude) {
            uniqueLocations[key] = Location(
              id: existingLoc.id,
              name: existingLoc.name,
              country: existingLoc.country,
              latitude: existingLoc.latitude,
              longitude: existingLoc.longitude,
              distanceFromCenter: 0.0,
            );
          }
        }
      }
      locationsToSearch = uniqueLocations.values.toList();
      
      // S'assurer que la localisation centrale a distance 0 si elle est présente
      for (int i = 0; i < locationsToSearch.length; i++) {
        final loc = locationsToSearch[i];
        if (loc.latitude == params.centerLatitude && 
            loc.longitude == params.centerLongitude) {
          locationsToSearch[i] = Location(
            id: loc.id,
            name: loc.name,
            country: loc.country,
            latitude: loc.latitude,
            longitude: loc.longitude,
            distanceFromCenter: 0.0,
          );
        }
      }
    }

    // 2. Pour chaque ville, récupérer les prévisions météo EN PARALLÈLE
    final locationsToProcess = locationsToSearch.take(50).toList();

    // Créer une liste de futures pour tous les appels API
    final futures = locationsToProcess.map((location) async {
      try {
        final weatherForecast = await _weatherRepository.getWeatherForecast(
          latitude: location.latitude,
          longitude: location.longitude,
          startDate: params.startDate,
          endDate: params.endDate,
        );

        // Ignorer les résultats sans prévisions valides
        if (weatherForecast.forecasts.isEmpty) {
          return null;
        }

        // Calculer le score météo avec les paramètres souhaités
        final weatherScore = _calculateWeatherScoreForParams(
          weatherForecast,
          params,
        );

        double? activityScore;

        // Si c'est une recherche avancée avec activités
        if (params is AdvancedSearchParams &&
            params.desiredActivities.isNotEmpty &&
            _activityRepository != null) {
          activityScore = await _calculateActivityScore(
            location: location,
            activityTypes: params.desiredActivities,
            radiusKm: 20.0, // Rayon pour chercher les activités
          );
        }

        // Score global
        final overallScore = activityScore != null
            ? (weatherScore * 0.7) + (activityScore * 0.3)
            : weatherScore;

        return SearchResult(
          location: location,
          weatherForecast: WeatherForecast(
            locationId: weatherForecast.locationId,
            forecasts: weatherForecast.forecasts,
            averageTemperature: weatherForecast.averageTemperature,
            weatherScore: weatherScore,
          ),
          activityScore: activityScore,
          overallScore: overallScore,
        );
      } catch (e) {
        // Retourner null en cas d'erreur pour cette ville
        return null;
      }
    }).toList();

    // Exécuter tous les appels en parallèle
    final resultsList = await Future.wait(futures);

    // Filtrer les résultats null (erreurs)
    var results = resultsList.whereType<SearchResult>().toList();

    // Filtrer par conditions météo si l'utilisateur a spécifié des conditions
    if (params.desiredConditions.isNotEmpty) {
      results = results.where((result) {
        return _matchesDesiredConditions(
          result.weatherForecast,
          params.desiredConditions,
        );
      }).toList();
    }

    // Trier par score global décroissant
    results.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return results;
  }

  /// Vérifie si la condition météo dominante correspond aux conditions souhaitées
  bool _matchesDesiredConditions(
    WeatherForecast forecast,
    List<String> desiredConditions,
  ) {
    if (forecast.forecasts.isEmpty) return false;

    // Compter les occurrences de chaque condition
    final conditionCounts = <String, int>{};
    for (final weather in forecast.forecasts) {
      final condition = weather.condition.toLowerCase();
      conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
    }

    // Trouver la condition dominante
    String dominantCondition = '';
    int maxCount = 0;
    for (final entry in conditionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominantCondition = entry.key;
      }
    }

    // Vérifier si la condition dominante correspond à une des conditions souhaitées
    for (final desired in desiredConditions) {
      if (_conditionsMatch(dominantCondition, desired.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Vérifie si deux conditions météo sont compatibles
  bool _conditionsMatch(String actual, String desired) {
    // Correspondance exacte
    if (actual == desired) return true;

    // Correspondances flexibles
    // "clear" correspond à "sunny" et vice versa
    if ((actual == 'clear' || actual == 'sunny') &&
        (desired == 'clear' || desired == 'sunny')) {
      return true;
    }

    // "partly_cloudy" correspond aussi si l'utilisateur cherche du soleil
    if (actual == 'partly_cloudy' && desired == 'clear') {
      return true;
    }

    return false;
  }

  double _calculateWeatherScoreForParams(
    WeatherForecast forecast,
    SearchParams params,
  ) {
    if (forecast.forecasts.isEmpty) return 0.0;

    // Calculer la stabilité météo réelle basée sur toutes les prévisions
    final allTemperatures = forecast.forecasts
        .expand((w) => [w.minTemperature, w.maxTemperature])
        .toList();
    final allConditions = forecast.forecasts
        .map((w) => w.condition)
        .toList();

    final weatherStability = ScoreCalculator.calculateWeatherStability(
      temperatures: allTemperatures,
      conditions: allConditions,
    );

    double totalScore = 0.0;
    for (final weather in forecast.forecasts) {
      double bestConditionScore = 0.0;

      // Si plusieurs conditions sont sélectionnées, prendre le meilleur score
      if (params.desiredConditions.isNotEmpty) {
        for (final desiredCondition in params.desiredConditions) {
          final score = ScoreCalculator.calculateWeatherScore(
            desiredMinTemp: params.desiredMinTemperature ?? 20.0,
            desiredMaxTemp: params.desiredMaxTemperature ?? 30.0,
            actualMinTemp: weather.minTemperature,
            actualMaxTemp: weather.maxTemperature,
            desiredCondition: desiredCondition,
            actualCondition: weather.condition,
            weatherStability: weatherStability, // Utiliser la stabilité calculée
          );
          bestConditionScore = max(bestConditionScore, score);
        }
      } else {
        // Aucune condition spécifiée, utiliser 'clear' par défaut
        bestConditionScore = ScoreCalculator.calculateWeatherScore(
          desiredMinTemp: params.desiredMinTemperature ?? 20.0,
          desiredMaxTemp: params.desiredMaxTemperature ?? 30.0,
          actualMinTemp: weather.minTemperature,
          actualMaxTemp: weather.maxTemperature,
          desiredCondition: 'clear',
          actualCondition: weather.condition,
          weatherStability: weatherStability, // Utiliser la stabilité calculée
        );
      }

      totalScore += bestConditionScore;
    }

    return totalScore / forecast.forecasts.length;
  }

  Future<double> _calculateActivityScore({
    required Location location,
    required List<ActivityType> activityTypes,
    required double radiusKm,
  }) async {
    if (_activityRepository == null) return 0.0;

    try {
      final activities = await _activityRepository!.getActivitiesNearLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: radiusKm,
        activityTypes: activityTypes,
      );

      return ScoreCalculator.calculateActivityScore(
        desiredActivities: activityTypes.map((e) => e.name).toList(),
        availableActivities: activities.map((e) => e.type.name).toList(),
      );
    } catch (e) {
      return 0.0;
    }
  }

  /// Version Stream pour affichage progressif des résultats
  /// Émet les résultats au fur et à mesure qu'ils sont calculés pour une meilleure UX
  Stream<SearchResult> executeStream(SearchParams params) async* {
    // 1. Récupérer les villes proches (identique à execute)
    List<Location> locationsToSearch = [];
    try {
      final nearbyCities = await _locationRepository.getNearbyCities(
        latitude: params.centerLatitude,
        longitude: params.centerLongitude,
        radiusKm: params.searchRadius,
      );
      locationsToSearch = nearbyCities;
    } catch (e) {
      final centerLocation = await _locationRepository.geocodeLocation(
        params.centerLatitude,
        params.centerLongitude,
      );
      if (centerLocation != null) {
        locationsToSearch = [centerLocation];
      }
    }

    if (locationsToSearch.isEmpty) {
      final centerLocation = await _locationRepository.geocodeLocation(
        params.centerLatitude,
        params.centerLongitude,
      );
      if (centerLocation != null) {
        locationsToSearch = [centerLocation];
      } else {
        locationsToSearch = [
          Location(
            id: 'center',
            name: 'Localisation centrale',
            latitude: params.centerLatitude,
            longitude: params.centerLongitude,
            distanceFromCenter: 0.0,
          ),
        ];
      }
    } else {
      // Dédupliquer (code identique à execute)
      final uniqueLocations = <String, Location>{};
      for (final loc in locationsToSearch) {
        final key = loc.id.isNotEmpty ? loc.id : '${loc.latitude.toStringAsFixed(4)}_${loc.longitude.toStringAsFixed(4)}';
        if (!uniqueLocations.containsKey(key)) {
          uniqueLocations[key] = loc;
        } else {
          final existingLoc = uniqueLocations[key]!;
          if (existingLoc.latitude == params.centerLatitude &&
              existingLoc.longitude == params.centerLongitude) {
            uniqueLocations[key] = Location(
              id: existingLoc.id,
              name: existingLoc.name,
              country: existingLoc.country,
              latitude: existingLoc.latitude,
              longitude: existingLoc.longitude,
              distanceFromCenter: 0.0,
            );
          }
        }
      }
      locationsToSearch = uniqueLocations.values.toList();

      for (int i = 0; i < locationsToSearch.length; i++) {
        final loc = locationsToSearch[i];
        if (loc.latitude == params.centerLatitude &&
            loc.longitude == params.centerLongitude) {
          locationsToSearch[i] = Location(
            id: loc.id,
            name: loc.name,
            country: loc.country,
            latitude: loc.latitude,
            longitude: loc.longitude,
            distanceFromCenter: 0.0,
          );
        }
      }
    }

    // 2. Traiter les villes EN PARALLÈLE mais émettre au fur et à mesure
    final locationsToProcess = locationsToSearch.take(50).toList();
    final futures = locationsToProcess.map((location) async {
      try {
        final weatherForecast = await _weatherRepository.getWeatherForecast(
          latitude: location.latitude,
          longitude: location.longitude,
          startDate: params.startDate,
          endDate: params.endDate,
        );

        // Ignorer les résultats sans prévisions valides
        if (weatherForecast.forecasts.isEmpty) {
          return null;
        }

        final weatherScore = _calculateWeatherScoreForParams(
          weatherForecast,
          params,
        );

        double? activityScore;
        if (params is AdvancedSearchParams &&
            params.desiredActivities.isNotEmpty &&
            _activityRepository != null) {
          activityScore = await _calculateActivityScore(
            location: location,
            activityTypes: params.desiredActivities,
            radiusKm: 20.0,
          );
        }

        final overallScore = activityScore != null
            ? (weatherScore * 0.7) + (activityScore * 0.3)
            : weatherScore;

        return SearchResult(
          location: location,
          weatherForecast: WeatherForecast(
            locationId: weatherForecast.locationId,
            forecasts: weatherForecast.forecasts,
            averageTemperature: weatherForecast.averageTemperature,
            weatherScore: weatherScore,
          ),
          activityScore: activityScore,
          overallScore: overallScore,
        );
      } catch (e) {
        return null;
      }
    }).toList();

    // Émettre les résultats au fur et à mesure qu'ils arrivent
    final results = <SearchResult>[];
    for (final future in futures) {
      final result = await future;
      if (result != null) {
        // Filtrer par conditions météo si spécifiées
        if (params.desiredConditions.isNotEmpty) {
          if (!_matchesDesiredConditions(
            result.weatherForecast,
            params.desiredConditions,
          )) {
            continue; // Ignorer ce résultat
          }
        }

        results.add(result);

        // Trier et émettre le résultat immédiatement
        results.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        yield result;
      }
    }
  }
}
