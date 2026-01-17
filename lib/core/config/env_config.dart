import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de configuration de l'environnement
class EnvConfig {
  /// Charge les variables d'environnement
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // Amadeus API
  static String get amadeusApiKey =>
      dotenv.get('AMADEUS_API_KEY', fallback: '');
  static String get amadeusApiSecret =>
      dotenv.get('AMADEUS_API_SECRET', fallback: '');
  static String get amadeusApiUrl =>
      dotenv.get('AMADEUS_API_URL', fallback: 'https://test.api.amadeus.com');

  // Google Places API
  static String get googlePlacesApiKey =>
      dotenv.get('GOOGLE_PLACES_API_KEY', fallback: '');

  // OpenWeather API
  static String get openWeatherApiKey =>
      dotenv.get('OPENWEATHER_API_KEY', fallback: '');

  // Configuration
  static bool get enableLogging =>
      dotenv.get('ENABLE_LOGGING', fallback: 'true').toLowerCase() == 'true';
  static int get cacheDurationHours =>
      int.tryParse(dotenv.get('CACHE_DURATION_HOURS', fallback: '24')) ?? 24;
  static int get apiTimeoutSeconds =>
      int.tryParse(dotenv.get('API_TIMEOUT_SECONDS', fallback: '30')) ?? 30;

  /// Vérifie si toutes les clés API nécessaires sont configurées
  static bool get hasAmadeusConfig =>
      amadeusApiKey.isNotEmpty && amadeusApiSecret.isNotEmpty;
  static bool get hasGooglePlacesConfig => googlePlacesApiKey.isNotEmpty;
  static bool get hasOpenWeatherConfig => openWeatherApiKey.isNotEmpty;

  /// Retourne un résumé de la configuration
  static Map<String, bool> get configStatus => {
        'amadeus': hasAmadeusConfig,
        'googlePlaces': hasGooglePlacesConfig,
        'openWeather': hasOpenWeatherConfig,
      };

  /// Vérifie si la configuration minimale est présente
  static bool get hasMinimalConfig => hasAmadeusConfig || hasGooglePlacesConfig;
}
