import 'package:iwantsun/domain/entities/activity.dart';

/// Paramètres de recherche simple
class SearchParams {
  final double centerLatitude;
  final double centerLongitude;
  final double searchRadius; // en km
  final DateTime startDate;
  final DateTime endDate;
  final double? desiredMinTemperature;
  final double? desiredMaxTemperature;
  final List<String> desiredConditions; // clear, partly_cloudy, etc.

  const SearchParams({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.searchRadius,
    required this.startDate,
    required this.endDate,
    this.desiredMinTemperature,
    this.desiredMaxTemperature,
    this.desiredConditions = const [],
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
      'type': 'simple',
    };
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
    );
  }
}

/// Paramètres de recherche avancée (avec activités)
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
