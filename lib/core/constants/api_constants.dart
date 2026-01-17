/// Constantes pour les APIs utilisées dans l'application
class ApiConstants {
  // OpenWeatherMap API (optionnel)
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  // Open-Meteo API (gratuit, sans clé)
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';

  // Nominatim (OpenStreetMap) - Géocodage
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  // Overpass API - Points d'intérêt
  static const String overpassBaseUrl = 'https://overpass-api.de/api/interpreter';

  // Amadeus API - Hôtels et vols
  static const String amadeusBaseUrl = 'https://test.api.amadeus.com';
  static const String amadeusAuthUrl = 'https://test.api.amadeus.com/v1/security/oauth2/token';

  // Google Places API - Lieux et activités
  static const String googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Rate limiting (requêtes par minute)
  static const int openWeatherRateLimit = 60;
  static const int nominatimRateLimit = 1; // requête par seconde
  static const int amadeusRateLimit = 10; // requêtes par seconde (test API)
  static const int googlePlacesRateLimit = 1000; // requêtes par jour pour free tier
  static const int overpassRateLimit = 2; // requêtes toutes les 2 secondes

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  // Cache keys
  static const String weatherCachePrefix = 'weather_';
  static const String locationCachePrefix = 'location_';
  static const String hotelCachePrefix = 'hotel_';
  static const String activityCachePrefix = 'activity_';
}
