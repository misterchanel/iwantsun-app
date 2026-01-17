import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/favorites_service.dart';
import 'package:iwantsun/presentation/providers/favorites_provider.dart';
import 'package:iwantsun/domain/entities/search_result.dart';

/// Bouton cœur pour ajouter/retirer des favoris
class FavoriteButton extends StatefulWidget {
  final SearchResult result;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.result,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.onToggle,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isAnimating = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _checkFavoriteStatus();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check favorite status when widget updates
    if (oldWidget.result.location.id != widget.result.location.id) {
      _checkFavoriteStatus();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.result.location.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isAnimating) return;

    setState(() => _isAnimating = true);

    // Animation
    await _animationController.forward();
    await _animationController.reverse();

    if (_isFavorite) {
      // Retirer des favoris
      final success = await _favoritesService.removeFavoriteByLocationId(
        widget.result.location.id,
      );

      if (success && mounted) {
        setState(() => _isFavorite = false);
        _showSnackBar('Retiré des favoris');

        // Notify the provider to refresh
        try {
          final provider = context.read<FavoritesProvider>();
          provider.refresh();
        } catch (_) {}
      }
    } else {
      // Ajouter aux favoris
      final success = await _favoritesService.addFavorite(widget.result);

      if (success && mounted) {
        setState(() => _isFavorite = true);
        _showSnackBar('Ajouté aux favoris');

        // Notify the provider to refresh
        try {
          final provider = context.read<FavoritesProvider>();
          provider.refresh();
        } catch (_) {}
      }
    }

    setState(() => _isAnimating = false);
    widget.onToggle?.call();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(
            widget.inactiveColor ?? AppColors.mediumGray,
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          size: widget.size,
          color: _isFavorite
              ? (widget.activeColor ?? AppColors.errorRed)
              : (widget.inactiveColor ?? AppColors.mediumGray),
        ),
        onPressed: _isAnimating ? null : _toggleFavorite,
        tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// Version compacte du bouton favori (pour les cards)
class CompactFavoriteButton extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onToggle;

  const CompactFavoriteButton({
    super.key,
    required this.result,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FavoriteButton(
        result: result,
        size: 20,
        activeColor: AppColors.errorRed,
        inactiveColor: AppColors.darkGray,
        onToggle: onToggle,
      ),
    );
  }
}
