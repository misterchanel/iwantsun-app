import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/domain/entities/event.dart';

/// Créneaux horaires pour l'analyse météo
enum TimeSlot {
  morning,   // 7h-12h
  afternoon, // 12h-18h
  evening,   // 18h-22h
  night,     // 22h-7h
}

/// Extension pour les propriétés des créneaux horaires
extension TimeSlotExtension on TimeSlot {
  String get displayName {
    switch (this) {
      case TimeSlot.morning:
        return 'Matin';
      case TimeSlot.afternoon:
        return 'Après-midi';
      case TimeSlot.evening:
        return 'Soirée';
      case TimeSlot.night:
        return 'Nuit';
    }
  }

  String get timeRange {
    switch (this) {
      case TimeSlot.morning:
        return '7h-12h';
      case TimeSlot.afternoon:
        return '12h-18h';
      case TimeSlot.evening:
        return '18h-22h';
      case TimeSlot.night:
        return '22h-7h';
    }
  }

  /// Retourne les heures (0-23) incluses dans ce créneau
  List<int> get hours {
    switch (this) {
      case TimeSlot.morning:
        return [7, 8, 9, 10, 11];
      case TimeSlot.afternoon:
        return [12, 13, 14, 15, 16, 17];
      case TimeSlot.evening:
        return [18, 19, 20, 21];
      case TimeSlot.night:
        return [22, 23, 0, 1, 2, 3, 4, 5, 6];
    }
  }
}

/// Créneaux par défaut (matin, après-midi, soirée - sans la nuit)
const List<TimeSlot> defaultTimeSlots = [
  TimeSlot.morning,
  TimeSlot.afternoon,
  TimeSlot.evening,
];

/// Paramètres de recherche de destination
class SearchParams {
  final double centerLatitude;
  final double centerLongitude;
  final double searchRadius; // en km
  final DateTime startDate;
  final DateTime endDate;
  final double? desiredMinTemperature;
  final double? desiredMaxTemperature;
  final List<String> desiredConditions; // clear, partly_cloudy, etc.
  final List<TimeSlot> timeSlots; // Créneaux horaires à considérer

  const SearchParams({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.searchRadius,
    required this.startDate,
    required this.endDate,
    this.desiredMinTemperature,
    this.desiredMaxTemperature,
    this.desiredConditions = const [],
    this.timeSlots = defaultTimeSlots,
  });

  /// Convertir en Map pour sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'searchRadius': searchRadius,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'desiredMinTemperature': desiredMinTemperature,
      'desiredMaxTemperature': desiredMaxTemperature,
      'desiredConditions': desiredConditions,
      'timeSlots': timeSlots.map((t) => t.name).toList(),
      'type': 'simple',
    };
  }

  /// Retourne toutes les heures à considérer basées sur les créneaux sélectionnés
  Set<int> get selectedHours {
    final hours = <int>{};
    for (final slot in timeSlots) {
      hours.addAll(slot.hours);
    }
    return hours;
  }

  /// Créer depuis Map
  factory SearchParams.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    if (type == 'advanced') {
      return AdvancedSearchParams.fromJson(json);
    }

    return SearchParams(
      centerLatitude: json['centerLatitude'] as double,
      centerLongitude: json['centerLongitude'] as double,
      searchRadius: json['searchRadius'] as double,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      desiredMinTemperature: json['desiredMinTemperature'] as double?,
      desiredMaxTemperature: json['desiredMaxTemperature'] as double?,
      desiredConditions: (json['desiredConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((name) => TimeSlot.values.firstWhere(
                    (t) => t.name == name,
                    orElse: () => TimeSlot.morning,
                  ))
              .toList() ??
          defaultTimeSlots,
    );
  }
}

/// Paramètres de recherche d'activité
class AdvancedSearchParams extends SearchParams {
  final List<ActivityType> desiredActivities;

  const AdvancedSearchParams({
    required super.centerLatitude,
    required super.centerLongitude,
    required super.searchRadius,
    required super.startDate,
    required super.endDate,
    super.desiredMinTemperature,
    super.desiredMaxTemperature,
    super.desiredConditions,
    super.timeSlots,
    this.desiredActivities = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'advanced';
    json['desiredActivities'] = desiredActivities.map((a) => a.name).toList();
    return json;
  }

  factory AdvancedSearchParams.fromJson(Map<String, dynamic> json) {
    return AdvancedSearchParams(
      centerLatitude: json['centerLatitude'] as double,
      centerLongitude: json['centerLongitude'] as double,
      searchRadius: json['searchRadius'] as double,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      desiredMinTemperature: json['desiredMinTemperature'] as double?,
      desiredMaxTemperature: json['desiredMaxTemperature'] as double?,
      desiredConditions: (json['desiredConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((name) => TimeSlot.values.firstWhere(
                    (t) => t.name == name,
                    orElse: () => TimeSlot.morning,
                  ))
              .toList() ??
          defaultTimeSlots,
      desiredActivities: (json['desiredActivities'] as List<dynamic>?)
              ?.map((name) => ActivityType.values.firstWhere(
                    (type) => type.name == name,
                    orElse: () => ActivityType.hiking,
                  ))
              .toList() ??
          const [],
    );
  }
}

/// Paramètres de recherche d'événements
class EventSearchParams {
  final double centerLatitude;
  final double centerLongitude;
  final double searchRadius; // en km
  final DateTime startDate;
  final DateTime endDate;
  final List<EventType> eventTypes; // Types d'événements recherchés
  final double? minPrice; // Prix minimum (optionnel)
  final double? maxPrice; // Prix maximum (optionnel)
  final bool? sortByPopularity; // Trier par popularité (optionnel)

  const EventSearchParams({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.searchRadius,
    required this.startDate,
    required this.endDate,
    this.eventTypes = const [],
    this.minPrice,
    this.maxPrice,
    this.sortByPopularity,
  });

  /// Convertir en Map pour sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'searchRadius': searchRadius,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'eventTypes': eventTypes.map((t) => t.name).toList(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'sortByPopularity': sortByPopularity,
      'type': 'event',
    };
  }

  /// Créer depuis Map
  factory EventSearchParams.fromJson(Map<String, dynamic> json) {
    return EventSearchParams(
      centerLatitude: json['centerLatitude'] as double,
      centerLongitude: json['centerLongitude'] as double,
      searchRadius: json['searchRadius'] as double,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      eventTypes: (json['eventTypes'] as List<dynamic>?)
              ?.map((name) => EventType.values.firstWhere(
                    (type) => type.name == name,
                    orElse: () => EventType.other,
                  ))
              .toList() ??
          const [],
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      sortByPopularity: json['sortByPopularity'] as bool?,
    );
  }
}
