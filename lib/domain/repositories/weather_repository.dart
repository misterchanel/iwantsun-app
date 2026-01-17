import 'package:iwantsun/domain/entities/weather.dart';

/// Repository interface pour les données météo
abstract class WeatherRepository {
  Future<WeatherForecast> getWeatherForecast({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  });
}
