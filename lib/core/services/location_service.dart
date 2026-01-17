import 'package:geolocator/geolocator.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/ip_geolocation_service.dart';

/// Résultat de géolocalisation avec métadonnées
class LocationResult {
  final double latitude;
  final double longitude;
  final LocationSource source;
  final String? displayName;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.displayName,
  });

  factory LocationResult.fromGps(Position position) {
    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      source: LocationSource.gps,
    );
  }

  factory LocationResult.fromIp(IpGeolocationResult ipResult) {
    return LocationResult(
      latitude: ipResult.latitude,
      longitude: ipResult.longitude,
      source: LocationSource.ip,
      displayName: ipResult.displayName,
    );
  }
}

enum LocationSource {
  gps,    // Position GPS précise
  ip,     // Position approximative basée sur l'IP
}

/// Service pour gérer la géolocalisation
class LocationService {
  final AppLogger _logger;
  final IpGeolocationService _ipGeoService;

  LocationService({AppLogger? logger, IpGeolocationService? ipGeoService})
      : _logger = logger ?? AppLogger(),
        _ipGeoService = ipGeoService ?? IpGeolocationService();

  /// Vérifie si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Demande la permission de localisation
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.warning('Location permission denied');
        return permission;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _logger.warning('Location permission denied forever');
      return permission;
    }

    return permission;
  }

  /// Récupère la position actuelle de l'utilisateur
  Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.warning('Location services are disabled');
        return null;
      }

      // Vérifier les permissions
      LocationPermission permission = await requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _logger.warning('Location permission not granted');
        return null;
      }

      // Récupérer la position avec timeout plus long
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15), // Timeout de 15 secondes
        ),
      );

      _logger.info('Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      _logger.error('Error getting current position', e);
      return null;
    }
  }

  /// Récupère la position avec fallback automatique sur IP
  /// Essaie d'abord le GPS, puis utilise la géolocalisation IP si échec
  Future<LocationResult?> getLocationWithFallback() async {
    _logger.info('Getting location with fallback...');

    // Tentative 1: GPS
    try {
      final position = await getCurrentPosition();
      if (position != null) {
        _logger.info('Location obtained via GPS');
        return LocationResult.fromGps(position);
      }
    } catch (e) {
      _logger.warning('GPS location failed, trying IP fallback', e);
    }

    // Tentative 2: Fallback IP
    _logger.info('Falling back to IP-based geolocation');
    try {
      final ipResult = await _ipGeoService.getLocationWithRetry();
      if (ipResult != null) {
        // Valider les coordonnées
        if (_ipGeoService.validateCoordinates(
          ipResult.latitude,
          ipResult.longitude,
        )) {
          _logger.info('Location obtained via IP: ${ipResult.displayName}');
          return LocationResult.fromIp(ipResult);
        } else {
          _logger.warning('Invalid IP geolocation coordinates');
        }
      }
    } catch (e) {
      _logger.error('IP geolocation fallback failed', e);
    }

    _logger.warning('All location methods failed');
    return null;
  }

  /// Obtenir juste les coordonnées (rétrocompatibilité)
  Future<({double latitude, double longitude})?> getCoordinatesWithFallback() async {
    final result = await getLocationWithFallback();
    if (result != null) {
      return (latitude: result.latitude, longitude: result.longitude);
    }
    return null;
  }
}
