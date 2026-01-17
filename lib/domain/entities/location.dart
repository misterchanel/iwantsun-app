/// Entité représentant une localité
class Location {
  final String id;
  final String name;
  final String? country;
  final double latitude;
  final double longitude;
  final double? distanceFromCenter; // en km

  const Location({
    required this.id,
    required this.name,
    this.country,
    required this.latitude,
    required this.longitude,
    this.distanceFromCenter,
  });
}
