import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/animations/list_animations.dart';
import 'package:iwantsun/domain/entities/favorite.dart';
import 'package:iwantsun/presentation/providers/favorites_provider.dart';
import 'package:iwantsun/presentation/widgets/empty_state.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/animated_card.dart';
import 'package:iwantsun/presentation/widgets/interactive_map.dart';

/// Écran des favoris amélioré avec statistiques et carte
class FavoritesScreenEnhanced extends StatefulWidget {
  const FavoritesScreenEnhanced({super.key});

  @override
  State<FavoritesScreenEnhanced> createState() => _FavoritesScreenEnhancedState();
}

class _FavoritesScreenEnhancedState extends State<FavoritesScreenEnhanced>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FavoritesSortOption _sortOption = FavoritesSortOption.dateDesc;
  String? _selectedCountry;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Charger les données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.lightBeige],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFavoritesTab(),
                    _buildStatisticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes Favoris',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Consumer<FavoritesProvider>(
                      builder: (context, provider, _) => Text(
                        '${provider.favoritesCount} destination${provider.favoritesCount > 1 ? 's' : ''} sauvegardée${provider.favoritesCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        if (provider.favorites.isEmpty) return const SizedBox.shrink();

        return Row(
          children: [
            IconButton(
              onPressed: () async {
                final text = await provider.exportFavorites();
                await Share.share(text);
              },
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Partager',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'clear') {
                  _showClearConfirmation();
                } else if (value == 'sort') {
                  _showSortOptions();
                } else if (value == 'filter') {
                  _showFilterOptions();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: AppColors.darkGray),
                      SizedBox(width: 8),
                      Text('Trier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: AppColors.darkGray),
                      SizedBox(width: 8),
                      Text('Filtrer'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.errorRed),
                      SizedBox(width: 8),
                      Text('Tout supprimer', style: TextStyle(color: AppColors.errorRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.darkGray,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 20),
                SizedBox(width: 8),
                Text('Favoris'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 20),
                SizedBox(width: 8),
                Text('Statistiques'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFavorites) {
          return const Center(
            child: LoadingIndicator(
              message: 'Chargement de vos favoris...',
            ),
          );
        }

        if (provider.favorites.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border,
            title: 'Aucun favori',
            message: 'Vous n\'avez pas encore ajouté de destination favorite.\n\nCommencez par faire une recherche !',
            actionLabel: 'Rechercher',
            onAction: () => Navigator.of(context).pop(),
          );
        }

        // Appliquer les filtres
        List<Favorite> displayedFavorites = provider.favorites;
        if (_selectedCountry != null) {
          displayedFavorites = provider.filterByCountry(_selectedCountry);
        }

        return Column(
          children: [
            // Filtre actif
            if (_selectedCountry != null)
              _buildActiveFilter(),

            // Toggle carte/liste
            if (!_showMap)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.loadFavorites,
                  color: AppColors.primaryOrange,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayedFavorites.length,
                    itemBuilder: (context, index) {
                      return AnimatedListItem(
                        index: index,
                        child: _FavoriteCardEnhanced(
                          favorite: displayedFavorites[index],
                          onRemove: () => _removeFavorite(displayedFavorites[index]),
                          onEdit: () => _editNotes(displayedFavorites[index]),
                          onShowOnMap: () => _showOnMap(displayedFavorites[index]),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: _buildMapView(displayedFavorites),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActiveFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            'Pays: $_selectedCountry',
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selectedCountry = null),
            child: const Icon(Icons.close, size: 18, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(List<Favorite> favorites) {
    if (favorites.isEmpty) {
      return const Center(child: Text('Aucun favori à afficher'));
    }

    final markers = favorites.map((f) => MapMarker(
      id: f.id,
      position: LatLng(f.latitude, f.longitude),
      type: MarkerType.destination,
      title: f.locationName,
      subtitle: '${f.overallScore.toInt()}% • ${f.averageTemperature.toStringAsFixed(1)}°C',
      data: f,
    )).toList();

    // Calculer le centre
    double sumLat = 0, sumLng = 0;
    for (final f in favorites) {
      sumLat += f.latitude;
      sumLng += f.longitude;
    }
    final center = LatLng(sumLat / favorites.length, sumLng / favorites.length);

    return Column(
      children: [
        Expanded(
          child: InteractiveMap(
            center: center,
            markers: markers,
            zoom: 5,
            onMarkerTap: (marker) {
              if (marker.data is Favorite) {
                _showFavoriteDetails(marker.data as Favorite);
              }
            },
          ),
        ),
        // Légende
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${favorites.length} favori${favorites.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        if (provider.favorites.isEmpty) {
          return const Center(
            child: Text(
              'Ajoutez des favoris pour voir vos statistiques',
              style: TextStyle(color: AppColors.mediumGray),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques principales
              _buildStatCard(
                title: 'Vos destinations',
                children: [
                  _buildStatRow(
                    icon: Icons.favorite,
                    label: 'Total favoris',
                    value: '${provider.favoritesCount}',
                    color: AppColors.errorRed,
                  ),
                  _buildStatRow(
                    icon: Icons.public,
                    label: 'Pays différents',
                    value: '${provider.uniqueCountries.length}',
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistiques météo
              _buildStatCard(
                title: 'Météo moyenne',
                children: [
                  _buildStatRow(
                    icon: Icons.star,
                    label: 'Score moyen',
                    value: '${provider.averageScore.toStringAsFixed(0)}%',
                    color: AppColors.primaryOrange,
                  ),
                  _buildStatRow(
                    icon: Icons.thermostat,
                    label: 'Température moyenne',
                    value: '${provider.averageTemperature.toStringAsFixed(1)}°C',
                    color: Colors.orange,
                  ),
                  _buildStatRow(
                    icon: Icons.wb_sunny,
                    label: 'Jours ensoleillés (total)',
                    value: '${provider.totalSunnyDays}',
                    color: Colors.amber,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Répartition par pays
              if (provider.uniqueCountries.isNotEmpty)
                _buildCountriesCard(provider),

              const SizedBox(height: 16),

              // Top destinations
              _buildTopDestinationsCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required List<Widget> children,
  }) {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.darkGray,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesCard(FavoritesProvider provider) {
    final countryCount = <String, int>{};
    for (final f in provider.favorites) {
      if (f.country != null) {
        countryCount[f.country!] = (countryCount[f.country!] ?? 0) + 1;
      }
    }

    final sortedCountries = countryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Par pays',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedCountries.take(5).map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: AppColors.darkGray),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopDestinationsCard(FavoritesProvider provider) {
    final topFavorites = List<Favorite>.from(provider.favorites)
      ..sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Top destinations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topFavorites.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final favorite = entry.value;
            final medal = index == 0 ? '🥇' : (index == 1 ? '🥈' : '🥉');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(medal, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.locationName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (favorite.country != null)
                          Text(
                            favorite.country!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mediumGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${favorite.overallScore.toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget? _buildFAB() {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        if (provider.favorites.isEmpty || _tabController.index == 1) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () => setState(() => _showMap = !_showMap),
          backgroundColor: AppColors.primaryOrange,
          icon: Icon(
            _showMap ? Icons.list : Icons.map,
            color: Colors.white,
          ),
          label: Text(
            _showMap ? 'Liste' : 'Carte',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trier par',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...FavoritesSortOption.values.map((option) => ListTile(
              leading: Icon(option.icon, color: AppColors.primaryOrange),
              title: Text(option.label),
              trailing: _sortOption == option
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                setState(() => _sortOption = option);
                context.read<FavoritesProvider>().sortFavorites(option);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    final provider = context.read<FavoritesProvider>();
    final countries = provider.uniqueCountries.toList()..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par pays',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Tous les pays'),
              trailing: _selectedCountry == null
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                setState(() => _selectedCountry = null);
                Navigator.pop(context);
              },
            ),
            ...countries.map((country) => ListTile(
              leading: const Icon(Icons.flag),
              title: Text(country),
              trailing: _selectedCountry == country
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                setState(() => _selectedCountry = country);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les favoris ?'),
        content: const Text(
          'Cette action est irréversible. Tous vos favoris seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<FavoritesProvider>().clearAllFavorites();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tous les favoris ont été supprimés')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(Favorite favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer des favoris ?'),
        content: Text('Voulez-vous retirer ${favorite.locationName} de vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FavoritesProvider>().removeFavorite(favorite.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${favorite.locationName} retiré des favoris')),
      );
    }
  }

  void _editNotes(Favorite favorite) {
    final controller = TextEditingController(text: favorite.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes personnelles'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ajoutez vos notes sur cette destination...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<FavoritesProvider>().updateNotes(
                favorite.id,
                controller.text.isEmpty ? null : controller.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes mises à jour')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showOnMap(Favorite favorite) {
    FullScreenMapDialog.show(
      context,
      center: LatLng(favorite.latitude, favorite.longitude),
      markers: [
        MapMarker(
          id: favorite.id,
          position: LatLng(favorite.latitude, favorite.longitude),
          type: MarkerType.destination,
          title: favorite.locationName,
          subtitle: favorite.country,
          data: favorite,
        ),
      ],
      title: favorite.locationName,
    );
  }

  void _showFavoriteDetails(Favorite favorite) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          color: AppColors.textDark,
                        ),
                      ),
                      if (favorite.country != null)
                        Text(
                          favorite.country!,
                          style: const TextStyle(
                            color: AppColors.mediumGray,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${favorite.overallScore.toInt()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  icon: Icons.thermostat,
                  value: '${favorite.averageTemperature.toStringAsFixed(1)}°C',
                  label: 'Température',
                ),
                _buildDetailItem(
                  icon: Icons.wb_sunny,
                  value: '${favorite.sunnyDays}',
                  label: 'Jours ensoleillés',
                ),
              ],
            ),
            if (favorite.notes != null && favorite.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, color: AppColors.mediumGray, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        favorite.notes!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.darkGray,
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

  Widget _buildDetailItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}

/// Carte de favori améliorée
class _FavoriteCardEnhanced extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onShowOnMap;

  const _FavoriteCardEnhanced({
    required this.favorite,
    required this.onRemove,
    required this.onEdit,
    required this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final score = favorite.overallScore.clamp(0.0, 100.0).toInt();
    final scoreColor = score >= 80
        ? const Color(0xFF4CAF50)
        : (score >= 60 ? const Color(0xFFFF9800) : const Color(0xFFF44336));

    return GlowCard(
      glowColor: AppColors.primaryOrange,
      glowIntensity: 5,
      animate: false,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (favorite.country != null)
                        Text(
                          favorite.country!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const Text(
                        'Score',
                        style: TextStyle(fontSize: 10, color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Infos météo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfo(
                  icon: Icons.thermostat,
                  value: '${favorite.averageTemperature.toStringAsFixed(1)}°C',
                  label: 'Température',
                ),
                _buildInfo(
                  icon: Icons.wb_sunny,
                  value: '${favorite.sunnyDays}',
                  label: 'Jours ensoleillés',
                ),
              ],
            ),
          ),

          // Notes
          if (favorite.notes != null && favorite.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: AppColors.mediumGray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        favorite.notes!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.darkGray,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onShowOnMap,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Carte'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Notes'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkGray,
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Retirer'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.mediumGray),
        ),
      ],
    );
  }
}
