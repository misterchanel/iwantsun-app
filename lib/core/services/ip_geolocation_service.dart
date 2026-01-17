import 'package:dio/dio.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/network/dio_client.dart';

/// Résultat de la géolocalisation IP
class IpGeolocationResult {
  final double latitude;
  final double longitude;
  final String? city;
  final String? region;
  final String? country;
  final String? countryCode;

  const IpGeolocationResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.region,
    this.country,
    this.countryCode,
  });

  factory IpGeolocationResult.fromJson(Map<String, dynamic> json) {
    return IpGeolocationResult(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country_name'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'region': region,
      'country_name': country,
      'country_code': countryCode,
    };
  }

  String get displayName {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (region != null && region != city) parts.add(region!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }
}

/// Service de géolocalisation basée sur l'adresse IP
/// Fallback lorsque le GPS n'est pas disponible ou échoue
class IpGeolocationService {
  final Dio _dio;
  final CacheService _cache;
  final AppLogger _logger;

  // Singleton
  static final IpGeolocationService _instance = IpGeolocationService._internal();
  factory IpGeolocationService() => _instance;

  IpGeolocationService._internal()
      : _dio = DioClient().dio,
        _cache = CacheService(),
        _logger = AppLogger();

  /// Obtenir la localisation via l'IP
  /// Utilise l'API ipapi.co (gratuite, 30,000 requêtes/mois)
  Future<IpGeolocationResult?> getLocation() async {
    try {
      _logger.info('Attempting IP-based geolocation...');

      // Vérifier le cache d'abord (TTL: 24h car position IP change rarement)
      const cacheKey = 'ip_geolocation';
      final cached = await _cache.get<Map<dynamic, dynamic>>(
        cacheKey,
        CacheService.locationCacheBox,
        customTtlHours: 24,
      );

      if (cached != null) {
        _logger.debug('IP geolocation cache hit');
        return IpGeolocationResult.fromJson(
          Map<String, dynamic>.from(cached),
        );
      }

      // Appel API ipapi.co
      final response = await _dio.get(
        'https://ipapi.co/json/',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = IpGeolocationResult.fromJson(data);

        _logger.info('IP geolocation successful: ${result.displayName}');

        // Mettre en cache pour 24h
        await _cache.put(cacheKey, result.toJson(), CacheService.locationCacheBox);

        return result;
      } else if (response.statusCode == 429) {
        _logger.warning('IP geolocation rate limit exceeded');
        return null;
      } else {
        _logger.warning('IP geolocation failed with status ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _logger.error('DioException during IP geolocation', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _logger.warning('IP geolocation timeout');
      }
      return null;
    } catch (e, stackTrace) {
      _logger.error('Unexpected error during IP geolocation', e, stackTrace);
      return null;
    }
  }

  /// Obtenir la localisation avec retry
  /// Essaie plusieurs fois en cas d'échec temporaire
  Future<IpGeolocationResult?> getLocationWithRetry({int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _logger.debug('IP geolocation attempt $attempt/$maxRetries');

      final result = await getLocation();
      if (result != null) {
        return result;
      }

      // Attendre avant de réessayer (sauf dernière tentative)
      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    _logger.warning('IP geolocation failed after $maxRetries attempts');
    return null;
  }

  /// Valider si les coordonnées sont raisonnables
  bool validateCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0); // Coordonnées par défaut invalides
  }
}
