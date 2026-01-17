import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Utilitaires pour optimiser les performances de l'application

/// Debouncer pour éviter les appels trop fréquents
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Exécuter l'action après le délai
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Annuler l'action en attente
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose du debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler pour limiter la fréquence d'exécution
class Throttler {
  final Duration interval;
  DateTime? _lastExecutionTime;

  Throttler({this.interval = const Duration(milliseconds: 100)});

  /// Exécuter l'action si l'intervalle est respecté
  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= interval) {
      _lastExecutionTime = now;
      action();
    }
  }
}

/// Cache mémoire simple avec expiration
class MemoryCache<K, V> {
  final Duration ttl;
  final int maxSize;
  final Map<K, _CacheEntry<V>> _cache = {};

  MemoryCache({
    this.ttl = const Duration(minutes: 5),
    this.maxSize = 100,
  });

  /// Obtenir une valeur du cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Mettre une valeur en cache
  void set(K key, V value) {
    // Nettoyer si trop d'entrées
    if (_cache.length >= maxSize) {
      _removeExpired();
      if (_cache.length >= maxSize) {
        _removeOldest();
      }
    }

    _cache[key] = _CacheEntry(value: value, createdAt: DateTime.now(), ttl: ttl);
  }

  /// Vérifier si une clé existe et n'est pas expirée
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Supprimer une entrée
  void remove(K key) {
    _cache.remove(key);
  }

  /// Vider le cache
  void clear() {
    _cache.clear();
  }

  /// Supprimer les entrées expirées
  void _removeExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Supprimer la plus ancienne entrée
  void _removeOldest() {
    if (_cache.isEmpty) return;

    K? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestTime = entry.value.createdAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime createdAt;
  final Duration ttl;

  _CacheEntry({
    required this.value,
    required this.createdAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Gestionnaire de préchargement intelligent
class PreloadManager {
  static final PreloadManager _instance = PreloadManager._internal();
  factory PreloadManager() => _instance;
  PreloadManager._internal();

  final Set<String> _preloadedResources = {};
  final Map<String, Future<void>> _pendingPreloads = {};

  /// Précharger une ressource
  Future<void> preload(String key, Future<void> Function() loader) async {
    if (_preloadedResources.contains(key)) return;
    if (_pendingPreloads.containsKey(key)) {
      return _pendingPreloads[key];
    }

    final future = loader();
    _pendingPreloads[key] = future;

    try {
      await future;
      _preloadedResources.add(key);
    } finally {
      _pendingPreloads.remove(key);
    }
  }

  /// Vérifier si une ressource est préchargée
  bool isPreloaded(String key) => _preloadedResources.contains(key);

  /// Réinitialiser
  void clear() {
    _preloadedResources.clear();
    _pendingPreloads.clear();
  }
}

/// Widget optimisé pour les listes longues avec virtualisation
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double estimatedItemHeight;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final Widget? header;
  final Widget? emptyWidget;
  final bool shrinkWrap;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.estimatedItemHeight = 100,
    this.padding,
    this.controller,
    this.header,
    this.emptyWidget,
    this.shrinkWrap = false,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      // Optimisations de performance
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: widget.estimatedItemHeight * 3,
      itemCount: widget.items.length + (widget.header != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.header != null && index == 0) {
          return widget.header!;
        }

        final itemIndex = widget.header != null ? index - 1 : index;
        return RepaintBoundary(
          child: widget.itemBuilder(context, widget.items[itemIndex], itemIndex),
        );
      },
    );
  }
}

/// Widget avec lazy loading automatique
class LazyWidget extends StatefulWidget {
  final Widget child;
  final Widget placeholder;
  final Duration delay;

  const LazyWidget({
    super.key,
    required this.child,
    required this.placeholder,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour charger après le frame actuel
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() => _loaded = true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loaded ? widget.child : widget.placeholder;
  }
}

/// Widget avec chargement progressif (skeleton -> contenu)
class ProgressiveLoader extends StatefulWidget {
  final Future<Widget> Function() loader;
  final Widget skeleton;
  final Duration minLoadTime;

  const ProgressiveLoader({
    super.key,
    required this.loader,
    required this.skeleton,
    this.minLoadTime = const Duration(milliseconds: 300),
  });

  @override
  State<ProgressiveLoader> createState() => _ProgressiveLoaderState();
}

class _ProgressiveLoaderState extends State<ProgressiveLoader> {
  Widget? _loadedWidget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final startTime = DateTime.now();

    try {
      final result = await widget.loader();

      // Attendre le temps minimum
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < widget.minLoadTime) {
        await Future.delayed(widget.minLoadTime - elapsed);
      }

      if (mounted) {
        setState(() {
          _loadedWidget = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loadedWidget == null) {
      return widget.skeleton;
    }
    return _loadedWidget!;
  }
}

/// Extension pour optimiser les widgets
extension PerformanceExtensions on Widget {
  /// Envelopper dans un RepaintBoundary
  Widget withRepaintBoundary() => RepaintBoundary(child: this);

  /// Charger paresseusement
  Widget lazy({Widget? placeholder}) => LazyWidget(
        placeholder: placeholder ?? const SizedBox.shrink(),
        child: this,
      );
}

/// Gestionnaire de frames pour éviter les jank
class FrameScheduler {
  static final FrameScheduler _instance = FrameScheduler._internal();
  factory FrameScheduler() => _instance;
  FrameScheduler._internal();

  final List<VoidCallback> _pendingCallbacks = [];
  bool _isProcessing = false;

  /// Programmer une action pour le prochain frame disponible
  void scheduleTask(VoidCallback callback) {
    _pendingCallbacks.add(callback);
    _processIfNeeded();
  }

  void _processIfNeeded() {
    if (_isProcessing || _pendingCallbacks.isEmpty) return;

    _isProcessing = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_pendingCallbacks.isNotEmpty) {
        final callback = _pendingCallbacks.removeAt(0);
        callback();
      }
      _isProcessing = false;
      _processIfNeeded();
    });
  }
}

/// Moniteur de performances
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, List<Duration>> _measurements = {};

  /// Mesurer le temps d'exécution
  T measure<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    final result = operation();
    stopwatch.stop();

    _measurements.putIfAbsent(operationName, () => []);
    _measurements[operationName]!.add(stopwatch.elapsed);

    // Garder seulement les 100 dernières mesures
    if (_measurements[operationName]!.length > 100) {
      _measurements[operationName]!.removeAt(0);
    }

    return result;
  }

  /// Mesurer le temps d'exécution asynchrone
  Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    final result = await operation();
    stopwatch.stop();

    _measurements.putIfAbsent(operationName, () => []);
    _measurements[operationName]!.add(stopwatch.elapsed);

    if (_measurements[operationName]!.length > 100) {
      _measurements[operationName]!.removeAt(0);
    }

    return result;
  }

  /// Obtenir les statistiques
  Map<String, Map<String, Duration>> getStats() {
    final stats = <String, Map<String, Duration>>{};

    for (final entry in _measurements.entries) {
      if (entry.value.isEmpty) continue;

      final sorted = List<Duration>.from(entry.value)..sort();
      final total = entry.value.fold(Duration.zero, (a, b) => a + b);
      final avg = total ~/ entry.value.length;

      stats[entry.key] = {
        'min': sorted.first,
        'max': sorted.last,
        'avg': avg,
        'p50': sorted[sorted.length ~/ 2],
        'p95': sorted[(sorted.length * 0.95).floor().clamp(0, sorted.length - 1)],
      };
    }

    return stats;
  }

  /// Réinitialiser les mesures
  void clear() {
    _measurements.clear();
  }
}
