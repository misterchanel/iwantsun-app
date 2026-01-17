import 'package:iwantsun/domain/entities/activity.dart';

/// Modèle de données pour Activity (sérialisation JSON)
class ActivityModel extends Activity {
  const ActivityModel({
    required super.type,
    required super.name,
    super.description,
    super.latitude,
    super.longitude,
    super.distanceFromLocation,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      type: _mapActivityType(json['type']?.toString() ?? ''),
      name: json['name'] ?? json['tags']?['name'] ?? '',
      description: json['description'] ?? json['tags']?['description'],
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lon'] ?? json['longitude'] ?? 0.0).toDouble(),
      distanceFromLocation: json['distance']?.toDouble(),
    );
  }

  static ActivityType _mapActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'beach':
      case 'leisure=beach_resort':
        return ActivityType.beach;
      case 'hiking':
      case 'tourism=hiking':
        return ActivityType.hiking;
      case 'skiing':
      case 'leisure=ski_resort':
        return ActivityType.skiing;
      case 'surfing':
      case 'leisure=surfing':
        return ActivityType.surfing;
      case 'cycling':
      case 'leisure=cycling':
        return ActivityType.cycling;
      case 'golf':
      case 'leisure=golf':
        return ActivityType.golf;
      case 'camping':
      case 'tourism=camp_site':
        return ActivityType.camping;
      default:
        return ActivityType.other;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distanceFromLocation,
    };
  }

  Activity toEntity() {
    return Activity(
      type: type,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      distanceFromLocation: distanceFromLocation,
    );
  }
}
