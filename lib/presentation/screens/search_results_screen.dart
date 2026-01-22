import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/presentation/providers/search_state.dart';
import 'package:iwantsun/presentation/widgets/enhanced_loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/enhanced_error_handler.dart';
import 'package:iwantsun/presentation/widgets/result_filter_sheet.dart';
import 'package:iwantsun/presentation/providers/result_filter_provider.dart';
import 'package:iwantsun/presentation/widgets/empty_state.dart';
import 'package:iwantsun/presentation/widgets/favorite_button.dart';
import 'package:iwantsun/presentation/widgets/interactive_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// Écran d'affichage des résultats de recherche
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  static const int _itemsPerPage = 10;
  int _displayedItemsCount = 10;
  bool _showMapView = false;
  SearchResult? _selectedResult;

  void _loadMore(int totalItems) {
    setState(() {
      _displayedItemsCount = (_displayedItemsCount + _itemsPerPage).clamp(0, totalItems);
    });
  }

  void _toggleView() {
    setState(() {
      _showMapView = !_showMapView;
      _selectedResult = null;
    });
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
            const Text('Résultats'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        actions: [
          // Bouton toggle vue liste/carte
          Consumer<SearchProvider>(
            builder: (context, searchProvider, _) {
              if (searchProvider.hasResults) {
                return IconButton(
                  icon: Icon(_showMapView ? Icons.list : Icons.map),
                  onPressed: _toggleView,
                  tooltip: _showMapView ? 'Vue liste' : 'Vue carte',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer2<SearchProvider, ResultFilterProvider>(
            builder: (context, searchProvider, filterProvider, _) {
              if (searchProvider.hasResults) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        showResultFilters(context);
                      },
                      tooltip: 'Filtres et tri',
                    ),
                    if (filterProvider.activeFiltersCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${filterProvider.activeFiltersCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          final state = provider.state;

          // État de chargement
          if (state is SearchLoading) {
            return _buildLoadingState(context, state);
          }

          // État d'erreur
          if (state is SearchError) {
            return Container(
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
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.95),
                    ],
                  ),
                ),
                child: EnhancedErrorMessage(
                  failure: state.failure,
                  onRetry: () {
                    // Retourner à l'écran de recherche
                    Navigator.of(context).pop();
                  },
                  onDismiss: () {
                    Navigator.of(context).pop();
                  },
                  customActions: {
                    'refineSearch': () {
                      // Retourner pour affiner la recherche
                      Navigator.of(context).pop();
                    },
                    'simplifySearch': () {
                      // Retourner pour simplifier
                      Navigator.of(context).pop();
                    },
                  },
                ),
              ),
            );
          }

          // État vide
          if (state is SearchEmpty) {
            return NoResultsFound(
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          // État initial - rediriger vers l'accueil
          if (state is SearchInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go('/home');
              }
            });
            return const StartSearchPrompt();
          }

          // État de succès avec résultats
          if (state is SearchSuccess) {
            // Initialiser le filter provider avec les résultats
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final filterProvider = context.read<ResultFilterProvider>();
              filterProvider.setResults(state.results);
            });

            return Consumer<ResultFilterProvider>(
              builder: (context, filterProvider, _) {
                // Utiliser les résultats filtrés s'ils existent et ne sont pas vides,
                // sinon utiliser les résultats originaux de l'état
                final filtered = filterProvider.filteredResults;
                final resultsToDisplay = (filtered != null && filtered.isNotEmpty)
                    ? filtered
                    : state.results;
                
                // Debug: vérifier le nombre de résultats
                debugPrint('Results to display: ${resultsToDisplay.length} (original: ${state.results.length}, filtered: ${filtered?.length ?? 0})');
                
                return _showMapView
                    ? _buildMapView(context, resultsToDisplay)
                    : _buildSuccessState(context, resultsToDisplay);
              },
            );
          }

          // État initial (ne devrait pas arriver ici)
          return const StartSearchPrompt();
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, SearchLoading state) {
    return Container(
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
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Skeleton cards en arrière-plan
            ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 80),
                SkeletonCard(),
                SizedBox(height: 16),
                SkeletonCard(),
                SizedBox(height: 16),
                SkeletonCard(),
              ],
            ),
            // Indicateur de chargement amélioré au-dessus
            EnhancedLoadingIndicator(
              loadingState: state,
              onCancel: () {
                // Annuler la recherche et retourner à l'écran précédent
                final provider = context.read<SearchProvider>();
                provider.reset();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, List<SearchResult> results) {
    final displayCount = _displayedItemsCount.clamp(0, results.length);
    final hasMore = displayCount < results.length;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/terrasse.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
        // Header compact avec compteur et pagination
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                Icons.explore,
                color: AppColors.textDark.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$displayCount / ${results.length} destination${results.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const Spacer(),
              if (hasMore)
                Text(
                  '${results.length - displayCount} de plus',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryOrange.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ),
        // Liste des résultats paginés
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).viewPadding.bottom,
            ),
            itemCount: displayCount + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Bouton "Charger plus" en fin de liste
              if (index == displayCount) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _loadMore(results.length),
                      icon: const Icon(Icons.expand_more, size: 20),
                      label: Text('Charger ${(results.length - displayCount).clamp(0, _itemsPerPage)} de plus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DestinationResultCard(result: results[index]),
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildMapView(BuildContext context, List<SearchResult> results) {
    if (results.isEmpty) {
      return const NoResultsFound();
    }

    // Calculer le centre de la carte (moyenne des positions)
    double avgLat = 0;
    double avgLng = 0;
    for (final result in results) {
      avgLat += result.location.latitude;
      avgLng += result.location.longitude;
    }
    avgLat /= results.length;
    avgLng /= results.length;

    // Créer les marqueurs avec rang (1-based)
    final markers = <MapMarker>[];
    for (int i = 0; i < results.length; i++) {
      markers.add(MapMarker.fromSearchResult(results[i], rank: i + 1));
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          // Carte interactive - plein écran avec fitBounds
          InteractiveMap(
            center: LatLng(avgLat, avgLng),
            zoom: 6,
            markers: markers,
            fitBounds: true, // Zoom automatique pour afficher toutes les villes
            boundsPadding: EdgeInsets.fromLTRB(
              50,
              80, // Plus de marge en haut pour le badge de compteur
              50,
              _selectedResult != null ? 250 : 50, // Plus de marge en bas si carte sélectionnée
            ),
            onMarkerTap: (marker) {
              final result = marker.data as SearchResult?;
              if (result != null) {
                setState(() {
                  _selectedResult = result;
                });
              }
            },
          ),

          // Carte de destination sélectionnée en bas (sans bouton favori)
          if (_selectedResult != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedResult = null;
                  });
                },
                child: DestinationResultCard(
                  result: _selectedResult!,
                  showFavorite: false, // Pas de favori sur la carte (superposé avec X)
                ),
              ),
            ),

          // Bouton pour fermer la sélection
          if (_selectedResult != null)
            Positioned(
              right: 24,
              bottom: 200 + MediaQuery.of(context).viewPadding.bottom,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _selectedResult = null;
                  });
                },
                backgroundColor: AppColors.white,
                child: const Icon(Icons.close, color: AppColors.darkGray),
              ),
            ),

          // Indicateur du nombre de résultats
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, size: 18, color: AppColors.primaryOrange),
                  const SizedBox(width: 6),
                  Text(
                    '${results.length} destination${results.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Légende des couleurs
          Positioned(
            left: 16,
            top: 56,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Top 10',
                    style: TextStyle(fontSize: 11, color: AppColors.darkGray),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Autres',
                    style: TextStyle(fontSize: 11, color: AppColors.darkGray),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de résultat compacte pour une destination
class DestinationResultCard extends StatelessWidget {
  final SearchResult result;
  final bool showFavorite; // Si false, n'affiche pas le bouton favori

  const DestinationResultCard({
    super.key,
    required this.result,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : score à gauche, infos au centre, coeur à droite
          Container(
            padding: const EdgeInsets.all(14),
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
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Score à gauche
                _buildScoreBadge(),
                const SizedBox(width: 12),
                // Infos au centre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de la ville
                      Text(
                        result.location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Activités si présentes (couples activité/ville)
                      if (result.activities != null && result.activities!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: result.activities!.take(3).map((activity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getActivityIcon(activity.type),
                                    size: 12,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.displayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        if (result.activities!.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${result.activities!.length - 3} autre${result.activities!.length - 3 > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.white.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                      if (result.location.country != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            result.location.country!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.white.withOpacity(0.85),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _getDistanceText(result),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Coeur à droite (seulement si showFavorite est true)
                if (showFavorite)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
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
                    ),
                  ),
              ],
            ),
          ),
          // Météo et actions
          _buildWeatherSection(context),
        ],
      ),
    );
  }

  /// Calcule la distance si absente en utilisant les paramètres de recherche
  String _getDistanceText(SearchResult result) {
    if (result.location.distanceFromCenter != null) {
      final distance = result.location.distanceFromCenter!;
      return distance < 1
          ? '${(distance * 1000).toStringAsFixed(0)} m'
          : '${distance.toStringAsFixed(1)} km';
    }
    
    // Calculer la distance côté client si absente
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final params = searchProvider.currentParams;
    
    if (params != null) {
      final distance = _calculateHaversineDistance(
        params.centerLatitude,
        params.centerLongitude,
        result.location.latitude,
        result.location.longitude,
      );
      return distance < 1
          ? '${(distance * 1000).toStringAsFixed(0)} m'
          : '${distance.toStringAsFixed(1)} km';
    }
    
    return 'Distance non disponible';
  }

  /// Calcule la distance entre deux points avec la formule de Haversine
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  /// Formate une plage de dates pour l'affichage (Point 14)
  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  /// Obtient la condition météo dominante (Point 14)
  String _getDominantCondition(List<String> conditions) {
    if (conditions.isEmpty) return 'unknown';
    
    final conditionCounts = <String, int>{};
    for (final condition in conditions) {
      conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
    }
    
    String dominant = 'unknown';
    int maxCount = 0;
    conditionCounts.forEach((condition, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = condition;
      }
    });
    
    return dominant;
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.beach:
        return Icons.beach_access;
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.skiing:
        return Icons.snowboarding;
      case ActivityType.surfing:
        return Icons.surfing;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.golf:
        return Icons.sports_golf;
      case ActivityType.camping:
        return Icons.camping;
      default:
        return Icons.sports_soccer;
    }
  }

  Widget _buildScoreBadge() {
    final score = result.overallScore;
    final percentage = score.clamp(0.0, 100.0).toInt();

    Color scoreColor;
    if (percentage >= 80) {
      scoreColor = const Color(0xFF4CAF50);
    } else if (percentage >= 60) {
      scoreColor = const Color(0xFFFF9800);
    } else {
      scoreColor = const Color(0xFFF44336);
    }

    // Tooltip avec décomposition du score (Point 24)
    return Tooltip(
      message: _buildScoreTooltip(),
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              'Score',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.darkGray.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le tooltip avec la décomposition du score (Point 24)
  String _buildScoreTooltip() {
    final weatherScore = result.weatherForecast.weatherScore;
    final activityScore = result.activityScore;
    
    String tooltip = 'Score global : ${result.overallScore.toStringAsFixed(0)}%\n\n';
    tooltip += 'Décomposition :\n';
    tooltip += '• Score météo : ${weatherScore.toStringAsFixed(0)}%\n';
    
    if (activityScore != null) {
      tooltip += '• Score activités : ${activityScore.toStringAsFixed(0)}%\n';
    }
    
    tooltip += '\nLe score météo combine :\n';
    tooltip += '- Température (35%)\n';
    tooltip += '- Conditions (50%)\n';
    tooltip += '- Stabilité (15%)';
    
    return tooltip;
  }

  Widget _buildWeatherSection(BuildContext context) {
    final forecast = result.weatherForecast;
    final conditionText = _getConditionText(forecast.forecasts.isNotEmpty
        ? forecast.forecasts.first.condition
        : 'unknown');
    
    // Afficher le score d'activité si disponible (Point 4)
    final hasActivityScore = result.activityScore != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBeige.withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Ligne 1 : Température et Conditions (sans labels)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Température
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thermostat,
                      color: AppColors.primaryOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${forecast.averageTemperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              // Conditions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getConditionIcon(forecast.forecasts.isNotEmpty
                          ? forecast.forecasts.first.condition
                          : 'unknown'),
                      color: AppColors.primaryOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    conditionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Score d'activité si disponible (Point 4)
          if (hasActivityScore) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Score activités : ${result.activityScore!.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Ligne 2 : Boutons Booking et Partager
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _openBooking(context),
                  icon: const Icon(Icons.hotel, size: 18),
                  label: const Text(
                    'Réserver sur Booking',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580), // Booking blue
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 2,
                    shadowColor: const Color(0xFF003580).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareDestination(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text(
                    'Partager',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: AppColors.primaryOrange.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'partly_cloudy':
        return Icons.wb_cloudy;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.cloud;
    }
  }

  Future<void> _openBooking(BuildContext context) async {
    // Récupérer les dates depuis les prévisions météo
    final forecasts = result.weatherForecast.forecasts;
    
    // Utiliser UTC pour éviter les problèmes de timezone
    final now = DateTime.now().toUtc();
    final checkIn = forecasts.isNotEmpty 
        ? forecasts.first.date.toUtc()
        : now.add(const Duration(days: 1));
    final checkOut = forecasts.isNotEmpty && forecasts.length > 1
        ? forecasts.last.date.toUtc().add(const Duration(days: 1))
        : (forecasts.isNotEmpty 
            ? forecasts.first.date.toUtc().add(const Duration(days: 1))
            : now.add(const Duration(days: 8)));

    // Formater les dates pour Booking.com (YYYY-MM-DD) en UTC pour cohérence
    final checkInStr = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
    final checkOutStr = '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}';

    // Construire l'URL Booking.com avec paramètres
    final cityName = Uri.encodeComponent(result.location.name);
    final bookingUrl = 'https://www.booking.com/searchresults.html'
        '?ss=$cityName'
        '&checkin=$checkInStr'
        '&checkout=$checkOutStr'
        '&order=distance_from_search'; // Tri par distance

    try {
      final uri = Uri.parse(bookingUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir Booking.com'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareDestination(BuildContext context) async {
    final locationName = result.location.name;
    final country = result.location.country ?? '';
    final score = result.overallScore.clamp(0.0, 100.0).toInt();
    final temp = result.weatherForecast.averageTemperature.toStringAsFixed(1);
    final forecasts = result.weatherForecast.forecasts;
    
    // Dates de voyage (Point 14)
    String datesText = '';
    if (forecasts.isNotEmpty) {
      final startDate = forecasts.first.date;
      final endDate = forecasts.length > 1 
          ? forecasts.last.date 
          : forecasts.first.date;
      datesText = '\n📅 ${_formatDateRange(startDate, endDate)}\n';
    }
    
    // Conditions météo dominantes (Point 14)
    String conditionsText = '';
    if (forecasts.isNotEmpty) {
      final dominantCondition = _getDominantCondition(forecasts.map((f) => f.condition).toList());
      conditionsText = '☀️ Conditions : ${_getConditionText(dominantCondition)}\n';
    }
    
    // Activités si disponibles (Point 14)
    String activitiesText = '';
    if (result.activities != null && result.activities!.isNotEmpty) {
      final activityNames = result.activities!.take(3).map((a) => a.displayName).join(', ');
      activitiesText = '🎯 Activités : $activityNames\n';
    }

    // Texte de partage amélioré (Point 14)
    final shareText = '🌟 Découvrez $locationName${country.isNotEmpty ? ', $country' : ''} !\n\n'
        '⭐ Score de compatibilité : $score%\n'
        '🌡️ Température moyenne : ${temp}°C\n'
        '$conditionsText'
        '$activitiesText'
        '$datesText'
        '\nTrouvé via IWantSun 🌞\n'
        '#IWantSun #Voyage #Météo';

    await SharePlus.instance.share(ShareParams(text: shareText));

    // Enregistrer le partage dans la gamification
    try {
      await GamificationService().recordShare();
    } catch (e) {
      // Ignorer les erreurs de gamification
    }

    // Tracker dans les analytics
    AnalyticsService().trackShare(result.location.id, 'native_share');
  }

  String _getConditionText(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Ensoleillé';
      case 'partly_cloudy':
        return 'Partiellement nuageux';
      case 'cloudy':
        return 'Nuageux';
      case 'rain':
        return 'Pluvieux';
      case 'snow':
        return 'Neigeux';
      default:
        return 'Variable';
    }
  }
}
