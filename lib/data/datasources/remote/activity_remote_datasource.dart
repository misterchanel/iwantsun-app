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

    // NOTE: La fonctionnalité activités n'est plus utilisée dans l'application.
    // Les types d'activités peuvent être sélectionnés dans l'UI (search_activity_screen.dart)
    // mais les activités ne sont jamais récupérées depuis l'API pour être affichées.
    // La Firebase Function getActivities a été désactivée car ActivityRepository n'est jamais appelé dans l'UI.
    // Cette fonctionnalité peut être réactivée si nécessaire dans le futur.
    _logger.warning('getActivitiesNearLocation called but activities feature is disabled');
    return [];
  }
}
