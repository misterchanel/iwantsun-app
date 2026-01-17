/// Types d'activités extérieures disponibles
enum ActivityType {
  beach, // Plage / Baignade
  hiking, // Randonnée / Trekking
  skiing, // Ski / Sports d'hiver
  surfing, // Surf / Windsurf
  cycling, // Vélo / VTT
  golf,
  camping,
  other,
}

/// Entité représentant une activité extérieure
class Activity {
  final ActivityType type;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final double? distanceFromLocation; // en km

  const Activity({
    required this.type,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.distanceFromLocation,
  });

  /// Retourne le nom affichable de l'activité
  String get displayName {
    switch (type) {
      case ActivityType.beach:
        return 'Plage / Baignade';
      case ActivityType.hiking:
        return 'Randonnée / Trekking';
      case ActivityType.skiing:
        return 'Ski / Sports d\'hiver';
      case ActivityType.surfing:
        return 'Surf / Windsurf';
      case ActivityType.cycling:
        return 'Vélo / VTT';
      case ActivityType.golf:
        return 'Golf';
      case ActivityType.camping:
        return 'Camping';
      case ActivityType.other:
        return name;
    }
  }
}
