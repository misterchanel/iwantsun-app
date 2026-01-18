import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:iwantsun/data/models/hotel_model.dart';
import 'package:iwantsun/core/network/dio_client.dart';
import 'package:iwantsun/core/constants/api_constants.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/config/affiliate_config.dart';

/// Datasource pour récupérer les hôtels via Overpass API (OpenStreetMap) - GRATUIT et SANS CLÉ
class HotelRemoteDataSourceOverpass {
  final Dio _dio;
  final CacheService _cacheService;
  final AppLogger _logger;

  HotelRemoteDataSourceOverpass({
    Dio? dio,
    CacheService? cacheService,
    AppLogger? logger,
  })  : _dio = dio ?? DioClient().dio,
        _cacheService = cacheService ?? CacheService(),
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

    try {
      // Utiliser Overpass API pour rechercher les hôtels
      const radiusMeters = 10000; // 10 km de rayon
      
      final query = '''
[out:json][timeout:25];
(
  node["tourism"="hotel"](around:$radiusMeters,$latitude,$longitude);
  way["tourism"="hotel"](around:$radiusMeters,$latitude,$longitude);
  relation["tourism"="hotel"](around:$radiusMeters,$latitude,$longitude);
  node["tourism"="hostel"](around:$radiusMeters,$latitude,$longitude);
  way["tourism"="hostel"](around:$radiusMeters,$latitude,$longitude);
  node["tourism"="apartment"](around:$radiusMeters,$latitude,$longitude);
  way["tourism"="apartment"](around:$radiusMeters,$latitude,$longitude);
  node["tourism"="guest_house"](around:$radiusMeters,$latitude,$longitude);
  way["tourism"="guest_house"](around:$radiusMeters,$latitude,$longitude);
);
out body;
>;
out skel qt;
''';

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
        
        final hotels = <HotelModel>[];
        for (var element in elements) {
          if (element['tags'] == null) continue;
          
          final tags = element['tags'] as Map<String, dynamic>;
          final name = tags['name']?.toString() ?? tags['alt_name']?.toString();
          
          if (name == null || name.isEmpty) continue;
          
          // Récupérer les coordonnées
          double? lat, lon;
          if (element['type'] == 'node') {
            lat = element['lat']?.toDouble();
            lon = element['lon']?.toDouble();
          } else if (element['type'] == 'way' || element['type'] == 'relation') {
            // Pour les ways et relations, utiliser le centre ou le premier node
            final geometry = element['geometry'] as List?;
            if (geometry != null && geometry.isNotEmpty) {
              final firstPoint = geometry.first;
              lat = firstPoint['lat']?.toDouble();
              lon = firstPoint['lon']?.toDouble();
            } else {
              // Utiliser les coordonnées de la location si pas de geometry
              lat = latitude;
              lon = longitude;
            }
          }
          
          if (lat == null || lon == null) continue;
          
          // Construire l'adresse
          final addressParts = <String>[];
          if (tags['addr:street'] != null) addressParts.add(tags['addr:street'].toString());
          if (tags['addr:housenumber'] != null) addressParts.add(tags['addr:housenumber'].toString());
          if (tags['addr:postcode'] != null) addressParts.add(tags['addr:postcode'].toString());
          if (tags['addr:city'] != null) addressParts.add(tags['addr:city'].toString());
          final address = addressParts.isNotEmpty ? addressParts.join(', ') : null;
          
          // Générer un lien Booking.com avec affiliation
          final affiliateUrl = AffiliateConfig.generateBookingUrl(
            hotelName: name,
            city: tags['addr:city']?.toString(),
            checkIn: checkIn,
            checkOut: checkOut,
            latitude: lat,
            longitude: lon,
          );
          
          hotels.add(HotelModel(
            id: element['id']?.toString() ?? '',
            name: name,
            locationId: locationId,
            address: address,
            latitude: lat,
            longitude: lon,
            pricePerNight: null, // OpenStreetMap ne fournit pas de prix
            currency: 'EUR',
            rating: tags['stars'] != null ? double.tryParse(tags['stars'].toString()) : null,
            reviewCount: null,
            imageUrl: null,
            description: tags['description']?.toString(),
            amenities: tags['amenity'] != null ? [tags['amenity'].toString()] : null,
            affiliateUrl: affiliateUrl,
          ));
        }
        
        // Trier par distance
        hotels.sort((a, b) {
          final distA = _calculateDistance(latitude, longitude, a.latitude ?? latitude, a.longitude ?? longitude);
          final distB = _calculateDistance(latitude, longitude, b.latitude ?? latitude, b.longitude ?? longitude);
          return distA.compareTo(distB);
        });
        
        // Limiter à 20 résultats
        final limitedHotels = hotels.take(20).toList();
        
        // Mettre en cache les résultats
        try {
          await _cacheService.put(
            cacheKey,
            limitedHotels.map((h) => h.toJson()).toList(),
            CacheService.hotelCacheBox,
          );
        } catch (e) {
          _logger.warning('Failed to cache hotels', e);
        }
        
        _logger.info('Successfully fetched ${limitedHotels.length} hotels from OpenStreetMap for location: $locationId');
        return limitedHotels;
      }
      
      return [];
    } catch (e, stackTrace) {
      _logger.error('Error fetching hotels from Overpass API', e, stackTrace);
      return [];
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
