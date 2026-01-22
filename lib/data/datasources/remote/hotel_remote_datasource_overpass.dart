import 'package:iwantsun/data/models/hotel_model.dart';
import 'package:iwantsun/core/constants/api_constants.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';

/// Datasource pour récupérer les hôtels via Firebase Function (remplace Overpass)
/// NOTE: Cette fonctionnalité n'est plus utilisée dans l'application.
/// La Firebase Function getHotels a été désactivée car GetHotelsUseCase n'est jamais appelé.
/// Cette fonctionnalité peut être réactivée si nécessaire dans le futur.
class HotelRemoteDataSourceOverpass {
  final CacheService _cacheService;
  final AppLogger _logger;

  HotelRemoteDataSourceOverpass({
    CacheService? cacheService,
    AppLogger? logger,
  })  : _cacheService = cacheService ?? CacheService(),
        _logger = logger ?? AppLogger();

  Future<List<HotelModel>> getHotelsForLocation({
    required String locationId,
    required double latitude,
    required double longitude,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    // Créer une clé de cache unique
    final cacheKey = '${ApiConstants.hotelCachePrefix}${latitude}_$longitude';

    // Vérifier le cache d'abord
    try {
      final cached = await _cacheService.get<List<dynamic>>(
        cacheKey,
        CacheService.hotelCacheBox,
      );

      if (cached != null) {
        _logger.info('Hotels loaded from cache for location: $locationId');
        return cached
            .map((json) => HotelModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _logger.warning('Failed to load hotels from cache', e);
    }

    // NOTE: La fonctionnalité hôtels n'est plus utilisée dans l'application.
    // La Firebase Function getHotels a été désactivée car GetHotelsUseCase n'est jamais appelé.
    // Cette fonctionnalité peut être réactivée si nécessaire dans le futur.
    _logger.warning('getHotelsForLocation called but hotels feature is disabled');
    return [];
  }
}
