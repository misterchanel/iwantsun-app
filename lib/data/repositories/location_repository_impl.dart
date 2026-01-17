import 'package:iwantsun/data/datasources/remote/location_remote_datasource.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _remoteDataSource;

  LocationRepositoryImpl({required LocationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Location>> searchLocations(String query) async {
    final models = await _remoteDataSource.searchLocations(query);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Location?> geocodeLocation(double latitude, double longitude) async {
    final model = await _remoteDataSource.geocodeLocation(latitude, longitude);
    return model?.toEntity();
  }

  @override
  Future<List<Location>> getNearbyCities({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final models = await _remoteDataSource.getNearbyCities(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    return models.map((model) => model.toEntity()).toList();
  }
}
