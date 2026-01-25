import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/firebase_api_service.dart';
import 'package:iwantsun/data/models/activity_model.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/core/constants/api_constants.dart';

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
  final FirebaseApiService _firebaseApi;
  final CacheService _cacheService;
  final AppLogger _logger;

  ActivityRemoteDataSourceImpl({
    FirebaseApiService? firebaseApi,
    CacheService? cacheService,
    AppLogger? logger,
  })  : _firebaseApi = firebaseApi ?? FirebaseApiService(),
        _cacheService = cacheService ?? CacheService(),
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

    // Appeler Firebase pour récupérer les activités
    try {
      _logger.info('Fetching activities from Firebase');
      final activities = await _firebaseApi.searchActivities(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        activityTypes: activityTypes,
      );

      // Mettre en cache les résultats
      if (activities.isNotEmpty) {
        try {
          await _cacheService.put(
            cacheKey,
            activities.map((a) => a.toJson()).toList(),
            CacheService.activityCacheBox,
          );
          _logger.info('Cached ${activities.length} activities');
        } catch (e) {
          _logger.warning('Failed to cache activities', e);
        }
      }

      return activities;
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch activities from Firebase', e, stackTrace);
      rethrow;
    }
  }
}
