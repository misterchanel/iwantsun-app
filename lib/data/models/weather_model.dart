import 'package:iwantsun/domain/entities/weather.dart';

/// Modèle de données pour Weather (sérialisation JSON)
class WeatherModel extends Weather {
  const WeatherModel({
    required super.date,
    required super.temperature,
    required super.minTemperature,
    required super.maxTemperature,
    required super.condition,
    super.humidity,
    super.windSpeed,
    super.description,
    super.hourlyData,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // Conversion depuis OpenWeatherMap format
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?[0] ?? {};
    final wind = json['wind'] ?? {};
    final dt = json['dt'] ?? json['dt_txt'];

    DateTime date;
    if (dt is int) {
      date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
    } else if (dt is String) {
      date = DateTime.parse(dt);
    } else {
      date = DateTime.now();
    }

    return WeatherModel(
      date: date,
      temperature: (main['temp'] ?? 0.0).toDouble(),
      minTemperature: (main['temp_min'] ?? 0.0).toDouble(),
      maxTemperature: (main['temp_max'] ?? 0.0).toDouble(),
      condition: _mapCondition(weather['main']?.toString().toLowerCase() ?? ''),
      humidity: (main['humidity'] ?? 0.0).toDouble(),
      windSpeed: (wind['speed'] ?? 0.0).toDouble(),
      description: weather['description']?.toString(),
    );
  }

  static String _mapCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'clear';
      case 'clouds':
        return 'cloudy';
      case 'partly_cloudy':
        return 'partly_cloudy';
      case 'rain':
      case 'drizzle':
        return 'rain';
      case 'snow':
        return 'snow';
      default:
        return 'cloudy';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temperature': temperature,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'condition': condition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'hourlyData': hourlyData.map((h) => h.toJson()).toList(),
    };
  }

  /// Créer depuis JSON avec données horaires (format Open-Meteo simplifié)
  factory WeatherModel.fromJsonSimple(Map<String, dynamic> json) {
    final hourlyList = (json['hourlyData'] as List<dynamic>?)
        ?.map((h) => HourlyWeather.fromJson(h as Map<String, dynamic>))
        .toList() ?? [];

    return WeatherModel(
      date: DateTime.parse(json['date'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      minTemperature: (json['minTemperature'] as num).toDouble(),
      maxTemperature: (json['maxTemperature'] as num).toDouble(),
      condition: json['condition'] as String,
      humidity: (json['humidity'] as num?)?.toDouble(),
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
      description: json['description'] as String?,
      hourlyData: hourlyList,
    );
  }

  Weather toEntity() {
    return Weather(
      date: date,
      temperature: temperature,
      minTemperature: minTemperature,
      maxTemperature: maxTemperature,
      condition: condition,
      humidity: humidity,
      windSpeed: windSpeed,
      description: description,
      hourlyData: hourlyData,
    );
  }
}
