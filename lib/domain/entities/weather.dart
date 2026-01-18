/// Données météo pour une heure spécifique
class HourlyWeather {
  final int hour; // 0-23
  final double temperature;
  final String condition;

  const HourlyWeather({
    required this.hour,
    required this.temperature,
    required this.condition,
  });

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'temperature': temperature,
    'condition': condition,
  };

  factory HourlyWeather.fromJson(Map<String, dynamic> json) => HourlyWeather(
    hour: json['hour'] as int,
    temperature: (json['temperature'] as num).toDouble(),
    condition: json['condition'] as String,
  );
}

/// Entité représentant les données météo
class Weather {
  final DateTime date;
  final double temperature; // en Celsius (moyenne journalière)
  final double minTemperature;
  final double maxTemperature;
  final String condition; // clear, partly_cloudy, cloudy, rain, etc.
  final double? humidity;
  final double? windSpeed;
  final String? description;
  final List<HourlyWeather> hourlyData; // Données horaires pour filtrage par créneau

  const Weather({
    required this.date,
    required this.temperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.condition,
    this.humidity,
    this.windSpeed,
    this.description,
    this.hourlyData = const [],
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
