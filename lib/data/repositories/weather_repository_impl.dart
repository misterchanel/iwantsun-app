import 'package:iwantsun/data/datasources/remote/weather_remote_datasource.dart';
import 'package:iwantsun/domain/entities/weather.dart';
import 'package:iwantsun/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource _remoteDataSource;

  WeatherRepositoryImpl({required WeatherRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<WeatherForecast> getWeatherForecast({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final weatherModels = await _remoteDataSource.getWeatherForecast(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    final forecasts = weatherModels.map((model) => model.toEntity()).toList();

    // Calculer la température moyenne
    final avgTemp = forecasts.isEmpty
        ? 0.0
        : forecasts.map((w) => w.temperature).reduce((a, b) => a + b) /
            forecasts.length;

    // Calculer le score météo (simplifié pour l'instant)
    final weatherScore = _calculateWeatherScore(forecasts);

    return WeatherForecast(
      locationId: '$latitude,$longitude',
      forecasts: forecasts,
      averageTemperature: avgTemp,
      weatherScore: weatherScore,
    );
  }

  double _calculateWeatherScore(List<Weather> forecasts) {
    if (forecasts.isEmpty) return 0.0;

    // Score basé sur la stabilité et les conditions
    double totalScore = 0.0;
    for (final forecast in forecasts) {
      // Score basé sur les conditions (ensoleillé = meilleur score)
      double conditionScore = 50.0;
      if (forecast.condition == 'clear') conditionScore = 100.0;
      if (forecast.condition == 'partly_cloudy') conditionScore = 80.0;
      if (forecast.condition == 'cloudy') conditionScore = 60.0;
      if (forecast.condition == 'rain') conditionScore = 30.0;

      totalScore += conditionScore;
    }

    return totalScore / forecasts.length;
  }
}
