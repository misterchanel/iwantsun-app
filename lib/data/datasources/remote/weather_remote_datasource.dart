import 'package:dio/dio.dart';
import 'package:iwantsun/core/constants/api_constants.dart';
import 'package:iwantsun/core/network/dio_client.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/rate_limiter_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/data/models/weather_model.dart';

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
  final Dio _dio;
  final CacheService _cacheService;
  final RateLimiterService _rateLimiter;
  final AppLogger _logger;

  WeatherRemoteDataSourceImpl({
    Dio? dio,
    CacheService? cacheService,
    RateLimiterService? rateLimiter,
    AppLogger? logger,
  })  : _dio = dio ?? DioClient().dio,
        _cacheService = cacheService ?? CacheService(),
        _rateLimiter = rateLimiter ?? RateLimiterService(),
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
            .map((json) => WeatherModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _logger.warning('Failed to load weather from cache', e);
    }

    try {
      // Vérifier le rate limiting pour Open-Meteo
      await _rateLimiter.checkRateLimit(
        'open_meteo',
        maxRequests: 10,
        duration: const Duration(seconds: 10),
      );

      // Utilisation d'Open-Meteo (gratuit, sans clé API)
      final url = ApiConstants.openMeteoBaseUrl;

      _logger.debug('Fetching weather forecast for lat: $latitude, lon: $longitude');

      final response = await _dio.get(
        '$url/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
          'daily': 'temperature_2m_max,temperature_2m_min,weathercode',
          'timezone': 'auto',
        },
        options: Options(
          headers: {
            'User-Agent': 'IWantSun/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final forecasts = _parseOpenMeteoResponse(response.data, startDate, endDate);

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
      } else {
        throw Exception('Erreur lors de la récupération des données météo');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch weather forecast', e, stackTrace);
      throw Exception('Erreur météo: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<WeatherModel> _parseOpenMeteoResponse(
    Map<String, dynamic> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    final daily = data['daily'] ?? {};
    final times = (daily['time'] as List?) ?? [];
    final tempsMax = (daily['temperature_2m_max'] as List?) ?? [];
    final tempsMin = (daily['temperature_2m_min'] as List?) ?? [];
    final weatherCodes = (daily['weathercode'] as List?) ?? [];

    final List<WeatherModel> forecasts = [];

    for (int i = 0; i < times.length && i < tempsMax.length; i++) {
      try {
        final dateStr = times[i].toString();
        final date = DateTime.parse(dateStr);

        // Vérifier que la date est dans la plage demandée
        if (date.isBefore(startDate.subtract(const Duration(days: 1))) ||
            date.isAfter(endDate.add(const Duration(days: 1)))) {
          continue;
        }

        // Ignorer les jours avec des données manquantes ou invalides
        final rawTempMax = tempsMax[i];
        final rawTempMin = tempsMin[i];
        if (rawTempMax == null || rawTempMin == null) {
          _logger.warning('Skipping day $dateStr: missing temperature data');
          continue;
        }

        final tempMax = rawTempMax.toDouble();
        final tempMin = rawTempMin.toDouble();

        // Vérifier que les températures sont dans une plage réaliste
        if (tempMax < -60 || tempMax > 60 || tempMin < -60 || tempMin > 60) {
          _logger.warning('Skipping day $dateStr: unrealistic temperature values (min=$tempMin, max=$tempMax)');
          continue;
        }

        final tempAvg = (tempMax + tempMin) / 2;
        final weatherCode = weatherCodes[i] ?? 0;

        forecasts.add(WeatherModel(
          date: date,
          temperature: tempAvg,
          minTemperature: tempMin,
          maxTemperature: tempMax,
          condition: _mapWeatherCode(weatherCode),
        ));
      } catch (e) {
        // Ignorer les erreurs de parsing individuelles
        continue;
      }
    }

    return forecasts;
  }

  String _mapWeatherCode(int code) {
    // Mapping WMO Weather interpretation codes (WW)
    if (code == 0) return 'clear';
    if (code >= 1 && code <= 3) return 'partly_cloudy';
    if (code >= 45 && code <= 48) return 'cloudy';
    if (code >= 51 && code <= 67) return 'rain';
    if (code >= 71 && code <= 77) return 'snow';
    if (code >= 80 && code <= 82) return 'rain';
    if (code >= 85 && code <= 86) return 'snow';
    if (code >= 95 && code <= 99) return 'rain';
    return 'cloudy';
  }
}
