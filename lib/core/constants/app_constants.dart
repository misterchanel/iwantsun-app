/// Constantes générales de l'application
class AppConstants {
  // Recherche
  static const double minSearchRadius = 10.0; // km
  static const double maxSearchRadius = 500.0; // km
  static const double defaultSearchRadius = 100.0; // km
  
  // Cache
  static const int cacheWeatherDuration = 3600; // 1 heure en secondes
  static const int cacheSearchResultsDuration = 86400; // 24 heures
  static const int cacheHotelsDuration = 21600; // 6 heures
  
  // Scoring
  static const double temperatureWeight = 0.4;
  static const double conditionsWeight = 0.4;
  static const double stabilityWeight = 0.2;
  static const double activitiesWeight = 0.3;
  
  // Affiliate
  static const String affiliateId = 'YOUR_AFFILIATE_ID';
}
