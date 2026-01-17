import 'package:equatable/equatable.dart';
import 'package:iwantsun/domain/entities/search_result.dart';

/// Représente une destination favorite sauvegardée par l'utilisateur
class Favorite extends Equatable {
  final String id;
  final String locationName;
  final String? country;
  final double latitude;
  final double longitude;
  final double overallScore;
  final double averageTemperature;
  final int sunnyDays;
  final DateTime savedAt;
  final String? notes; // Notes personnelles de l'utilisateur

  const Favorite({
    required this.id,
    required this.locationName,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.overallScore,
    required this.averageTemperature,
    required this.sunnyDays,
    required this.savedAt,
    this.notes,
  });

  /// Créer un favori depuis un SearchResult
  factory Favorite.fromSearchResult(SearchResult result, {String? notes}) {
    return Favorite(
      id: '${result.location.id}_${DateTime.now().millisecondsSinceEpoch}',
      locationName: result.location.name,
      country: result.location.country,
      latitude: result.location.latitude,
      longitude: result.location.longitude,
      overallScore: result.overallScore,
      averageTemperature: result.weatherForecast.averageTemperature,
      sunnyDays: result.weatherForecast.forecasts
          .where((f) => f.condition.toLowerCase().contains('clear') ||
                       f.condition.toLowerCase().contains('sunny'))
          .length,
      savedAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Convertir en Map pour Hive
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationName': locationName,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'overallScore': overallScore,
      'averageTemperature': averageTemperature,
      'sunnyDays': sunnyDays,
      'savedAt': savedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Créer depuis Map (Hive)
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      country: json['country'] as String?,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      overallScore: json['overallScore'] as double,
      averageTemperature: json['averageTemperature'] as double,
      sunnyDays: json['sunnyDays'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Créer une copie avec modifications
  Favorite copyWith({
    String? id,
    String? locationName,
    String? country,
    double? latitude,
    double? longitude,
    double? overallScore,
    double? averageTemperature,
    int? sunnyDays,
    DateTime? savedAt,
    String? notes,
  }) {
    return Favorite(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      overallScore: overallScore ?? this.overallScore,
      averageTemperature: averageTemperature ?? this.averageTemperature,
      sunnyDays: sunnyDays ?? this.sunnyDays,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        locationName,
        country,
        latitude,
        longitude,
        overallScore,
        averageTemperature,
        sunnyDays,
        savedAt,
        notes,
      ];
}
