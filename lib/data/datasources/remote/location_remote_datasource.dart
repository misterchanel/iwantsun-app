import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:iwantsun/core/constants/api_constants.dart';
import 'package:iwantsun/core/network/dio_client.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/cache_service.dart';
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
  final Dio _dio;
  final AppLogger _logger;
  final CacheService _cache;

  LocationRemoteDataSourceImpl({Dio? dio, AppLogger? logger, CacheService? cache})
      : _dio = dio ?? DioClient().dio,
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
      // Utilisation de Nominatim (OpenStreetMap) - gratuit
      _logger.debug('Searching locations for query: $query');

      final response = await _dio.get(
        '${ApiConstants.nominatimBaseUrl}/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 20, // Augmenté pour avoir plus de choix après filtrage
          'addressdetails': 1,
          'featuretype': 'settlement', // Limiter aux villes/villages
        },
        options: Options(
          headers: {
            'User-Agent': 'IWantSun/1.0', // Requis par Nominatim
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      _logger.debug('Nominatim response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        _logger.debug('Nominatim returned ${data.length} results');

        final locations = <LocationModel>[];
        final seenNames = <String>{};

        for (final json in data) {
          // Filtrer pour ne garder que les villes/villages
          if (!_isSettlement(json)) {
            _logger.debug('Filtered out non-settlement: ${json['display_name']}');
            continue;
          }

          final address = json['address'] as Map<String, dynamic>?;

          // Extraire le nom de ville depuis address (priorité) ou display_name
          String name = _extractCityName(address) ?? '';
          if (name.isEmpty) {
            // Fallback: utiliser la première partie du display_name
            final displayName = json['display_name']?.toString() ?? '';
            name = displayName.split(',').first.trim();
          }

          if (name.isEmpty) continue;

          // Éviter les doublons
          final nameKey = name.toLowerCase();
          if (seenNames.contains(nameKey)) continue;
          seenNames.add(nameKey);

          // Extraire le pays
          final country = address?['country']?.toString();

          locations.add(LocationModel.fromJson({
            'id': json['place_id']?.toString() ?? '',
            'name': name,
            'country': country,
            'lat': json['lat'],
            'lon': json['lon'],
          }));
        }

        _logger.debug('Filtered to ${locations.length} cities/villages');
        return locations.take(10).toList(); // Limiter à 10 résultats
      } else if (response.statusCode == 429) {
        // Rate limit
        _logger.warning('Nominatim rate limit exceeded');
        throw Exception('Trop de requêtes. Veuillez patienter quelques instants.');
      } else {
        _logger.warning('Nominatim returned status ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      _logger.error('DioException during location search', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('La requête a pris trop de temps. Vérifiez votre connexion Internet.');
      }
      throw Exception('Erreur recherche localisation: ${e.message}');
    } catch (e) {
      _logger.error('Unexpected error during location search', e);
      throw Exception('Erreur recherche localisation: $e');
    }
  }

  @override
  Future<LocationModel?> geocodeLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      // Reverse geocoding avec Nominatim
      final response = await _dio.get(
        '${ApiConstants.nominatimBaseUrl}/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'addressdetails': 1,
          'zoom': 10, // Niveau ville/village (10 = city, 14 = suburb, 18 = building)
        },
        options: Options(
          headers: {
            'User-Agent': 'IWantSun/1.0',
          },
          validateStatus: (status) {
            return status != null && status == 200;
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'] as Map<String, dynamic>?;

        // Extraire le nom de ville/village
        String name = _extractCityName(address) ?? '';
        if (name.isEmpty) {
          // Fallback: utiliser la première partie du display_name
          final displayName = data['display_name']?.toString() ?? '';
          name = displayName.split(',').first.trim();
        }

        // Extraire le pays
        final country = address?['country']?.toString();

        _logger.debug('Geocoded location: $name, $country');

        return LocationModel.fromJson({
          'id': data['place_id']?.toString() ?? '',
          'name': name,
          'country': country,
          'lat': latitude,
          'lon': longitude,
        });
      }
      return null;
    } catch (e) {
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
      _logger.debug('Searching nearby cities within ${radiusKm}km of ($latitude, $longitude)');

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
        _logger.debug('Cache hit for Overpass API query (24h TTL)');
        return cachedData
            .map((json) => LocationModel.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }

      _logger.debug('Cache miss, calling Overpass API');

      // Utilisation d'Overpass API avec bounding box pour une meilleure recherche
      final latDelta = radiusKm / 111.0; // Approximation : 1 degré de latitude ≈ 111 km
      final lonDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180));
      
      final bboxSouth = latitude - latDelta;
      final bboxNorth = latitude + latDelta;
      final bboxWest = longitude - lonDelta;
      final bboxEast = longitude + lonDelta;
      
      final query = '''
[out:json][timeout:30];
(
  node["place"="city"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  node["place"="town"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  node["place"="village"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  way["place"="city"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  way["place"="town"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  way["place"="village"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  relation["place"="city"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  relation["place"="town"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
  relation["place"="village"]($bboxSouth,$bboxWest,$bboxNorth,$bboxEast);
);
out center;
''';

      final response = await _dio.post(
        ApiConstants.overpassBaseUrl,
        data: query,
        options: Options(
          headers: {
            'Content-Type': 'text/plain',
          },
          receiveTimeout: const Duration(seconds: 35),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final elements = (data['elements'] as List?) ?? [];

        _logger.debug('Overpass API returned ${elements.length} elements');

        final locations = <LocationModel>[];
        for (var element in elements) {
          final tags = element['tags'] as Map<String, dynamic>?;
          if (tags == null) continue;

          // Vérifier que c'est bien une ville/village (strict)
          final place = tags['place']?.toString();
          if (place != 'city' && place != 'town' && place != 'village') continue;

          final name = tags['name']?.toString() ?? tags['name:fr']?.toString() ?? '';
          if (name.isEmpty) continue;

          // Récupérer les coordonnées
          double? lat, lon;
          if (element['type'] == 'node') {
            lat = element['lat']?.toDouble();
            lon = element['lon']?.toDouble();
          } else if (element['type'] == 'way' || element['type'] == 'relation') {
            final center = element['center'] as Map<String, dynamic>?;
            if (center != null) {
              lat = center['lat']?.toDouble();
              lon = center['lon']?.toDouble();
            }
          }

          if (lat == null || lon == null) continue;

          // Calculer la distance depuis le centre
          final distance = _calculateDistance(latitude, longitude, lat, lon);

          // Filtrer pour ne garder que les villes dans le rayon
          if (distance > radiusKm) continue;

          locations.add(LocationModel(
            id: element['id']?.toString() ?? '',
            name: name,
            country: tags['addr:country'] ?? tags['is_in:country'],
            latitude: lat,
            longitude: lon,
            distanceFromCenter: distance,
          ));
        }

        _logger.debug('Found ${locations.length} cities/villages within radius');

        // Trier par distance
        locations.sort((a, b) {
          final distA = a.distanceFromCenter ?? double.infinity;
          final distB = b.distanceFromCenter ?? double.infinity;
          return distA.compareTo(distB);
        });

        // Limite adaptative selon le rayon de recherche
        // Rayon plus grand = plus de villes potentiellement pertinentes
        final maxCities = radiusKm < 75
            ? 20  // Petit rayon: 20 villes suffisent
            : radiusKm < 150
                ? 30  // Rayon moyen: 30 villes
                : 50;  // Grand rayon: 50 villes pour plus de choix

        _logger.debug('Limiting to $maxCities cities for radius ${radiusKm}km');
        final result = locations.take(maxCities).toList();

        // Mettre en cache les résultats pour 24h seulement si on a des villes
        if (result.isNotEmpty) {
          final cacheData = result.map((loc) => loc.toJson()).toList();
          await _cache.put(cacheKey, cacheData, CacheService.locationCacheBox);
          _logger.debug('Cached Overpass API results for 24h');
        }

        return result;
      }

      _logger.warning('Overpass API returned status ${response.statusCode}');
      throw Exception('Erreur Overpass API: code ${response.statusCode}');
    } catch (e, stackTrace) {
      _logger.error('Error fetching nearby cities from Overpass API', e);
      _logger.debug('Stack trace', stackTrace);
      // Lever l'exception pour que le code appelant sache qu'il y a eu un problème
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
