import 'package:iwantsun/domain/entities/hotel.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/repositories/hotel_repository.dart';

/// Use case pour récupérer les hôtels pour une localité
class GetHotelsUseCase {
  final HotelRepository _hotelRepository;

  GetHotelsUseCase({required HotelRepository hotelRepository})
      : _hotelRepository = hotelRepository;

  Future<List<Hotel>> execute({
    required Location location,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    return await _hotelRepository.getHotelsForLocation(
      location: location,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }
}
