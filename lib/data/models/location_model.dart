import 'package:iwantsun/domain/entities/location.dart';

/// Modèle de données pour Location (sérialisation JSON)
class LocationModel extends Location {
  const LocationModel({
    required super.id,
    required super.name,
    super.country,
    required super.latitude,
    required super.longitude,
    super.distanceFromCenter,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Convertir lat/lon qui peuvent être des strings ou des doubles
    double parseCoordinate(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return LocationModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['display_name'] ?? '',
      country: json['country'] ?? json['address']?['country'],
      latitude: parseCoordinate(json['lat'] ?? json['latitude']),
      longitude: parseCoordinate(json['lon'] ?? json['longitude']),
      distanceFromCenter: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distanceFromCenter,
    };
  }

  Location toEntity() {
    return Location(
      id: id,
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
      distanceFromCenter: distanceFromCenter,
    );
  }
}
