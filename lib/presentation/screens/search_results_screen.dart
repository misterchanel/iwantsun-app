import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
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

          // État de succès avec résultats
          if (state is SearchSuccess) {
            // Initialiser le filter provider avec les résultats
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final filterProvider = context.read<ResultFilterProvider>();
              filterProvider.setResults(state.results);
            });

            return Consumer<ResultFilterProvider>(
              builder: (context, filterProvider, _) {
                final resultsToDisplay =
                    filterProvider.filteredResults ?? state.results;
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
                      Text(
                        result.location.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.location.country != null)
                        Text(
                          result.location.country!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.white.withOpacity(0.9),
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
                            '${result.location.distanceFromCenter?.toStringAsFixed(0) ?? '?'} km',
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

    return Container(
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
    );
  }

  Widget _buildWeatherSection(BuildContext context) {
    final forecast = result.weatherForecast;
    final conditionText = _getConditionText(forecast.forecasts.isNotEmpty
        ? forecast.forecasts.first.condition
        : 'unknown');

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
    final checkIn = forecasts.isNotEmpty ? forecasts.first.date : DateTime.now().add(const Duration(days: 1));
    final checkOut = forecasts.isNotEmpty ? forecasts.last.date.add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 8));

    // Formater les dates pour Booking.com (YYYY-MM-DD)
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

    final shareText = '🌟 Découvrez $locationName$country !\n\n'
        'Score de compatibilité : $score%\n'
        'Température moyenne : ${temp}°C\n\n'
        'Trouvé via IWantSun 🌞';

    await Share.share(shareText);

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
