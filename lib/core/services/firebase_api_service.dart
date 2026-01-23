import 'package:cloud_functions/cloud_functions.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/data/models/location_model.dart';
import 'package:iwantsun/data/models/weather_model.dart';
import 'package:iwantsun/data/models/activity_model.dart';
import 'package:iwantsun/data/models/hotel_model.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/domain/entities/weather.dart';
import 'package:iwantsun/domain/entities/event.dart';
import 'package:iwantsun/domain/entities/search_params.dart';

/// Service unifié pour appeler toutes les Firebase Functions remplaçant les APIs directes
class FirebaseApiService {
  static final FirebaseApiService _instance = FirebaseApiService._internal();
  factory FirebaseApiService() => _instance;
  FirebaseApiService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final AppLogger _logger = AppLogger();

  /// Recherche de villes via Nominatim (géocodage)
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      _logger.info('Calling Firebase searchLocations function');

      final callable = _functions.httpsCallable(
        'searchLocations',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'query': query,
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        throw Exception(data['error']);
      }

      final locationsJson = data['locations'] as List<dynamic>?;
      if (locationsJson == null) {
        return [];
      }

      return locationsJson
          .map((json) => LocationModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Error calling searchLocations', e, stackTrace);
      rethrow;
    }
  }

  /// Géocodage inverse via Nominatim
  Future<LocationModel?> geocodeLocation(double latitude, double longitude) async {
    try {
      _logger.info('Calling Firebase geocodeLocation function');

      final callable = _functions.httpsCallable(
        'geocodeLocation',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final response = await callable.call({
        'latitude': latitude,
        'longitude': longitude,
      });

      // Convertir response.data en Map<String, dynamic> de manière sûre
      final rawData = response.data;
      final data = rawData is Map ? Map<String, dynamic>.from(rawData as Map) : <String, dynamic>{};
      _logger.debug('Firebase geocodeLocation response: ${data.toString()}');
      
      if (data['error'] != null) {
        _logger.warning('Firebase function error: ${data['error']}');
        // Ne pas retourner null immédiatement, vérifier si location existe quand même
      }

      final locationData = data['location'];
      final locationJson = locationData is Map 
          ? Map<String, dynamic>.from(locationData as Map)
          : null;
      
      if (locationJson == null) {
        _logger.warning('No location data returned from geocodeLocation for ($latitude, $longitude). Response was: $data');
        return null;
      }

      final location = LocationModel.fromJson(locationJson);
      _logger.info('Geocoded location received: ${location.name}, ${location.country}');
      
      // Vérifier si le nom est valide (pas juste des coordonnées)
      if (location.name.isEmpty || 
          (location.name.contains(',') && location.name.split(',').length == 2 && 
           location.name.replaceAll(' ', '').contains(RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$')))) {
        _logger.warning('Geocoded location name appears to be coordinates: ${location.name}');
        // On retourne quand même la location pour que l'utilisateur puisse voir les coordonnées
      }
      
      return location;
    } catch (e, stackTrace) {
      _logger.error('Error calling geocodeLocation', e, stackTrace);
      return null;
    }
  }

  /// Récupération des villes proches via Overpass
  Future<List<LocationModel>> getNearbyCities({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      _logger.info('Calling Firebase getNearbyCities function');

      final callable = _functions.httpsCallable(
        'getNearbyCities',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 45),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        throw Exception(data['error']);
      }

      final citiesJson = data['cities'] as List<dynamic>?;
      if (citiesJson == null) {
        return [];
      }

      return citiesJson
          .map((json) {
            final cityJson = Map<String, dynamic>.from(json as Map);
            return LocationModel(
              id: cityJson['id']?.toString() ?? '',
              name: cityJson['name']?.toString() ?? '',
              country: cityJson['country']?.toString(),
              latitude: (cityJson['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (cityJson['longitude'] as num?)?.toDouble() ?? 0.0,
              distanceFromCenter: (cityJson['distance'] as num?)?.toDouble(),
            );
          })
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Error calling getNearbyCities', e, stackTrace);
      rethrow;
    }
  }

  /// Récupération des prévisions météo via Open-Meteo
  Future<List<WeatherModel>> getWeatherForecast({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.info('Calling Firebase getWeatherForecast function');

      final callable = _functions.httpsCallable(
        'getWeatherForecast',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'latitude': latitude,
        'longitude': longitude,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        throw Exception(data['error']);
      }

      final forecastsJson = data['forecasts'] as List<dynamic>?;
      if (forecastsJson == null) {
        return [];
      }

      return forecastsJson.map((json) {
        final forecastJson = Map<String, dynamic>.from(json as Map);
        final hourlyData = (forecastJson['hourlyData'] as List<dynamic>?)
                ?.map((h) {
                  final hJson = Map<String, dynamic>.from(h as Map);
                  return HourlyWeather(
                    hour: (hJson['hour'] as num?)?.toInt() ?? 0,
                    temperature: (hJson['temperature'] as num?)?.toDouble() ?? 0.0,
                    condition: hJson['condition']?.toString() ?? 'clear',
                  );
                })
                .toList() ??
            [];

        return WeatherModel(
          date: DateTime.parse(forecastJson['date'] as String),
          temperature: (forecastJson['temperature'] as num?)?.toDouble() ?? 0.0,
          minTemperature: (forecastJson['minTemperature'] as num?)?.toDouble() ?? 0.0,
          maxTemperature: (forecastJson['maxTemperature'] as num?)?.toDouble() ?? 0.0,
          condition: forecastJson['condition']?.toString() ?? 'clear',
          hourlyData: hourlyData,
        );
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Error calling getWeatherForecast', e, stackTrace);
      rethrow;
    }
  }

  /// Récupération des activités via Overpass
  /// NOTE: Cette fonction n'est plus utilisée dans l'application.
  /// La fonctionnalité activités permet de sélectionner les types d'activités souhaitées dans l'UI,
  /// mais les activités ne sont jamais récupérées depuis l'API pour être affichées.
  /// ActivityRepository est configuré mais jamais appelé dans l'UI.
  /// Cette méthode peut être réactivée si nécessaire dans le futur.
  /*
  Future<List<ActivityModel>> getActivities({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<ActivityType> activityTypes,
  }) async {
    try {
      _logger.info('Calling Firebase getActivities function');

      final callable = _functions.httpsCallable(
        'getActivities',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 45),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'activityTypes': activityTypes.map((type) => type.name).toList(),
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        throw Exception(data['error']);
      }

      final activitiesJson = data['activities'] as List<dynamic>?;
      if (activitiesJson == null) {
        return [];
      }

      return activitiesJson.map((json) {
        final activityJson = Map<String, dynamic>.from(json as Map);
        final typeStr = activityJson['type']?.toString() ?? '';
        ActivityType type;
        try {
          type = ActivityType.values.firstWhere((e) => e.name == typeStr);
        } catch (e) {
          type = ActivityType.other;
        }

        return ActivityModel(
          type: type,
          name: activityJson['name']?.toString() ?? '',
          description: activityJson['description']?.toString(),
          latitude: (activityJson['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (activityJson['longitude'] as num?)?.toDouble() ?? 0.0,
          distanceFromLocation: (activityJson['distanceFromLocation'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Error calling getActivities', e, stackTrace);
      rethrow;
    }
  }
  */

  /// Récupération des hôtels via Overpass
  /// NOTE: Cette fonction n'est plus utilisée dans l'application.
  /// La fonctionnalité hôtels a été supprimée du flux principal de recherche.
  /// Cette méthode peut être réactivée si nécessaire dans le futur.
  /*
  Future<List<HotelModel>> getHotels({
    required String locationId,
    required double latitude,
    required double longitude,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      _logger.info('Calling Firebase getHotels function');

      final callable = _functions.httpsCallable(
        'getHotels',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 45),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'locationId': locationId,
        'latitude': latitude,
        'longitude': longitude,
        'checkIn': _formatDate(checkIn),
        'checkOut': _formatDate(checkOut),
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        return [];
      }

      final hotelsJson = data['hotels'] as List<dynamic>?;
      if (hotelsJson == null) {
        return [];
      }

      return hotelsJson.map((json) {
        final hotelJson = Map<String, dynamic>.from(json as Map);
        return HotelModel.fromJson(hotelJson);
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Error calling getHotels', e, stackTrace);
      return [];
    }
  }
  */

  /// Géolocalisation par IP via ipapi.co
  Future<Map<String, dynamic>?> getIpLocation() async {
    try {
      _logger.info('Calling Firebase getIpLocation function');

      final callable = _functions.httpsCallable(
        'getIpLocation',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 10),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({});

      final data = response.data;
      if (data['error'] != null) {
        _logger.warning('Firebase function error: ${data['error']}');
        return null;
      }

      final locationJson = data['location'] as Map<String, dynamic>?;
      return locationJson;
    } catch (e, stackTrace) {
      _logger.error('Error calling getIpLocation', e, stackTrace);
      return null;
    }
  }

  /// Calcule la température moyenne pour une localisation, période et créneaux horaires
  /// Retourne min et max (moyenne ± 5°C arrondie)
  Future<Map<String, double?>?> calculateAverageTemperature({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> timeSlots,
  }) async {
    try {
      _logger.info('Calling Firebase calculateAverageTemperature function');

      final callable = _functions.httpsCallable(
        'calculateAverageTemperature',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'latitude': latitude,
        'longitude': longitude,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
        'timeSlots': timeSlots,
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.warning('Firebase function error: ${data['error']}');
        return null;
      }

      final minTemp = data['minTemperature'] as num?;
      final maxTemp = data['maxTemperature'] as num?;
      final avgTemp = data['averageTemperature'] as num?;

      if (minTemp == null || maxTemp == null || avgTemp == null) {
        _logger.warning('No temperature data returned from calculateAverageTemperature');
        return null;
      }

      _logger.info('Average temperature calculated: ${avgTemp.toDouble()}°C (min: ${minTemp.toDouble()}°C, max: ${maxTemp.toDouble()}°C)');

      return {
        'minTemperature': minTemp.toDouble(),
        'maxTemperature': maxTemp.toDouble(),
        'averageTemperature': avgTemp.toDouble(),
      };
    } catch (e, stackTrace) {
      _logger.error('Error calling calculateAverageTemperature', e, stackTrace);
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Recherche d'événements
  Future<List<Event>> searchEvents(EventSearchParams params) async {
    try {
      _logger.info('Calling Firebase searchEvents function');

      final callable = _functions.httpsCallable(
        'searchEvents',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'centerLatitude': params.centerLatitude,
        'centerLongitude': params.centerLongitude,
        'searchRadius': params.searchRadius,
        'startDate': params.startDate.toIso8601String(),
        'endDate': params.endDate.toIso8601String(),
        'eventTypes': params.eventTypes.map((t) => t.name).toList(),
        'minPrice': params.minPrice,
        'maxPrice': params.maxPrice,
        'sortByPopularity': params.sortByPopularity,
      });

      final data = response.data;
      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        throw Exception(data['error']);
      }

      final eventsJson = data['events'] as List<dynamic>?;
      if (eventsJson == null) {
        return [];
      }

      return eventsJson.map((json) {
        final eventMap = Map<String, dynamic>.from(json as Map);
        return Event(
          id: eventMap['id'] as String,
          name: eventMap['name'] as String,
          description: eventMap['description'] as String?,
          type: EventType.values.firstWhere(
            (t) => t.name == eventMap['type'],
            orElse: () => EventType.other,
          ),
          latitude: (eventMap['latitude'] as num).toDouble(),
          longitude: (eventMap['longitude'] as num).toDouble(),
          startDate: DateTime.parse(eventMap['startDate'] as String),
          endDate: eventMap['endDate'] != null
              ? DateTime.parse(eventMap['endDate'] as String)
              : null,
          locationName: eventMap['locationName'] as String?,
          city: eventMap['city'] as String?,
          country: eventMap['country'] as String?,
          distanceFromCenter: (eventMap['distanceFromCenter'] as num?)?.toDouble(),
          imageUrl: eventMap['imageUrl'] as String?,
          websiteUrl: eventMap['websiteUrl'] as String?,
          price: (eventMap['price'] as num?)?.toDouble(),
          priceCurrency: eventMap['priceCurrency'] as String?,
        );
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Error calling searchEvents', e, stackTrace);
      rethrow;
    }
  }
}
