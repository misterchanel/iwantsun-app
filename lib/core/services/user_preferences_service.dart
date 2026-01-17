import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';

/// Préférences utilisateur pour l'application
class UserPreferences {
  // Recherche par défaut
  final double? defaultMinTemperature;
  final double? defaultMaxTemperature;
  final List<String>? defaultWeatherConditions;
  final double? defaultSearchRadius;

  // Ville favorite
  final String? favoriteLocationName;
  final double? favoriteLocationLat;
  final double? favoriteLocationLon;

  // Affichage
  final TemperatureUnit temperatureUnit;
  final bool use24HourFormat;
  final String locale; // 'fr', 'en', etc.

  // Notifications (pour future implémentation)
  final bool enableNotifications;
  final bool notifyBeforeTrip;
  final int notifyDaysBefore;

  // Accessibilité
  final bool highContrastMode;
  final double textScaleFactor;

  // Autres
  final bool showOnboarding;
  final DateTime? lastUsedAt;

  const UserPreferences({
    this.defaultMinTemperature,
    this.defaultMaxTemperature,
    this.defaultWeatherConditions,
    this.defaultSearchRadius,
    this.favoriteLocationName,
    this.favoriteLocationLat,
    this.favoriteLocationLon,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.use24HourFormat = true,
    this.locale = 'fr',
    this.enableNotifications = false,
    this.notifyBeforeTrip = false,
    this.notifyDaysBefore = 7,
    this.highContrastMode = false,
    this.textScaleFactor = 1.0,
    this.showOnboarding = true,
    this.lastUsedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'defaultMinTemperature': defaultMinTemperature,
      'defaultMaxTemperature': defaultMaxTemperature,
      'defaultWeatherConditions': defaultWeatherConditions,
      'defaultSearchRadius': defaultSearchRadius,
      'favoriteLocationName': favoriteLocationName,
      'favoriteLocationLat': favoriteLocationLat,
      'favoriteLocationLon': favoriteLocationLon,
      'temperatureUnit': temperatureUnit.toString(),
      'use24HourFormat': use24HourFormat,
      'locale': locale,
      'enableNotifications': enableNotifications,
      'notifyBeforeTrip': notifyBeforeTrip,
      'notifyDaysBefore': notifyDaysBefore,
      'highContrastMode': highContrastMode,
      'textScaleFactor': textScaleFactor,
      'showOnboarding': showOnboarding,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      defaultMinTemperature: (json['defaultMinTemperature'] as num?)?.toDouble(),
      defaultMaxTemperature: (json['defaultMaxTemperature'] as num?)?.toDouble(),
      defaultWeatherConditions: (json['defaultWeatherConditions'] as List?)?.cast<String>(),
      defaultSearchRadius: (json['defaultSearchRadius'] as num?)?.toDouble(),
      favoriteLocationName: json['favoriteLocationName'] as String?,
      favoriteLocationLat: (json['favoriteLocationLat'] as num?)?.toDouble(),
      favoriteLocationLon: (json['favoriteLocationLon'] as num?)?.toDouble(),
      temperatureUnit: _parseTemperatureUnit(json['temperatureUnit'] as String?),
      use24HourFormat: json['use24HourFormat'] as bool? ?? true,
      locale: json['locale'] as String? ?? 'fr',
      enableNotifications: json['enableNotifications'] as bool? ?? false,
      notifyBeforeTrip: json['notifyBeforeTrip'] as bool? ?? false,
      notifyDaysBefore: json['notifyDaysBefore'] as int? ?? 7,
      highContrastMode: json['highContrastMode'] as bool? ?? false,
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      showOnboarding: json['showOnboarding'] as bool? ?? true,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
    );
  }

  static TemperatureUnit _parseTemperatureUnit(String? value) {
    if (value == null) return TemperatureUnit.celsius;
    return TemperatureUnit.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => TemperatureUnit.celsius,
    );
  }

  UserPreferences copyWith({
    double? Function()? defaultMinTemperature,
    double? Function()? defaultMaxTemperature,
    List<String>? Function()? defaultWeatherConditions,
    double? Function()? defaultSearchRadius,
    String? Function()? favoriteLocationName,
    double? Function()? favoriteLocationLat,
    double? Function()? favoriteLocationLon,
    TemperatureUnit? temperatureUnit,
    bool? use24HourFormat,
    String? locale,
    bool? enableNotifications,
    bool? notifyBeforeTrip,
    int? notifyDaysBefore,
    bool? highContrastMode,
    double? textScaleFactor,
    bool? showOnboarding,
    DateTime? Function()? lastUsedAt,
  }) {
    return UserPreferences(
      defaultMinTemperature:
          defaultMinTemperature != null ? defaultMinTemperature() : this.defaultMinTemperature,
      defaultMaxTemperature:
          defaultMaxTemperature != null ? defaultMaxTemperature() : this.defaultMaxTemperature,
      defaultWeatherConditions: defaultWeatherConditions != null
          ? defaultWeatherConditions()
          : this.defaultWeatherConditions,
      defaultSearchRadius:
          defaultSearchRadius != null ? defaultSearchRadius() : this.defaultSearchRadius,
      favoriteLocationName:
          favoriteLocationName != null ? favoriteLocationName() : this.favoriteLocationName,
      favoriteLocationLat:
          favoriteLocationLat != null ? favoriteLocationLat() : this.favoriteLocationLat,
      favoriteLocationLon:
          favoriteLocationLon != null ? favoriteLocationLon() : this.favoriteLocationLon,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      locale: locale ?? this.locale,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notifyBeforeTrip: notifyBeforeTrip ?? this.notifyBeforeTrip,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      showOnboarding: showOnboarding ?? this.showOnboarding,
      lastUsedAt: lastUsedAt != null ? lastUsedAt() : this.lastUsedAt,
    );
  }
}

enum TemperatureUnit {
  celsius,
  fahrenheit,
}

/// Service pour gérer les préférences utilisateur
class UserPreferencesService {
  static const String _prefsBoxName = 'user_preferences';
  static const String _prefsKey = 'preferences';

  final CacheService _cacheService;
  final AppLogger _logger;

  UserPreferences? _cachedPrefs;

  // Singleton
  static final UserPreferencesService _instance = UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;

  UserPreferencesService._internal()
      : _cacheService = CacheService(),
        _logger = AppLogger();

  /// Initialiser le service
  Future<void> init() async {
    try {
      await _cacheService.init();
      await loadPreferences(); // Charger immédiatement
      _logger.info('UserPreferencesService initialized');
    } catch (e) {
      _logger.error('Failed to initialize UserPreferencesService', e);
    }
  }

  /// Charger les préférences
  Future<UserPreferences> loadPreferences() async {
    try {
      if (_cachedPrefs != null) {
        return _cachedPrefs!;
      }

      final data = await _cacheService.get<Map<dynamic, dynamic>>(
        _prefsKey,
        _prefsBoxName,
      );

      if (data == null) {
        _logger.debug('No saved preferences, using defaults');
        _cachedPrefs = const UserPreferences();
        return _cachedPrefs!;
      }

      _cachedPrefs = UserPreferences.fromJson(Map<String, dynamic>.from(data));
      _logger.debug('Loaded user preferences');
      return _cachedPrefs!;
    } catch (e) {
      _logger.error('Failed to load preferences', e);
      _cachedPrefs = const UserPreferences();
      return _cachedPrefs!;
    }
  }

  /// Sauvegarder les préférences
  Future<bool> savePreferences(UserPreferences prefs) async {
    try {
      await _cacheService.put(
        _prefsKey,
        prefs.toJson(),
        _prefsBoxName,
      );

      _cachedPrefs = prefs;
      _logger.info('Saved user preferences');
      return true;
    } catch (e) {
      _logger.error('Failed to save preferences', e);
      return false;
    }
  }

  /// Mettre à jour partiellement les préférences
  Future<bool> updatePreferences(UserPreferences Function(UserPreferences) updater) async {
    final currentPrefs = await loadPreferences();
    final newPrefs = updater(currentPrefs);
    return await savePreferences(newPrefs);
  }

  /// Réinitialiser aux valeurs par défaut
  Future<bool> resetToDefaults() async {
    _logger.info('Resetting preferences to defaults');
    _cachedPrefs = null;
    return await savePreferences(const UserPreferences());
  }

  /// Marquer la dernière utilisation
  Future<void> markLastUsed() async {
    await updatePreferences((prefs) => prefs.copyWith(
          lastUsedAt: () => DateTime.now(),
        ));
  }

  /// Définir la ville favorite
  Future<bool> setFavoriteLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          favoriteLocationName: () => name,
          favoriteLocationLat: () => latitude,
          favoriteLocationLon: () => longitude,
        ));
  }

  /// Supprimer la ville favorite
  Future<bool> clearFavoriteLocation() async {
    return await updatePreferences((prefs) => prefs.copyWith(
          favoriteLocationName: () => null,
          favoriteLocationLat: () => null,
          favoriteLocationLon: () => null,
        ));
  }

  /// Définir les températures par défaut
  Future<bool> setDefaultTemperatures({
    required double minTemp,
    required double maxTemp,
  }) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          defaultMinTemperature: () => minTemp,
          defaultMaxTemperature: () => maxTemp,
        ));
  }

  /// Définir le rayon de recherche par défaut
  Future<bool> setDefaultSearchRadius(double radius) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          defaultSearchRadius: () => radius,
        ));
  }

  /// Définir les conditions météo par défaut
  Future<bool> setDefaultWeatherConditions(List<String> conditions) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          defaultWeatherConditions: () => conditions,
        ));
  }

  /// Changer l'unité de température
  Future<bool> setTemperatureUnit(TemperatureUnit unit) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          temperatureUnit: unit,
        ));
  }

  /// Convertir une température selon l'unité préférée
  double convertTemperature(double celsius, {TemperatureUnit? toUnit}) {
    final unit = toUnit ?? _cachedPrefs?.temperatureUnit ?? TemperatureUnit.celsius;

    if (unit == TemperatureUnit.fahrenheit) {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }

  /// Formater une température avec l'unité
  String formatTemperature(double celsius) {
    final prefs = _cachedPrefs ?? const UserPreferences();
    final temp = convertTemperature(celsius, toUnit: prefs.temperatureUnit);
    final symbol = prefs.temperatureUnit == TemperatureUnit.celsius ? '°C' : '°F';
    return '${temp.toStringAsFixed(0)}$symbol';
  }

  /// Activer/désactiver le mode contraste élevé
  Future<bool> setHighContrastMode(bool enabled) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          highContrastMode: enabled,
        ));
  }

  /// Définir le facteur d'échelle du texte
  Future<bool> setTextScaleFactor(double factor) async {
    return await updatePreferences((prefs) => prefs.copyWith(
          textScaleFactor: factor.clamp(0.8, 1.5),
        ));
  }

  /// Marquer l'onboarding comme terminé
  Future<bool> completeOnboarding() async {
    return await updatePreferences((prefs) => prefs.copyWith(
          showOnboarding: false,
        ));
  }

  /// Obtenir les préférences actuelles (sans async)
  UserPreferences get currentPreferences => _cachedPrefs ?? const UserPreferences();
}
