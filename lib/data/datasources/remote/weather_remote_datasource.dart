import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/firebase_api_service.dart';
import 'package:iwantsun/data/models/weather_model.dart';
import 'package:iwantsun/core/constants/api_constants.dart';

/// Datasource pour récupérer les données météo depuis les APIs
abstract class WeatherRemoteDataSource {
  Future<List<WeatherModel>> getWeatherForecast({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final FirebaseApiService _firebaseApi;
  final CacheService _cacheService;
  final AppLogger _logger;

  WeatherRemoteDataSourceImpl({
    FirebaseApiService? firebaseApi,
    CacheService? cacheService,
    AppLogger? logger,
  })  : _firebaseApi = firebaseApi ?? FirebaseApiService(),
        _cacheService = cacheService ?? CacheService(),
        _logger = logger ?? AppLogger();

  @override
  Future<List<WeatherModel>> getWeatherForecast({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Créer une clé de cache unique
    final cacheKey = '${ApiConstants.weatherCachePrefix}${latitude}_${longitude}_'
        '${startDate.toIso8601String()}_${endDate.toIso8601String()}';

    // Vérifier le cache d'abord
    try {
      final cached = await _cacheService.get<List<dynamic>>(
        cacheKey,
        CacheService.weatherCacheBox,
      );

      if (cached != null) {
        _logger.info('Weather forecast loaded from cache');
        return cached
            .map((json) => WeatherModel.fromJsonSimple(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _logger.warning('Failed to load weather from cache', e);
    }

    try {
      _logger.debug('Fetching weather forecast for lat: $latitude, lon: $longitude via Firebase');

      // Appel via Firebase Function au lieu d'Open-Meteo directement
      final forecasts = await _firebaseApi.getWeatherForecast(
        latitude: latitude,
        longitude: longitude,
        startDate: startDate,
        endDate: endDate,
      );

      // Mettre en cache les résultats
      try {
        await _cacheService.put(
          cacheKey,
          forecasts.map((f) => f.toJson()).toList(),
          CacheService.weatherCacheBox,
        );
      } catch (e) {
        _logger.warning('Failed to cache weather forecast', e);
      }

      _logger.info('Successfully fetched ${forecasts.length} weather forecasts');
      return forecasts;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch weather forecast', e, stackTrace);
      throw Exception('Erreur météo: $e');
    }
  }

}
