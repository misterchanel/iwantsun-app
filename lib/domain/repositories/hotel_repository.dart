import 'package:iwantsun/domain/entities/hotel.dart';
import 'package:iwantsun/domain/entities/location.dart';

/// Repository interface pour les hôtels
abstract class HotelRepository {
  Future<List<Hotel>> getHotelsForLocation({
    required Location location,
    required DateTime checkIn,
    required DateTime checkOut,
  });
}
