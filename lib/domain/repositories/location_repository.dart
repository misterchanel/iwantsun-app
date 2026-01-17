import 'package:iwantsun/domain/entities/location.dart';

/// Repository interface pour la géolocalisation
abstract class LocationRepository {
  Future<List<Location>> searchLocations(String query);
  Future<Location?> geocodeLocation(double latitude, double longitude);
  Future<List<Location>> getNearbyCities({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}
