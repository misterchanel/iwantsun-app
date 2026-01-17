import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des préférences utilisateur
/// Gère la persistance des paramètres et de l'état de l'application
class PreferencesService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _temperatureUnitKey = 'temperature_unit';
  static const String _distanceUnitKey = 'distance_unit';
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme_mode';
  static const String _locationPermissionAskedKey = 'location_permission_asked';

  late final SharedPreferences _prefs;

  /// Initialise le service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== ONBOARDING ====================

  /// Vérifie si l'onboarding a été complété
  bool get hasCompletedOnboarding {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Marque l'onboarding comme complété
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }

  // ==================== UNITÉS ====================

  /// Obtient l'unité de température (celsius/fahrenheit)
  String get temperatureUnit {
    return _prefs.getString(_temperatureUnitKey) ?? 'celsius';
  }

  /// Définit l'unité de température
  Future<void> setTemperatureUnit(String unit) async {
    await _prefs.setString(_temperatureUnitKey, unit);
  }

  /// Obtient l'unité de distance (km/miles)
  String get distanceUnit {
    return _prefs.getString(_distanceUnitKey) ?? 'km';
  }

  /// Définit l'unité de distance
  Future<void> setDistanceUnit(String unit) async {
    await _prefs.setString(_distanceUnitKey, unit);
  }

  // ==================== LANGUE ====================

  /// Obtient la langue préférée
  String get language {
    return _prefs.getString(_languageKey) ?? 'fr';
  }

  /// Définit la langue préférée
  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  // ==================== THÈME ====================

  /// Obtient le mode de thème (light/dark/system)
  String get themeMode {
    return _prefs.getString(_themeKey) ?? 'light';
  }

  /// Définit le mode de thème
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeKey, mode);
  }

  // ==================== PERMISSIONS ====================

  /// Vérifie si la permission de localisation a été demandée
  bool get hasAskedLocationPermission {
    return _prefs.getBool(_locationPermissionAskedKey) ?? false;
  }

  /// Marque la permission de localisation comme demandée
  Future<void> setLocationPermissionAsked(bool asked) async {
    await _prefs.setBool(_locationPermissionAskedKey, asked);
  }

  // ==================== RESET ====================

  /// Réinitialise toutes les préférences (utile pour le debug)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
