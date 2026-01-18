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
    // 1. Récupérer TOUTES les villes dans le rayon (triées par distance depuis le centre)
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

      // Trier par distance croissante (les plus proches en premier)
      // Cela garantit qu'on traite d'abord les villes les plus proches
      locationsToSearch.sort((a, b) {
        final distA = a.distanceFromCenter ?? double.infinity;
        final distB = b.distanceFromCenter ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    // 2. Traiter les villes par batch avec arrêt anticipé dès qu'on a 20 résultats compatibles
    // Le cache est géré automatiquement par le weather repository (TTL 24h)
    const int targetResults = 20;
    const int batchSize = 10; // Traiter 10 villes à la fois pour équilibrer performance et API calls
    final results = <SearchResult>[];

    for (int i = 0; i < locationsToSearch.length; i += batchSize) {
      // Si on a déjà assez de résultats, arrêter
      if (results.length >= targetResults) {
        break;
      }

      // Prendre le prochain batch de villes
      final batchEnd = (i + batchSize < locationsToSearch.length) 
          ? i + batchSize 
          : locationsToSearch.length;
      final batch = locationsToSearch.sublist(i, batchEnd);

      // Traiter ce batch en parallèle
      final batchFutures = batch.map((location) => _processLocation(location, params)).toList();
      final batchResults = await Future.wait(batchFutures);

      // Filtrer les résultats null et vérifier la compatibilité météo immédiatement
      for (final result in batchResults) {
        if (result == null) continue; // Ignorer les erreurs

        // Vérifier la compatibilité météo si des conditions sont spécifiées
        if (params.desiredConditions.isNotEmpty) {
          if (!_matchesDesiredConditions(result.weatherForecast, params.desiredConditions)) {
            continue; // Ville incompatible, l'oublier de la liste
          }
        }

        // Ville compatible : l'ajouter aux résultats
        results.add(result);

        // Arrêter si on a atteint le nombre cible
        if (results.length >= targetResults) {
          break;
        }
      }
    }

    // Trier par score global décroissant (meilleurs scores en premier)
    results.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    // Retourner au minimum les résultats trouvés (peut être moins de 20 si pas assez de villes compatibles)
    return results;
  }

  /// Traite une ville individuelle : récupère météo, calcule score, et retourne le résultat ou null
  Future<SearchResult?> _processLocation(Location location, SearchParams params) async {
    try {
      // Le cache est géré automatiquement par le repository (vérifie TTL 24h)
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

  /// Filtre les données horaires selon les créneaux sélectionnés et calcule les moyennes
  ({double avgTemp, double minTemp, double maxTemp, String condition}) _getFilteredWeatherData(
    Weather weather,
    Set<int> selectedHours,
  ) {
    // Si pas de données horaires ou tous les créneaux sélectionnés, utiliser les données journalières
    if (weather.hourlyData.isEmpty || selectedHours.length >= 24) {
      return (
        avgTemp: weather.temperature,
        minTemp: weather.minTemperature,
        maxTemp: weather.maxTemperature,
        condition: weather.condition,
      );
    }

    // Filtrer les données horaires selon les créneaux sélectionnés
    final filteredHourly = weather.hourlyData
        .where((h) => selectedHours.contains(h.hour))
        .toList();

    if (filteredHourly.isEmpty) {
      // Fallback aux données journalières si aucune donnée horaire ne correspond
      return (
        avgTemp: weather.temperature,
        minTemp: weather.minTemperature,
        maxTemp: weather.maxTemperature,
        condition: weather.condition,
      );
    }

    // Calculer les moyennes filtrées
    final temps = filteredHourly.map((h) => h.temperature).toList();
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);

    // Déterminer la condition dominante
    final conditionCounts = <String, int>{};
    for (final h in filteredHourly) {
      conditionCounts[h.condition] = (conditionCounts[h.condition] ?? 0) + 1;
    }
    String dominantCondition = weather.condition;
    int maxCount = 0;
    for (final entry in conditionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominantCondition = entry.key;
      }
    }

    return (
      avgTemp: avgTemp,
      minTemp: minTemp,
      maxTemp: maxTemp,
      condition: dominantCondition,
    );
  }

  double _calculateWeatherScoreForParams(
    WeatherForecast forecast,
    SearchParams params,
  ) {
    if (forecast.forecasts.isEmpty) return 0.0;

    // Récupérer les heures sélectionnées
    final selectedHours = params.selectedHours;

    // Calculer la stabilité météo basée sur les données filtrées
    final filteredData = forecast.forecasts
        .map((w) => _getFilteredWeatherData(w, selectedHours))
        .toList();

    final allTemperatures = filteredData
        .expand((d) => [d.minTemp, d.maxTemp])
        .toList();
    final allConditions = filteredData
        .map((d) => d.condition)
        .toList();

    final weatherStability = ScoreCalculator.calculateWeatherStability(
      temperatures: allTemperatures,
      conditions: allConditions,
    );

    double totalScore = 0.0;
    for (int i = 0; i < forecast.forecasts.length; i++) {
      final filtered = filteredData[i];
      double bestConditionScore = 0.0;

      // Si plusieurs conditions sont sélectionnées, prendre le meilleur score
      if (params.desiredConditions.isNotEmpty) {
        for (final desiredCondition in params.desiredConditions) {
          final score = ScoreCalculator.calculateWeatherScore(
            desiredMinTemp: params.desiredMinTemperature ?? 20.0,
            desiredMaxTemp: params.desiredMaxTemperature ?? 30.0,
            actualMinTemp: filtered.minTemp,
            actualMaxTemp: filtered.maxTemp,
            desiredCondition: desiredCondition,
            actualCondition: filtered.condition,
            weatherStability: weatherStability,
          );
          bestConditionScore = max(bestConditionScore, score);
        }
      } else {
        // Aucune condition spécifiée, utiliser 'clear' par défaut
        bestConditionScore = ScoreCalculator.calculateWeatherScore(
          desiredMinTemp: params.desiredMinTemperature ?? 20.0,
          desiredMaxTemp: params.desiredMaxTemperature ?? 30.0,
          actualMinTemp: filtered.minTemp,
          actualMaxTemp: filtered.maxTemp,
          desiredCondition: 'clear',
          actualCondition: filtered.condition,
          weatherStability: weatherStability,
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
