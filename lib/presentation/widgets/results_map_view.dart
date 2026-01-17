import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/presentation/widgets/interactive_map.dart';
import 'package:iwantsun/presentation/widgets/animated_card.dart';

/// Vue carte des résultats de recherche
class ResultsMapView extends StatefulWidget {
  final List<SearchResult> results;
  final SearchResult? selectedResult;
  final Function(SearchResult)? onResultSelected;
  final bool showFullScreenButton;

  const ResultsMapView({
    super.key,
    required this.results,
    this.selectedResult,
    this.onResultSelected,
    this.showFullScreenButton = true,
  });

  @override
  State<ResultsMapView> createState() => _ResultsMapViewState();
}

class _ResultsMapViewState extends State<ResultsMapView> {
  late LatLng _center;
  late List<MapMarker> _markers;

  @override
  void initState() {
    super.initState();
    _updateMapData();
  }

  @override
  void didUpdateWidget(ResultsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) {
      _updateMapData();
    }
  }

  void _updateMapData() {
    if (widget.results.isEmpty) {
      _center = const LatLng(46.2276, 2.2137); // Centre de la France
      _markers = [];
      return;
    }

    // Créer les marqueurs
    _markers = widget.results.map((result) {
      return MapMarker.fromDestination(result);
    }).toList();

    // Calculer le centre de la carte (moyenne des positions)
    double sumLat = 0;
    double sumLng = 0;
    for (final result in widget.results) {
      sumLat += result.location.latitude;
      sumLng += result.location.longitude;
    }
    _center = LatLng(
      sumLat / widget.results.length,
      sumLng / widget.results.length,
    );
  }

  void _showFullScreenMap() {
    FullScreenMapDialog.show(
      context,
      center: _center,
      markers: _markers,
      title: '${widget.results.length} destinations trouvées',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedCard(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.map,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vue carte',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        '${widget.results.length} destination${widget.results.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showFullScreenButton)
                  IconButton(
                    onPressed: _showFullScreenMap,
                    icon: const Icon(Icons.fullscreen),
                    tooltip: 'Plein écran',
                  ),
              ],
            ),
          ),

          // Carte
          InteractiveMap(
            center: _center,
            markers: _markers,
            height: 300,
            zoom: _calculateZoom(),
            onMarkerTap: (marker) {
              if (marker.data is SearchResult) {
                widget.onResultSelected?.call(marker.data as SearchResult);
                _showResultDetails(marker.data as SearchResult);
              }
            },
          ),

          // Légende
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(
                  color: AppColors.primaryOrange,
                  icon: Icons.location_on,
                  label: 'Destination',
                ),
                _buildLegendItem(
                  color: AppColors.primaryBlue,
                  icon: Icons.hotel,
                  label: 'Hôtel',
                ),
                _buildLegendItem(
                  color: const Color(0xFF4CAF50),
                  icon: Icons.attractions,
                  label: 'Activité',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }

  double _calculateZoom() {
    if (widget.results.isEmpty) return 6;
    if (widget.results.length == 1) return 13;

    // Calculer la distance maximale entre les points pour ajuster le zoom
    double maxDistance = 0;
    for (int i = 0; i < widget.results.length; i++) {
      for (int j = i + 1; j < widget.results.length; j++) {
        final distance = const Distance().distance(
          LatLng(
            widget.results[i].location.latitude,
            widget.results[i].location.longitude,
          ),
          LatLng(
            widget.results[j].location.latitude,
            widget.results[j].location.longitude,
          ),
        );
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }
    }

    // Ajuster le zoom en fonction de la distance maximale (en mètres)
    if (maxDistance < 10000) return 12; // < 10 km
    if (maxDistance < 50000) return 10; // < 50 km
    if (maxDistance < 100000) return 9; // < 100 km
    if (maxDistance < 200000) return 8; // < 200 km
    if (maxDistance < 500000) return 7; // < 500 km
    return 6; // > 500 km
  }

  void _showResultDetails(SearchResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.location.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.location.country,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange,
                        AppColors.primaryOrange.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.matchScore}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Météo
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Température moyenne: ${result.weatherScore.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Distance
            Row(
              children: [
                const Icon(
                  Icons.place,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Distance: ${result.distanceScore.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton voir détails
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onResultSelected?.call(result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir les détails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton pour basculer entre vue liste et vue carte
class ViewToggleButton extends StatelessWidget {
  final bool isMapView;
  final VoidCallback onToggle;

  const ViewToggleButton({
    super.key,
    required this.isMapView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onToggle,
      backgroundColor: AppColors.primaryOrange,
      icon: Icon(
        isMapView ? Icons.list : Icons.map,
        color: Colors.white,
      ),
      label: Text(
        isMapView ? 'Vue liste' : 'Vue carte',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
