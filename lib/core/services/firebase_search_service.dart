import 'package:cloud_functions/cloud_functions.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/error/exceptions.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/weather.dart';
import 'package:iwantsun/domain/entities/activity.dart';

/// Service pour effectuer les recherches via Firebase Cloud Functions
class FirebaseSearchService {
  static final FirebaseSearchService _instance = FirebaseSearchService._internal();
  factory FirebaseSearchService() => _instance;
  FirebaseSearchService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final AppLogger _logger = AppLogger();

  /// Recherche des destinations via Cloud Function
  Future<List<SearchResult>> searchDestinations(SearchParams params) async {
    try {
      _logger.info('Calling Firebase searchDestinations function');

      final callable = _functions.httpsCallable(
        'searchDestinations',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120), // 2 minutes max (batch API très rapide)
        ),
      );

      final requestData = <String, dynamic>{
        'centerLatitude': params.centerLatitude,
        'centerLongitude': params.centerLongitude,
        'searchRadius': params.searchRadius,
        'startDate': _formatDate(params.startDate),
        'endDate': _formatDate(params.endDate),
        'desiredMinTemperature': params.desiredMinTemperature,
        'desiredMaxTemperature': params.desiredMaxTemperature,
        'desiredConditions': params.desiredConditions,
        'timeSlots': params.timeSlots.map((slot) => slot.name).toList(),
      };

      // Ajouter les activités si c'est une recherche avancée
      if (params is AdvancedSearchParams) {
        requestData['desiredActivities'] = (params as AdvancedSearchParams)
            .desiredActivities
            .map((a) => a.name)
            .toList();
      }

      final response = await callable.call<Map<String, dynamic>>(requestData);

      final data = response.data;

      if (data['error'] != null) {
        final errorMessage = (data['error'] as String?)?.toString() ?? 'Erreur inconnue';
        _logger.error('Firebase function error: $errorMessage');
        
        // Détecter les erreurs Overpass spécifiques
        if (errorMessage.contains('serveurs de données géographiques') || 
            errorMessage.contains('indisponibles') ||
            errorMessage.contains('Overpass')) {
          throw FirebaseSearchException(
            errorMessage,
            FirebaseErrorType.networkError, // Traiter comme erreur réseau
          );
        }
        
        // Si c'est une erreur explicite (pas de villes trouvées), la propager
        if (errorMessage.contains('Aucune ville trouvée')) {
          throw FirebaseSearchException(errorMessage, FirebaseErrorType.noResults);
        }
        throw FirebaseSearchException('Erreur lors de la recherche: $errorMessage', FirebaseErrorType.generic);
      }

      final resultsJson = data['results'] as List<dynamic>?;
      if (resultsJson == null) {
        _logger.warning('No results field in Firebase response');
        return [];
      }
      
      _logger.info('Received ${resultsJson.length} results from Firebase');
      
      if (resultsJson.isEmpty) {
        _logger.warning('No results returned from Firebase search');
      }

      final results = <SearchResult>[];
      int parsedCount = 0;
      for (int i = 0; i < resultsJson.length; i++) {
        try {
          final resultJson = resultsJson[i];
          if (resultJson == null) {
            _logger.warning('Result $i is null, skipping');
            continue;
          }
          
          final parsedResult = _parseSearchResult(_convertMap(resultJson));
          results.add(parsedResult);
          parsedCount++;
        } catch (e, stackTrace) {
          _logger.error('Error parsing result $i: $e', e, stackTrace);
          // Continue with other results
        }
      }
      
      _logger.info('Successfully parsed $parsedCount/${resultsJson.length} results');
      return results;
    } catch (e, stackTrace) {
      _logger.error('Firebase search error', e, stackTrace);
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convertit récursivement les Maps Firebase en Map<String, dynamic>
  Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(
        key.toString(),
        value is Map ? _convertMap(value) : (value is List ? _convertList(value) : value),
      ));
    }
    return {};
  }

  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) => item is Map ? _convertMap(item) : item).toList();
  }

  SearchResult _parseSearchResult(dynamic rawJson) {
    final json = _convertMap(rawJson);
    final locationJson = _convertMap(json['location'] ?? {});
    final weatherJson = _convertMap(json['weatherForecast'] ?? {});
    final forecastsJson = (weatherJson['forecasts'] as List<dynamic>?) ?? [];

    // Parser les activités si présentes
    List<Activity>? activities;
    if (json['activities'] != null) {
      try {
        final activitiesJson = json['activities'] as List<dynamic>?;
        if (activitiesJson != null && activitiesJson.isNotEmpty) {
          activities = activitiesJson.map((activityJson) {
            final activityMap = _convertMap(activityJson);
            final typeStr = (activityMap['type'] as String?)?.toString() ?? '';
            ActivityType type;
            try {
              type = ActivityType.values.firstWhere(
                (t) => t.name == typeStr,
                orElse: () => ActivityType.other,
              );
            } catch (e) {
              type = ActivityType.other;
            }
            
            // Obtenir le nom d'affichage depuis le type
            String displayName;
            switch (type) {
              case ActivityType.beach:
                displayName = 'Plage / Baignade';
                break;
              case ActivityType.hiking:
                displayName = 'Randonnée / Trekking';
                break;
              case ActivityType.skiing:
                displayName = 'Ski / Sports d\'hiver';
                break;
              case ActivityType.surfing:
                displayName = 'Surf / Windsurf';
                break;
              case ActivityType.cycling:
                displayName = 'Vélo / VTT';
                break;
              case ActivityType.golf:
                displayName = 'Golf';
                break;
              case ActivityType.camping:
                displayName = 'Camping';
                break;
              case ActivityType.other:
                displayName = (activityMap['name'] as String?)?.toString() ?? 'Autre';
                break;
            }
            
            return Activity(
              type: type,
              name: (activityMap['name'] as String?)?.toString() ?? displayName,
              description: activityMap['description'] as String?,
              latitude: (activityMap['latitude'] is num
                  ? (activityMap['latitude'] as num).toDouble()
                  : null),
              longitude: (activityMap['longitude'] is num
                  ? (activityMap['longitude'] as num).toDouble()
                  : null),
              distanceFromLocation: (activityMap['distanceFromLocation'] is num
                  ? (activityMap['distanceFromLocation'] as num).toDouble()
                  : null),
            );
          }).toList();
        }
      } catch (e) {
        _logger.warning('Error parsing activities: $e');
        activities = null;
      }
    }

    return SearchResult(
      location: Location(
        id: (locationJson['id'] as String?)?.toString() ?? '',
        name: (locationJson['name'] as String?)?.toString() ?? 'Inconnu',
        country: locationJson['country'] as String?,
        latitude: (locationJson['latitude'] is num 
            ? (locationJson['latitude'] as num).toDouble() 
            : 0.0),
        longitude: (locationJson['longitude'] is num 
            ? (locationJson['longitude'] as num).toDouble() 
            : 0.0),
        distanceFromCenter: (locationJson['distance'] as num?)?.toDouble(),
      ),
      weatherForecast: WeatherForecast(
        locationId: (weatherJson['locationId'] as String?)?.toString() ?? '',
        forecasts: forecastsJson.map((f) => _parseWeather(f)).toList(),
        averageTemperature: (weatherJson['averageTemperature'] is num 
            ? (weatherJson['averageTemperature'] as num).toDouble() 
            : 0.0),
        weatherScore: (weatherJson['weatherScore'] is num 
            ? (weatherJson['weatherScore'] as num).toDouble() 
            : 0.0),
      ),
      activityScore: (json['activityScore'] is num
          ? (json['activityScore'] as num).toDouble()
          : null),
      overallScore: (json['overallScore'] is num 
          ? (json['overallScore'] as num).toDouble() 
          : 0.0),
      activities: activities,
    );
  }

  Weather _parseWeather(Map<String, dynamic> json) {
    final hourlyJson = json['hourlyData'] as List<dynamic>? ?? [];

    // Validation de la date
    final dateStr = json['date'] as String?;
    if (dateStr == null) {
      throw FormatException('Date manquante dans les données météo');
    }
    
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      throw FormatException('Date invalide dans les données météo: $dateStr', e);
    }

    return Weather(
      date: date,
      temperature: (json['temperature'] is num 
          ? (json['temperature'] as num).toDouble() 
          : 0.0),
      minTemperature: (json['minTemperature'] is num 
          ? (json['minTemperature'] as num).toDouble() 
          : 0.0),
      maxTemperature: (json['maxTemperature'] is num 
          ? (json['maxTemperature'] as num).toDouble() 
          : 0.0),
      condition: (json['condition'] as String?)?.toString() ?? 'unknown',
      hourlyData: hourlyJson.map((h) {
        final hourValue = h['hour'];
        final hour = (hourValue is int 
            ? hourValue.clamp(0, 23) 
            : ((hourValue is num ? hourValue.toInt() : 0).clamp(0, 23)));
        
        return HourlyWeather(
          hour: hour,
          temperature: (h['temperature'] is num 
              ? (h['temperature'] as num).toDouble() 
              : 0.0),
          condition: (h['condition'] as String?)?.toString() ?? 'unknown',
        );
      }).toList(),
    );
  }
}
