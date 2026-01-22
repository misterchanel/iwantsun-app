import 'dart:math' as math;
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/firebase_api_service.dart';
import 'package:iwantsun/data/models/location_model.dart';

/// Datasource pour la géolocalisation et la recherche de villes
abstract class LocationRemoteDataSource {
  Future<List<LocationModel>> searchLocations(String query);
  Future<LocationModel?> geocodeLocation(double latitude, double longitude);
  Future<List<LocationModel>> getNearbyCities({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final FirebaseApiService _firebaseApi;
  final AppLogger _logger;
  final CacheService _cache;

  LocationRemoteDataSourceImpl({
    FirebaseApiService? firebaseApi,
    AppLogger? logger,
    CacheService? cache,
  })  : _firebaseApi = firebaseApi ?? FirebaseApiService(),
        _logger = logger ?? AppLogger(),
        _cache = cache ?? CacheService();

  /// Extrait le nom de ville/village depuis les données d'adresse Nominatim
  String? _extractCityName(Map<String, dynamic>? address) {
    if (address == null) return null;

    // Ordre de priorité pour trouver le nom de ville/village
    final cityKeys = [
      'city',
      'town',
      'village',
      'municipality',
      'hamlet',
      'locality',
      'suburb',
    ];

    for (final key in cityKeys) {
      final value = address[key]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Vérifie si le résultat Nominatim est une ville/village
  bool _isSettlement(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase();
    final classType = json['class']?.toString().toLowerCase();

    // Types acceptés pour les villes/villages
    final validTypes = [
      'city', 'town', 'village', 'hamlet', 'municipality',
      'administrative', 'suburb', 'locality'
    ];

    final validClasses = ['place', 'boundary'];

    return validTypes.contains(type) || validClasses.contains(classType);
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      _logger.debug('Searching locations for query: $query via Firebase');

      // Appel via Firebase Function au lieu de Nominatim directement
      final locations = await _firebaseApi.searchLocations(query);

      _logger.debug('Firebase returned ${locations.length} locations');
      return locations;
    } catch (e) {
      _logger.error('Error during location search', e);
      throw Exception('Erreur recherche localisation: $e');
    }
  }

  @override
  Future<LocationModel?> geocodeLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      _logger.debug('Geocoding location ($latitude, $longitude) via Firebase');

      // Appel via Firebase Function au lieu de Nominatim directement
      final location = await _firebaseApi.geocodeLocation(latitude, longitude);

      if (location != null) {
        _logger.debug('Geocoded location: ${location.name}, ${location.country}');
      }
      return location;
    } catch (e) {
      _logger.error('Error during geocoding', e);
      throw Exception('Erreur géocodage: $e');
    }
  }

  @override
  Future<List<LocationModel>> getNearbyCities({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      _logger.debug('Searching nearby cities within ${radiusKm}km of ($latitude, $longitude) via Firebase');

      // Créer une clé de cache unique basée sur les coordonnées et le rayon
      // Arrondir à 2 décimales pour avoir un cache partagé pour des recherches proches
      final cacheKey = 'overpass_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_${radiusKm.toInt()}';

      // Vérifier le cache avec TTL de 24h
      final cachedData = await _cache.get<List<dynamic>>(
        cacheKey,
        CacheService.locationCacheBox,
        customTtlHours: 24,
      );

      if (cachedData != null) {
        _logger.debug('Cache hit for nearby cities (24h TTL)');
        return cachedData
            .map((json) => LocationModel.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }

      _logger.debug('Cache miss, calling Firebase Function');

      // Appel via Firebase Function au lieu d'Overpass directement
      final cities = await _firebaseApi.getNearbyCities(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      _logger.debug('Firebase returned ${cities.length} cities');

      // Trier par distance (les plus proches en premier)
      cities.sort((a, b) {
        final distA = a.distanceFromCenter ?? double.infinity;
        final distB = b.distanceFromCenter ?? double.infinity;
        return distA.compareTo(distB);
      });

      // Mettre en cache les résultats pour 24h seulement si on a des villes
      if (cities.isNotEmpty) {
        final cacheData = cities.map((loc) => loc.toJson()).toList();
        await _cache.put(cacheKey, cacheData, CacheService.locationCacheBox);
        _logger.debug('Cached nearby cities results for 24h');
      }

      return cities;
    } catch (e, stackTrace) {
      _logger.error('Error fetching nearby cities from Firebase', e);
      _logger.debug('Stack trace', stackTrace);
      rethrow;
    }
  }

  /// Calcul de distance en km entre deux points (formule de Haversine)
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
