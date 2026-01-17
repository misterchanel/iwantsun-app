/// Entité représentant les données météo
class Weather {
  final DateTime date;
  final double temperature; // en Celsius
  final double minTemperature;
  final double maxTemperature;
  final String condition; // clear, partly_cloudy, cloudy, rain, etc.
  final double? humidity;
  final double? windSpeed;
  final String? description;

  const Weather({
    required this.date,
    required this.temperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.condition,
    this.humidity,
    this.windSpeed,
    this.description,
  });
}

/// Entité représentant les prévisions météo pour une localité
class WeatherForecast {
  final String locationId;
  final List<Weather> forecasts;
  final double averageTemperature;
  final double weatherScore; // score de compatibilité (0-100)

  const WeatherForecast({
    required this.locationId,
    required this.forecasts,
    required this.averageTemperature,
    required this.weatherScore,
  });
}
