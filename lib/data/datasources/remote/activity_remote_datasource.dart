import 'package:dio/dio.dart';
import 'package:iwantsun/core/constants/api_constants.dart';
import 'package:iwantsun/core/network/dio_client.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/rate_limiter_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/data/models/activity_model.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'dart:math' as math;

/// Datasource pour récupérer les activités (points d'intérêt)
abstract class ActivityRemoteDataSource {
  Future<List<ActivityModel>> getActivitiesNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<ActivityType> activityTypes,
  });
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final Dio _dio;
  final CacheService _cacheService;
  final RateLimiterService _rateLimiter;
  final AppLogger _logger;

  ActivityRemoteDataSourceImpl({
    Dio? dio,
    CacheService? cacheService,
    RateLimiterService? rateLimiter,
    AppLogger? logger,
  })  : _dio = dio ?? DioClient().dio,
        _cacheService = cacheService ?? CacheService(),
        _rateLimiter = rateLimiter ?? RateLimiterService(),
        _logger = logger ?? AppLogger();

  @override
  Future<List<ActivityModel>> getActivitiesNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<ActivityType> activityTypes,
  }) async {
    // Créer une clé de cache unique
    final cacheKey = '${ApiConstants.activityCachePrefix}${latitude}_${longitude}_'
        '${radiusKm}_${activityTypes.map((e) => e.toString()).join("_")}';

    // Vérifier le cache d'abord
    try {
      final cached = await _cacheService.get<List<dynamic>>(
        cacheKey,
        CacheService.activityCacheBox,
      );

      if (cached != null) {
        _logger.info('Activities loaded from cache');
        return cached
            .map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _logger.warning('Failed to load activities from cache', e);
    }

    try {
      final radiusMeters = (radiusKm * 1000).toInt();
      final List<ActivityModel> allActivities = [];

      for (final activityType in activityTypes) {
        // Vérifier le rate limiting pour Overpass
        await _rateLimiter.checkRateLimit(
          'overpass_api',
          maxRequests: 1,
          duration: const Duration(seconds: 2),
        );

        final query = _buildOverpassQuery(activityType, latitude, longitude, radiusMeters);

        _logger.debug('Fetching activities for type: $activityType');

        final response = await _dio.post(
          ApiConstants.overpassBaseUrl,
          data: query,
          options: Options(
            headers: {
              'Content-Type': 'text/plain',
            },
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final elements = (data['elements'] as List?) ?? [];
          
          for (var element in elements) {
            if (element['type'] == 'node' && element['lat'] != null) {
              final lat = element['lat'].toDouble();
              final lon = element['lon'].toDouble();
              final tags = element['tags'] ?? {};
              final name = tags['name'] ?? '';
              
              if (name.isNotEmpty) {
                final distance = _calculateDistance(latitude, longitude, lat, lon);
                
                allActivities.add(ActivityModel(
                  type: activityType,
                  name: name,
                  description: tags['description']?.toString(),
                  latitude: lat,
                  longitude: lon,
                  distanceFromLocation: distance,
                ));
              }
            } else if (element['type'] == 'way' || element['type'] == 'relation') {
              // Pour les ways et relations, on peut utiliser le centre
              final tags = element['tags'] ?? {};
              final name = tags['name'] ?? '';
              
              if (name.isNotEmpty && element['center'] != null) {
                final center = element['center'];
                final lat = center['lat'].toDouble();
                final lon = center['lon'].toDouble();
                final distance = _calculateDistance(latitude, longitude, lat, lon);
                
                allActivities.add(ActivityModel(
                  type: activityType,
                  name: name,
                  description: tags['description']?.toString(),
                  latitude: lat,
                  longitude: lon,
                  distanceFromLocation: distance,
                ));
              }
            }
          }
        }
        
        // Respecter le rate limiting (1 seconde entre les requêtes)
        if (activityTypes.indexOf(activityType) < activityTypes.length - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // Trier par distance
      allActivities.sort((a, b) {
        final distA = a.distanceFromLocation ?? double.infinity;
        final distB = b.distanceFromLocation ?? double.infinity;
        return distA.compareTo(distB);
      });

      // Mettre en cache les résultats
      try {
        await _cacheService.put(
          cacheKey,
          allActivities.map((a) => a.toJson()).toList(),
          CacheService.activityCacheBox,
        );
      } catch (e) {
        _logger.warning('Failed to cache activities', e);
      }

      _logger.info('Successfully fetched ${allActivities.length} activities');
      return allActivities;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch activities', e, stackTrace);
      throw Exception('Erreur récupération activités: $e');
    }
  }

  String _buildOverpassQuery(
    ActivityType activityType,
    double latitude,
    double longitude,
    int radiusMeters,
  ) {
    final tags = _getOverpassTagsForActivity(activityType);
    final tagFilters = tags.map((tag) => 'node["$tag"](around:$radiusMeters,$latitude,$longitude);').join('\n');
    
    return '''
[out:json][timeout:25];
(
  $tagFilters
);
out body;
>;
out skel qt;
''';
  }

  List<String> _getOverpassTagsForActivity(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.beach:
        return ['leisure=beach_resort', 'natural=beach'];
      case ActivityType.hiking:
        return ['tourism=information', 'information=hiking'];
      case ActivityType.skiing:
        return ['leisure=ski_resort', 'sport=skiing'];
      case ActivityType.surfing:
        return ['sport=surfing', 'leisure=surfing'];
      case ActivityType.cycling:
        return ['sport=cycling', 'leisure=cycling'];
      case ActivityType.golf:
        return ['leisure=golf_course', 'sport=golf'];
      case ActivityType.camping:
        return ['tourism=camp_site', 'leisure=camping'];
      case ActivityType.other:
        return ['leisure'];
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
