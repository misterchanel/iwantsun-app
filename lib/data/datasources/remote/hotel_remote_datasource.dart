import 'package:iwantsun/data/models/hotel_model.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'hotel_remote_datasource_overpass.dart';

/// Datasource pour récupérer les hôtels via OpenStreetMap (GRATUIT, SANS CLÉ API)
abstract class HotelRemoteDataSource {
  Future<List<HotelModel>> getHotelsForLocation({
    required String locationId,
    required double latitude,
    required double longitude,
    required DateTime checkIn,
    required DateTime checkOut,
  });
}

/// Implémentation utilisant Overpass API (OpenStreetMap) - GRATUIT et SANS CLÉ
class HotelRemoteDataSourceImpl implements HotelRemoteDataSource {
  final HotelRemoteDataSourceOverpass _overpassDataSource;

  HotelRemoteDataSourceImpl({
    HotelRemoteDataSourceOverpass? overpassDataSource,
  }) : _overpassDataSource = overpassDataSource ?? HotelRemoteDataSourceOverpass();

  @override
  Future<List<HotelModel>> getHotelsForLocation({
    required String locationId,
    required double latitude,
    required double longitude,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return _overpassDataSource.getHotelsForLocation(
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }
}
