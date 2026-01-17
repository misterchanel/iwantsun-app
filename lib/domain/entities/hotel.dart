/// Entité représentant un hôtel
class Hotel {
  final String id;
  final String name;
  final String locationId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? pricePerNight;
  final String? currency;
  final double? rating;
  final int? reviewCount;
  final String? imageUrl;
  final String? description;
  final List<String>? amenities;
  final String affiliateUrl; // Lien d'affiliation
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  const Hotel({
    required this.id,
    required this.name,
    required this.locationId,
    this.address,
    this.latitude,
    this.longitude,
    this.pricePerNight,
    this.currency,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.description,
    this.amenities,
    required this.affiliateUrl,
    this.checkInDate,
    this.checkOutDate,
  });
}
