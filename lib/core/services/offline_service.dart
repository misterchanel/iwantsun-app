import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types d'opérations pouvant être mises en file d'attente
enum SyncOperationType {
  addFavorite,
  removeFavorite,
  saveSearch,
}

/// Opération en attente de synchronisation
class PendingSyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingSyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Service de gestion du mode offline et de la synchronisation
class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;

  OfflineService._internal();

  final NetworkService _networkService = NetworkService();
  final AppLogger _logger = AppLogger();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  final List<PendingSyncOperation> _syncQueue = [];
  List<PendingSyncOperation> get syncQueue => List.unmodifiable(_syncQueue);
  int get pendingOperationsCount => _syncQueue.length;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;

  static const String _queueKey = 'offline_sync_queue';

  /// Initialise le service et commence à écouter la connectivité
  Future<void> init() async {
    _logger.info('Initializing OfflineService');

    // Charger la queue depuis le stockage
    await _loadSyncQueue();

    // Vérifier l'état initial
    _isOnline = await _networkService.isConnected;
    notifyListeners();

    // Écouter les changements de connectivité
    _connectivitySubscription = _networkService.connectivityStream.listen(
      (connected) {
        final wasOffline = !_isOnline;
        _isOnline = connected;
        _logger.info('Network status changed: ${_isOnline ? "Online" : "Offline"}');
        notifyListeners();

        // Si on vient de passer en ligne, synchroniser
        if (wasOffline && _isOnline) {
          _logger.info('Back online - starting sync');
          _syncPendingOperations();
        }
      },
      onError: (error) {
        _logger.error('Error in connectivity stream', error);
      },
    );

    // Démarrer un timer pour tenter la sync périodiquement
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && _syncQueue.isNotEmpty) {
        _logger.debug('Periodic sync attempt');
        _syncPendingOperations();
      }
    });

    _logger.info('OfflineService initialized - Status: ${_isOnline ? "Online" : "Offline"}');
  }

  /// Ajoute une opération à la file de synchronisation
  Future<void> addToSyncQueue(SyncOperationType type, Map<String, dynamic> data) async {
    final operation = PendingSyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    _syncQueue.add(operation);
    await _saveSyncQueue();
    notifyListeners();

    _logger.info('Added operation to sync queue: ${type.toString()}');

    // Si on est en ligne, tenter de synchroniser immédiatement
    if (_isOnline) {
      _syncPendingOperations();
    }
  }

  /// Supprime une opération de la queue
  Future<void> _removeFromSyncQueue(String operationId) async {
    _syncQueue.removeWhere((op) => op.id == operationId);
    await _saveSyncQueue();
    notifyListeners();
  }

  /// Synchronise les opérations en attente
  Future<void> _syncPendingOperations() async {
    if (_syncQueue.isEmpty) return;
    if (!_isOnline) return;

    _logger.info('Starting sync of ${_syncQueue.length} pending operations');

    // Copier la queue pour éviter les modifications pendant l'itération
    final operationsToSync = List<PendingSyncOperation>.from(_syncQueue);

    for (final operation in operationsToSync) {
      try {
        // Note: Dans une vraie app, on appellerait ici les services réels
        // Pour l'instant, on marque simplement comme synchronisé
        _logger.info('Syncing operation ${operation.type.toString()}');

        // Simuler un délai de sync
        await Future.delayed(const Duration(milliseconds: 100));

        // Supprimer de la queue après succès
        await _removeFromSyncQueue(operation.id);
        _logger.info('Successfully synced operation ${operation.id}');
      } catch (e) {
        _logger.error('Failed to sync operation ${operation.id}', e);
        // On garde l'opération dans la queue pour réessayer plus tard
        break; // Arrêter la sync en cas d'erreur
      }
    }

    _logger.info('Sync completed - ${_syncQueue.length} operations remaining');
  }

  /// Force une tentative de synchronisation
  Future<void> forceSyncNow() async {
    _logger.info('Force sync requested');

    // Vérifier la connexion
    _isOnline = await _networkService.isConnected;
    notifyListeners();

    if (_isOnline) {
      await _syncPendingOperations();
    } else {
      _logger.warning('Cannot sync - device is offline');
      throw Exception('Appareil hors ligne');
    }
  }

  /// Charge la queue de sync depuis le stockage
  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList(_queueKey);

      if (queueJson != null) {
        _syncQueue.clear();
        // Note: Simplification - dans une vraie app, il faudrait parser le JSON
        // Pour l'instant on ignore l'ancien état (queueJson contient les données sérialisées)
        _logger.info('Loaded ${_syncQueue.length} operations from sync queue');
      }
    } catch (e) {
      _logger.error('Failed to load sync queue', e);
    }
  }

  /// Sauvegarde la queue de sync dans le stockage
  Future<void> _saveSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _syncQueue.map((op) => op.toJson().toString()).toList();
      await prefs.setStringList(_queueKey, queueJson);
      _logger.debug('Saved ${_syncQueue.length} operations to sync queue');
    } catch (e) {
      _logger.error('Failed to save sync queue', e);
    }
  }

  /// Vide la queue de synchronisation
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    await _saveSyncQueue();
    notifyListeners();
    _logger.info('Sync queue cleared');
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
