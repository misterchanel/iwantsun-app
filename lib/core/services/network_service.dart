import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iwantsun/core/services/logger_service.dart';

/// Service de gestion de la connectivité réseau
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final AppLogger _logger = AppLogger();

  /// Vérifie si l'appareil est connecté à Internet
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();

      final connected = !results.contains(ConnectivityResult.none) &&
          (results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.ethernet));

      _logger.debug('Network status: ${connected ? "Connected" : "Disconnected"}');
      return connected;
    } catch (e) {
      _logger.error('Error checking network status', e);
      return false;
    }
  }

  /// Stream pour écouter les changements de connectivité
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      final connected = !results.contains(ConnectivityResult.none) &&
          (results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.ethernet));

      _logger.debug('Network status changed: ${connected ? "Connected" : "Disconnected"}');
      return connected;
    });
  }
}
