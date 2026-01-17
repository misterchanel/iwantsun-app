import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iwantsun/core/services/logger_service.dart';

/// Modèle pour les préférences de température
class TemperaturePreference {
  final double minTemp;
  final double maxTemp;
  final String label;

  const TemperaturePreference({
    required this.minTemp,
    required this.maxTemp,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'minTemp': minTemp,
    'maxTemp': maxTemp,
    'label': label,
  };

  factory TemperaturePreference.fromJson(Map<String, dynamic> json) {
    return TemperaturePreference(
      minTemp: (json['minTemp'] as num).toDouble(),
      maxTemp: (json['maxTemp'] as num).toDouble(),
      label: json['label'] as String,
    );
  }

  // Préférences prédéfinies
  static const TemperaturePreference hot = TemperaturePreference(
    minTemp: 30,
    maxTemp: 40,
    label: 'Très chaud',
  );
  static const TemperaturePreference warm = TemperaturePreference(
    minTemp: 25,
    maxTemp: 32,
    label: 'Chaud',
  );
  static const TemperaturePreference mild = TemperaturePreference(
    minTemp: 20,
    maxTemp: 27,
    label: 'Doux',
  );
  static const TemperaturePreference cool = TemperaturePreference(
    minTemp: 15,
    maxTemp: 22,
    label: 'Frais',
  );
}

/// Profil utilisateur complet
class UserProfile {
  final String? name;
  final String? email;
  final String? avatarUrl;
  final TemperaturePreference? temperaturePreference;
  final List<String> preferredActivities;
  final int defaultSearchRadius;
  final bool useCurrentLocation;
  final String? homeLocation;
  final double? homeLatitude;
  final double? homeLongitude;
  final bool notificationsEnabled;
  final bool weatherAlertsEnabled;
  final bool dealsEnabled;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  const UserProfile({
    this.name,
    this.email,
    this.avatarUrl,
    this.temperaturePreference,
    this.preferredActivities = const [],
    this.defaultSearchRadius = 500,
    this.useCurrentLocation = true,
    this.homeLocation,
    this.homeLatitude,
    this.homeLongitude,
    this.notificationsEnabled = true,
    this.weatherAlertsEnabled = true,
    this.dealsEnabled = false,
    this.createdAt,
    this.lastUpdated,
  });

  bool get isComplete {
    return name != null &&
           temperaturePreference != null &&
           preferredActivities.isNotEmpty;
  }

  int get completionPercentage {
    int score = 0;
    if (name != null) score += 20;
    if (temperaturePreference != null) score += 20;
    if (preferredActivities.isNotEmpty) score += 20;
    if (homeLocation != null) score += 20;
    if (notificationsEnabled) score += 10;
    if (email != null) score += 10;
    return score;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'temperaturePreference': temperaturePreference?.toJson(),
    'preferredActivities': preferredActivities,
    'defaultSearchRadius': defaultSearchRadius,
    'useCurrentLocation': useCurrentLocation,
    'homeLocation': homeLocation,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'notificationsEnabled': notificationsEnabled,
    'weatherAlertsEnabled': weatherAlertsEnabled,
    'dealsEnabled': dealsEnabled,
    'createdAt': createdAt?.toIso8601String(),
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      temperaturePreference: json['temperaturePreference'] != null
          ? TemperaturePreference.fromJson(json['temperaturePreference'] as Map<String, dynamic>)
          : null,
      preferredActivities: (json['preferredActivities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      defaultSearchRadius: json['defaultSearchRadius'] as int? ?? 500,
      useCurrentLocation: json['useCurrentLocation'] as bool? ?? true,
      homeLocation: json['homeLocation'] as String?,
      homeLatitude: (json['homeLatitude'] as num?)?.toDouble(),
      homeLongitude: (json['homeLongitude'] as num?)?.toDouble(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      weatherAlertsEnabled: json['weatherAlertsEnabled'] as bool? ?? true,
      dealsEnabled: json['dealsEnabled'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    TemperaturePreference? temperaturePreference,
    List<String>? preferredActivities,
    int? defaultSearchRadius,
    bool? useCurrentLocation,
    String? homeLocation,
    double? homeLatitude,
    double? homeLongitude,
    bool? notificationsEnabled,
    bool? weatherAlertsEnabled,
    bool? dealsEnabled,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      temperaturePreference: temperaturePreference ?? this.temperaturePreference,
      preferredActivities: preferredActivities ?? this.preferredActivities,
      defaultSearchRadius: defaultSearchRadius ?? this.defaultSearchRadius,
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      homeLocation: homeLocation ?? this.homeLocation,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      weatherAlertsEnabled: weatherAlertsEnabled ?? this.weatherAlertsEnabled,
      dealsEnabled: dealsEnabled ?? this.dealsEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

/// Service pour gérer le profil utilisateur
class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final AppLogger _logger = AppLogger();
  static const String _profileKey = 'user_profile';

  UserProfile _profile = const UserProfile();
  bool _isLoading = false;
  bool _isInitialized = false;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Initialiser le service
  Future<void> init() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>);
        _logger.info('User profile loaded');
      } else {
        _profile = UserProfile(createdAt: DateTime.now());
        _logger.info('New user profile created');
      }

      _isInitialized = true;
    } catch (e) {
      _logger.error('Failed to load user profile', e);
      _profile = UserProfile(createdAt: DateTime.now());
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarder le profil
  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(_profile.toJson()));
      _logger.info('User profile saved');
    } catch (e) {
      _logger.error('Failed to save user profile', e);
    }
  }

  /// Mettre à jour le profil
  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile.copyWith(lastUpdated: DateTime.now());
    notifyListeners();
    await _saveProfile();
  }

  /// Mettre à jour le nom
  Future<void> updateName(String name) async {
    await updateProfile(_profile.copyWith(name: name));
  }

  /// Mettre à jour l'email
  Future<void> updateEmail(String email) async {
    await updateProfile(_profile.copyWith(email: email));
  }

  /// Mettre à jour la préférence de température
  Future<void> updateTemperaturePreference(TemperaturePreference pref) async {
    await updateProfile(_profile.copyWith(temperaturePreference: pref));
  }

  /// Mettre à jour les activités préférées
  Future<void> updatePreferredActivities(List<String> activities) async {
    await updateProfile(_profile.copyWith(preferredActivities: activities));
  }

  /// Ajouter une activité préférée
  Future<void> addPreferredActivity(String activity) async {
    if (!_profile.preferredActivities.contains(activity)) {
      final newActivities = [..._profile.preferredActivities, activity];
      await updateProfile(_profile.copyWith(preferredActivities: newActivities));
    }
  }

  /// Retirer une activité préférée
  Future<void> removePreferredActivity(String activity) async {
    final newActivities = _profile.preferredActivities
        .where((a) => a != activity)
        .toList();
    await updateProfile(_profile.copyWith(preferredActivities: newActivities));
  }

  /// Mettre à jour le rayon de recherche par défaut
  Future<void> updateDefaultSearchRadius(int radius) async {
    await updateProfile(_profile.copyWith(defaultSearchRadius: radius));
  }

  /// Mettre à jour les paramètres de localisation
  Future<void> updateLocationSettings({
    bool? useCurrentLocation,
    String? homeLocation,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    await updateProfile(_profile.copyWith(
      useCurrentLocation: useCurrentLocation,
      homeLocation: homeLocation,
      homeLatitude: homeLatitude,
      homeLongitude: homeLongitude,
    ));
  }

  /// Mettre à jour les paramètres de notifications
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? weatherAlertsEnabled,
    bool? dealsEnabled,
  }) async {
    await updateProfile(_profile.copyWith(
      notificationsEnabled: notificationsEnabled,
      weatherAlertsEnabled: weatherAlertsEnabled,
      dealsEnabled: dealsEnabled,
    ));
  }

  /// Réinitialiser le profil
  Future<void> resetProfile() async {
    _profile = UserProfile(createdAt: DateTime.now());
    notifyListeners();
    await _saveProfile();
    _logger.info('User profile reset');
  }

  /// Exporter le profil en JSON
  String exportProfile() {
    return const JsonEncoder.withIndent('  ').convert(_profile.toJson());
  }
}

/// Liste des activités disponibles
class AvailableActivities {
  static const List<ActivityOption> all = [
    ActivityOption(id: 'beach', name: 'Plage', icon: Icons.beach_access),
    ActivityOption(id: 'hiking', name: 'Randonnée', icon: Icons.terrain),
    ActivityOption(id: 'culture', name: 'Culture', icon: Icons.museum),
    ActivityOption(id: 'gastronomy', name: 'Gastronomie', icon: Icons.restaurant),
    ActivityOption(id: 'nightlife', name: 'Vie nocturne', icon: Icons.nightlife),
    ActivityOption(id: 'spa', name: 'Spa & Bien-être', icon: Icons.spa),
    ActivityOption(id: 'sports', name: 'Sports', icon: Icons.sports_tennis),
    ActivityOption(id: 'nature', name: 'Nature', icon: Icons.park),
    ActivityOption(id: 'shopping', name: 'Shopping', icon: Icons.shopping_bag),
    ActivityOption(id: 'photography', name: 'Photographie', icon: Icons.camera_alt),
  ];

  static ActivityOption? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Option d'activité
class ActivityOption {
  final String id;
  final String name;
  final IconData icon;

  const ActivityOption({
    required this.id,
    required this.name,
    required this.icon,
  });
}
