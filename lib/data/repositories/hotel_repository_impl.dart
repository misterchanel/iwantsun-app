import 'package:iwantsun/core/constants/app_constants.dart';
import 'package:iwantsun/data/datasources/remote/hotel_remote_datasource.dart';
import 'package:iwantsun/domain/entities/hotel.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/repositories/hotel_repository.dart';

class HotelRepositoryImpl implements HotelRepository {
  final HotelRemoteDataSource _remoteDataSource;

  HotelRepositoryImpl({required HotelRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Hotel>> getHotelsForLocation({
    required Location location,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final models = await _remoteDataSource.getHotelsForLocation(
      locationId: location.id,
      latitude: location.latitude,
      longitude: location.longitude,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    final hotels = models.map((model) => model.toEntity()).toList();

    // Ajouter les liens d'affiliation si manquants
    return hotels.map((hotel) {
      if (hotel.affiliateUrl.isEmpty) {
        // Générer un lien d'affiliation basique (à remplacer par une vraie API)
        final affiliateUrl = _generateAffiliateUrl(
          location: location,
          checkIn: checkIn,
          checkOut: checkOut,
        );
        return Hotel(
          id: hotel.id,
          name: hotel.name,
          locationId: hotel.locationId,
          address: hotel.address,
          latitude: hotel.latitude,
          longitude: hotel.longitude,
          pricePerNight: hotel.pricePerNight,
          currency: hotel.currency,
          rating: hotel.rating,
          reviewCount: hotel.reviewCount,
          imageUrl: hotel.imageUrl,
          description: hotel.description,
          amenities: hotel.amenities,
          affiliateUrl: affiliateUrl,
          checkInDate: checkIn,
          checkOutDate: checkOut,
        );
      }
      return hotel;
    }).toList();
  }

  String _generateAffiliateUrl({
    required Location location,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    // URL d'exemple pour Booking.com (à remplacer par la vraie API)
    final checkInStr = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
    final checkOutStr = '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}';
    
    return 'https://www.booking.com/searchresults.html'
        '?ss=${Uri.encodeComponent(location.name)}'
        '&checkin=$checkInStr'
        '&checkout=$checkOutStr'
        '&aid=${AppConstants.affiliateId}';
  }
}
