import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/domain/entities/weather.dart';

/// Résultat de recherche pour une localité
class SearchResult {
  final Location location;
  final WeatherForecast weatherForecast;
  final double? activityScore; // Score activités (0-100) si mode avancé
  final double overallScore; // Score global (0-100)

  const SearchResult({
    required this.location,
    required this.weatherForecast,
    this.activityScore,
    required this.overallScore,
  });
}
