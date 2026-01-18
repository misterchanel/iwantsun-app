import 'package:cloud_functions/cloud_functions.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/weather.dart';

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
          timeout: const Duration(seconds: 60),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'centerLatitude': params.centerLatitude,
        'centerLongitude': params.centerLongitude,
        'searchRadius': params.searchRadius,
        'startDate': _formatDate(params.startDate),
        'endDate': _formatDate(params.endDate),
        'desiredMinTemperature': params.desiredMinTemperature,
        'desiredMaxTemperature': params.desiredMaxTemperature,
        'desiredConditions': params.desiredConditions,
        'timeSlots': params.timeSlots.map((slot) => slot.name).toList(),
      });

      final data = response.data;

      if (data['error'] != null) {
        _logger.error('Firebase function error: ${data['error']}');
        throw Exception(data['error']);
      }

      final resultsJson = data['results'] as List<dynamic>;
      _logger.info('Received ${resultsJson.length} results from Firebase');

      return resultsJson.map((json) => _parseSearchResult(json)).toList();
    } catch (e, stackTrace) {
      _logger.error('Firebase search error', e, stackTrace);
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  SearchResult _parseSearchResult(Map<String, dynamic> json) {
    final locationJson = json['location'] as Map<String, dynamic>;
    final weatherJson = json['weatherForecast'] as Map<String, dynamic>;
    final forecastsJson = weatherJson['forecasts'] as List<dynamic>;

    return SearchResult(
      location: Location(
        id: locationJson['id'] as String,
        name: locationJson['name'] as String,
        country: locationJson['country'] as String?,
        latitude: (locationJson['latitude'] as num).toDouble(),
        longitude: (locationJson['longitude'] as num).toDouble(),
        distanceFromCenter: (locationJson['distance'] as num?)?.toDouble(),
      ),
      weatherForecast: WeatherForecast(
        locationId: weatherJson['locationId'] as String,
        forecasts: forecastsJson.map((f) => _parseWeather(f)).toList(),
        averageTemperature: (weatherJson['averageTemperature'] as num).toDouble(),
        weatherScore: (weatherJson['weatherScore'] as num).toDouble(),
      ),
      overallScore: (json['overallScore'] as num).toDouble(),
    );
  }

  Weather _parseWeather(Map<String, dynamic> json) {
    final hourlyJson = json['hourlyData'] as List<dynamic>? ?? [];

    return Weather(
      date: DateTime.parse(json['date'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      minTemperature: (json['minTemperature'] as num).toDouble(),
      maxTemperature: (json['maxTemperature'] as num).toDouble(),
      condition: json['condition'] as String,
      hourlyData: hourlyJson.map((h) => HourlyWeather(
        hour: h['hour'] as int,
        temperature: (h['temperature'] as num).toDouble(),
        condition: h['condition'] as String,
      )).toList(),
    );
  }
}
