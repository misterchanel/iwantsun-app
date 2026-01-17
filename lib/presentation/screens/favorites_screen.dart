import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/favorites_service.dart';
import 'package:iwantsun/domain/entities/favorite.dart';
import 'package:iwantsun/presentation/widgets/empty_state.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';

/// Écran d'affichage des destinations favorites
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<Favorite>? _favorites;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final favorites = await _favoritesService.getFavorites();

    if (mounted) {
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(Favorite favorite) async {
    final success = await _favoritesService.removeFavorite(favorite.id);

    if (success && mounted) {
      setState(() {
        _favorites?.removeWhere((f) => f.id == favorite.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${favorite.locationName} retiré des favoris'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () {
              // TODO: Implémenter undo
            },
          ),
        ),
      );
    }
  }

  Future<void> _shareAllFavorites() async {
    final text = await _favoritesService.exportFavorites();
    await Share.share(text);
  }

  Future<void> _clearAllFavorites() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les favoris ?'),
        content: const Text(
          'Cette action est irréversible. Tous vos favoris seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _favoritesService.clearAllFavorites();
      await _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  size: 24,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Mes Favoris'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        actions: [
          if (_favorites != null && _favorites!.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAllFavorites,
              tooltip: 'Partager',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _clearAllFavorites();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.errorRed),
                      SizedBox(width: 8),
                      Text('Tout supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/terrasse.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cream.withOpacity(0.85),
                AppColors.cream.withOpacity(0.90),
              ],
            ),
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(
          message: 'Chargement de vos favoris...',
        ),
      );
    }

    if (_favorites == null || _favorites!.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun favori',
        message:
            'Vous n\'avez pas encore ajouté de destination favorite.\n\nCommencez par faire une recherche et ajoutez vos destinations préférées !',
        actionLabel: 'Faire une recherche',
        onAction: () => Navigator.of(context).pop(),
      );
    }

    return Column(
      children: [
        // Header avec compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBeige,
            border: Border(
              bottom: BorderSide(
                color: AppColors.mediumGray.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.errorRed,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_favorites!.length} destination${_favorites!.length > 1 ? 's' : ''} favorite${_favorites!.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Liste des favoris
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFavorites,
            color: AppColors.primaryOrange,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites!.length,
              itemBuilder: (context, index) {
                return FavoriteCard(
                  favorite: _favorites![index],
                  onRemove: () => _removeFavorite(_favorites![index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Card pour afficher un favori
class FavoriteCard extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onRemove;

  const FavoriteCard({
    super.key,
    required this.favorite,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final score = favorite.overallScore.clamp(0.0, 100.0).toInt();
    Color scoreColor;
    if (score >= 80) {
      scoreColor = const Color(0xFF4CAF50);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFFF9800);
    } else {
      scoreColor = const Color(0xFFF44336);
    }

    return Dismissible(
      key: Key(favorite.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Supprimer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retirer des favoris ?'),
            content: Text(
              'Voulez-vous retirer ${favorite.locationName} de vos favoris ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Retirer'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOrange,
                    AppColors.sunsetOrange,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.locationName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (favorite.country != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            favorite.country!,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.darkGray.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Infos météo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfo(
                    icon: Icons.thermostat,
                    label: 'Température',
                    value: '${favorite.averageTemperature.toStringAsFixed(1)}°C',
                  ),
                  _buildInfo(
                    icon: Icons.wb_sunny,
                    label: 'Jours ensoleillés',
                    value: '${favorite.sunnyDays}',
                  ),
                ],
              ),
            ),
            if (favorite.notes != null && favorite.notes!.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 20,
                      color: AppColors.mediumGray,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        favorite.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryOrange,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkGray.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
