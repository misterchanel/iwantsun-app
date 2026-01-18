import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service de cache d'images optimisé
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Cache pour les images décodées
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, Completer<ui.Image>> _pendingLoads = {};

  // Limite du cache
  static const int _maxCacheSize = 50;

  /// Précharger une image réseau
  Future<void> preloadNetworkImage(String url) async {
    if (_imageCache.containsKey(url) || _pendingLoads.containsKey(url)) {
      return;
    }

    final completer = Completer<ui.Image>();
    _pendingLoads[url] = completer;

    try {
      final imageProvider = NetworkImage(url);
      final imageStream = imageProvider.resolve(ImageConfiguration.empty);

      imageStream.addListener(ImageStreamListener(
        (info, _) {
          _addToCache(url, info.image);
          completer.complete(info.image);
          _pendingLoads.remove(url);
        },
        onError: (error, stackTrace) {
          completer.completeError(error);
          _pendingLoads.remove(url);
        },
      ));
    } catch (e) {
      completer.completeError(e);
      _pendingLoads.remove(url);
    }
  }

  /// Précharger une image asset
  Future<void> preloadAssetImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath) || _pendingLoads.containsKey(assetPath)) {
      return;
    }

    final completer = Completer<ui.Image>();
    _pendingLoads[assetPath] = completer;

    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();

      _addToCache(assetPath, frame.image);
      completer.complete(frame.image);
      _pendingLoads.remove(assetPath);
    } catch (e) {
      completer.completeError(e);
      _pendingLoads.remove(assetPath);
    }
  }

  /// Obtenir une image du cache
  ui.Image? getCachedImage(String key) {
    return _imageCache[key];
  }

  /// Ajouter au cache avec gestion de la taille
  void _addToCache(String key, ui.Image image) {
    if (_imageCache.length >= _maxCacheSize) {
      // Supprimer la première entrée (FIFO)
      final firstKey = _imageCache.keys.first;
      _imageCache.remove(firstKey);
    }
    _imageCache[key] = image;
  }

  /// Vider le cache
  void clear() {
    _imageCache.clear();
    _pendingLoads.clear();
  }

  /// Retirer une image spécifique
  void remove(String key) {
    _imageCache.remove(key);
  }

  /// Nombre d'images en cache
  int get cacheSize => _imageCache.length;
}

/// Widget d'image optimisée avec placeholder et fade-in
class OptimizedImage extends StatefulWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final BorderRadius? borderRadius;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.borderRadius,
  }) : assert(imageUrl != null || assetPath != null);

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  ImageProvider? _imageProvider;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _loadImage();
  }

  void _loadImage() {
    if (widget.imageUrl != null) {
      _imageProvider = NetworkImage(widget.imageUrl!);
    } else if (widget.assetPath != null) {
      _imageProvider = AssetImage(widget.assetPath!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    if (!_isLoaded && mounted) {
      setState(() => _isLoaded = true);
      _controller.forward();
    }
  }

  void _onImageError() {
    if (mounted) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_hasError) {
      content = widget.errorWidget ?? _buildDefaultError();
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder
          if (!_isLoaded)
            widget.placeholder ?? _buildDefaultPlaceholder(),

          // Image avec fade-in
          if (_imageProvider != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image(
                image: _imageProvider!,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    _onImageLoaded();
                    return child;
                  }
                  return const SizedBox.shrink();
                },
                errorBuilder: (context, error, stackTrace) {
                  _onImageError();
                  return widget.errorWidget ?? _buildDefaultError();
                },
              ),
            ),
        ],
      );
    }

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

/// Widget de placeholder animé (skeleton)
class ImageSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Préchargeur d'images pour une liste
class ImagePreloader {
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls, {
    int batchSize = 5,
  }) async {
    for (int i = 0; i < imageUrls.length; i += batchSize) {
      final batch = imageUrls.skip(i).take(batchSize);
      await Future.wait(
        batch.map((url) => precacheImage(NetworkImage(url), context)),
      );
    }
  }

  static Future<void> preloadAssets(
    BuildContext context,
    List<String> assetPaths,
  ) async {
    await Future.wait(
      assetPaths.map((path) => precacheImage(AssetImage(path), context)),
    );
  }
}
