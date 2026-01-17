import 'package:iwantsun/domain/entities/hotel.dart';

/// Modèle de données pour Hotel (sérialisation JSON)
class HotelModel extends Hotel {
  const HotelModel({
    required super.id,
    required super.name,
    required super.locationId,
    super.address,
    super.latitude,
    super.longitude,
    super.pricePerNight,
    super.currency,
    super.rating,
    super.reviewCount,
    super.imageUrl,
    super.description,
    super.amenities,
    required super.affiliateUrl,
    super.checkInDate,
    super.checkOutDate,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      locationId: json['location_id'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      pricePerNight: json['price']?.toDouble() ?? json['price_per_night']?.toDouble(),
      currency: json['currency'] ?? 'EUR',
      rating: json['rating']?.toDouble(),
      reviewCount: json['review_count'] ?? json['reviews_count'],
      imageUrl: json['image_url'] ?? json['image'],
      description: json['description'],
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList(),
      affiliateUrl: json['affiliate_url'] ?? json['booking_url'] ?? '',
      checkInDate: json['check_in_date'] != null
          ? DateTime.parse(json['check_in_date'])
          : null,
      checkOutDate: json['check_out_date'] != null
          ? DateTime.parse(json['check_out_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location_id': locationId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_night': pricePerNight,
      'currency': currency,
      'rating': rating,
      'review_count': reviewCount,
      'image_url': imageUrl,
      'description': description,
      'amenities': amenities,
      'affiliate_url': affiliateUrl,
      'check_in_date': checkInDate?.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
    };
  }

  Hotel toEntity() {
    return Hotel(
      id: id,
      name: name,
      locationId: locationId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      pricePerNight: pricePerNight,
      currency: currency,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      description: description,
      amenities: amenities,
      affiliateUrl: affiliateUrl,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
    );
  }
}
