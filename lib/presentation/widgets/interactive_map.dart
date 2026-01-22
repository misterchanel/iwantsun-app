import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/entities/hotel.dart';
import 'package:iwantsun/domain/entities/activity.dart';

/// Carte interactive avec OpenStreetMap
class InteractiveMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final List<MapMarker> markers;
  final Function(MapMarker)? onMarkerTap;
  final double? height;
  final bool showControls;
  final bool enableInteraction;
  final bool fitBounds; // Si true, zoom automatique pour afficher tous les marqueurs
  final EdgeInsets boundsPadding; // Padding autour des bounds

  const InteractiveMap({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.markers = const [],
    this.onMarkerTap,
    this.height,
    this.showControls = true,
    this.enableInteraction = true,
    this.fitBounds = false,
    this.boundsPadding = const EdgeInsets.all(50),
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  late MapController _mapController;
  bool _hasFittedBounds = false;
  LatLngBounds? _currentBounds; // Stocker les bounds pour le recentrage

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Calcule les bounds pour afficher tous les marqueurs
  LatLngBounds? _calculateBounds() {
    if (widget.markers.isEmpty) return null;
    if (widget.markers.length == 1) return null; // Un seul marqueur, pas besoin de bounds

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in widget.markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Ajouter un peu de marge
    final latMargin = (maxLat - minLat) * 0.1;
    final lngMargin = (maxLng - minLng) * 0.1;

    return LatLngBounds(
      LatLng(minLat - latMargin, minLng - lngMargin),
      LatLng(maxLat + latMargin, maxLng + lngMargin),
    );
  }

  void _fitMapToBounds({bool force = false}) {
    if (!widget.fitBounds || (_hasFittedBounds && !force)) return;

    final bounds = _calculateBounds();
    if (bounds != null) {
      _currentBounds = bounds; // Stocker les bounds pour le recentrage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: widget.boundsPadding,
            ),
          );
          _hasFittedBounds = true;
        }
      });
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _centerMap() {
    // Si des bounds ont été calculés, recentrer dessus
    if (_currentBounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: _currentBounds!,
          padding: widget.boundsPadding,
        ),
      );
    } else {
      _mapController.move(widget.center, widget.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapWidget = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: InteractionOptions(
              flags: widget.enableInteraction
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
            onMapReady: () {
              // Fit bounds quand la carte est prête avec un léger délai
              // pour s'assurer que les tuiles sont chargées
              if (widget.fitBounds && !_hasFittedBounds) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _fitMapToBounds();
                  }
                });
              }
            },
          ),
            children: [
              // Tuiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.iwantsun.app',
                maxZoom: 19,
                tileProvider: NetworkTileProvider(),
                // Rendu instantané pour éviter le flou
                tileDisplay: const TileDisplay.instantaneous(),
                // Forcer le rafraîchissement des tuiles
                keepBuffer: 5,
              ),

              // Marqueurs avec clustering (Point 15)
              if (widget.markers.isNotEmpty)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80, // Rayon maximum pour créer un cluster (en pixels)
                    size: const Size(40, 40),
                    markers: widget.markers.map((mapMarker) {
                      return Marker(
                        point: mapMarker.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => widget.onMarkerTap?.call(mapMarker),
                          child: _buildMarkerIcon(mapMarker),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      // Widget personnalisé pour les clusters
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${markers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    // Animation lors de la création/suppression de clusters
                    animate: true,
                    // Zoom automatique lors du clic sur un cluster
                    zoomToBoundsOnClick: true,
                    // Taille minimale du cluster (en pixels)
                    disableClusteringAtZoom: 15, // Désactiver le clustering au zoom 15+
                  ),
                ),

              // Attribution (obligatoire pour OSM)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // Contrôles de zoom
          if (widget.showControls)
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                children: [
                  _buildControlButton(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                    tooltip: 'Zoom avant',
                  ),
                  const SizedBox(height: 8),
                  _buildControlButton(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                    tooltip: 'Zoom arrière',
                  ),
                  const SizedBox(height: 8),
                  _buildControlButton(
                    icon: Icons.my_location,
                    onPressed: _centerMap,
                    tooltip: 'Centrer',
                  ),
                ],
              ),
            ),
        ],
      );

    // Si height est spécifié, utiliser SizedBox, sinon retourner directement le widget
    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        child: mapWidget,
      );
    }
    return mapWidget;
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.darkGray,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerIcon(MapMarker marker) {
    Color markerColor;
    IconData markerIcon;

    switch (marker.type) {
      case MarkerType.destination:
        // Si top 10, utiliser vert, sinon orange
        markerColor = marker.isTopTen
            ? const Color(0xFF4CAF50) // Vert pour top 10
            : AppColors.primaryOrange;
        markerIcon = Icons.location_on;
        break;
      case MarkerType.hotel:
        markerColor = AppColors.primaryBlue;
        markerIcon = Icons.hotel;
        break;
      case MarkerType.activity:
        markerColor = const Color(0xFF4CAF50);
        markerIcon = Icons.attractions;
        break;
      case MarkerType.currentLocation:
        markerColor = const Color(0xFFF44336);
        markerIcon = Icons.my_location;
        break;
    }

    // Si un rang est défini, afficher le numéro au lieu de l'icône
    if (marker.rank != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: markerColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${marker.rank}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: markerColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        markerIcon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

/// Type de marqueur
enum MarkerType {
  destination,
  hotel,
  activity,
  currentLocation,
}

/// Marqueur sur la carte
class MapMarker {
  final String id;
  final LatLng position;
  final MarkerType type;
  final String title;
  final String? subtitle;
  final dynamic data; // Données associées (DestinationResult, Hotel, Activity, etc.)
  final int? rank; // Rang pour affichage numéroté (1-based)
  final bool isTopTen; // Si dans les 10 premiers (couleur verte)

  const MapMarker({
    required this.id,
    required this.position,
    required this.type,
    required this.title,
    this.subtitle,
    this.data,
    this.rank,
    this.isTopTen = false,
  });

  factory MapMarker.fromSearchResult(SearchResult result, {int? rank}) {
    return MapMarker(
      id: 'dest_${result.location.latitude}_${result.location.longitude}',
      position: LatLng(result.location.latitude, result.location.longitude),
      type: MarkerType.destination,
      title: result.location.name,
      subtitle: '${result.overallScore.toInt()}% de correspondance',
      data: result,
      rank: rank,
      isTopTen: rank != null && rank <= 10,
    );
  }

  factory MapMarker.fromHotel(Hotel hotel) {
    return MapMarker(
      id: 'hotel_${hotel.id}',
      position: LatLng(hotel.latitude ?? 0, hotel.longitude ?? 0),
      type: MarkerType.hotel,
      title: hotel.name,
      subtitle: hotel.address,
      data: hotel,
    );
  }

  factory MapMarker.fromActivity(Activity activity) {
    return MapMarker(
      id: 'activity_${activity.name.hashCode}',
      position: LatLng(activity.latitude ?? 0, activity.longitude ?? 0),
      type: MarkerType.activity,
      title: activity.name,
      subtitle: activity.displayName,
      data: activity,
    );
  }

  factory MapMarker.currentLocation(double latitude, double longitude) {
    return MapMarker(
      id: 'current_location',
      position: LatLng(latitude, longitude),
      type: MarkerType.currentLocation,
      title: 'Ma position',
    );
  }
}

/// Widget carte compacte pour preview
class CompactMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? label;
  final double height;
  final double zoom;
  final VoidCallback? onTap;

  const CompactMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label,
    this.height = 150,
    this.zoom = 13,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            InteractiveMap(
              center: LatLng(latitude, longitude),
              zoom: zoom,
              height: height,
              showControls: false,
              enableInteraction: false,
              markers: [
                MapMarker(
                  id: 'location',
                  position: LatLng(latitude, longitude),
                  type: MarkerType.destination,
                  title: label ?? 'Emplacement',
                ),
              ],
            ),
            if (onTap != null)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                  child: const Center(
                    child: Icon(
                      Icons.zoom_out_map,
                      color: Colors.white,
                      size: 32,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
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

/// Dialogue carte plein écran
class FullScreenMapDialog extends StatelessWidget {
  final LatLng center;
  final List<MapMarker> markers;
  final String title;

  const FullScreenMapDialog({
    super.key,
    required this.center,
    required this.markers,
    this.title = 'Carte',
  });

  static void show(
    BuildContext context, {
    required LatLng center,
    required List<MapMarker> markers,
    String title = 'Carte',
  }) {
    showDialog(
      context: context,
      builder: (context) => FullScreenMapDialog(
        center: center,
        markers: markers,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Carte
          Expanded(
            child: InteractiveMap(
              center: center,
              markers: markers,
              zoom: 12,
              onMarkerTap: (marker) {
                _showMarkerInfo(context, marker);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkerInfo(BuildContext context, MapMarker marker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForType(marker.type),
                  color: _getColorForType(marker.type),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (marker.subtitle != null)
                        Text(
                          marker.subtitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mediumGray,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Coordonnées: ${marker.position.latitude.toStringAsFixed(4)}, ${marker.position.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(MarkerType type) {
    switch (type) {
      case MarkerType.destination:
        return Icons.location_on;
      case MarkerType.hotel:
        return Icons.hotel;
      case MarkerType.activity:
        return Icons.attractions;
      case MarkerType.currentLocation:
        return Icons.my_location;
    }
  }

  Color _getColorForType(MarkerType type) {
    switch (type) {
      case MarkerType.destination:
        return AppColors.primaryOrange;
      case MarkerType.hotel:
        return AppColors.primaryBlue;
      case MarkerType.activity:
        return const Color(0xFF4CAF50);
      case MarkerType.currentLocation:
        return const Color(0xFFF44336);
    }
  }
}
