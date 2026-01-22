# Guide d'Intégration des Cartes Interactives

## Vue d'ensemble

L'application IWantSun intègre maintenant des cartes interactives basées sur OpenStreetMap (OSM) via le package `flutter_map`. Cette intégration permet d'afficher visuellement les destinations, hôtels et activités sur une carte interactive.

---

## 📦 Packages Utilisés

- **`flutter_map: ^6.1.0`** - Widget de carte Flutter avec tuiles OSM
- **`latlong2: ^0.9.0`** - Gestion des coordonnées géographiques (latitude/longitude)
- **OpenStreetMap** - Tuiles de carte gratuites et open-source

---

## 🗺️ Widgets Créés

### 1. `InteractiveMap`

Widget de base pour afficher une carte interactive avec marqueurs personnalisés.

```dart
InteractiveMap(
  center: LatLng(48.8566, 2.3522), // Paris
  zoom: 13.0,
  markers: [
    MapMarker(
      id: 'paris',
      position: LatLng(48.8566, 2.3522),
      type: MarkerType.destination,
      title: 'Paris',
    ),
  ],
  onMarkerTap: (marker) {
    print('Marqueur tapé: ${marker.title}');
  },
  height: 400,
  showControls: true,
  enableInteraction: true,
)
```

**Propriétés** :
- `center` (LatLng) - Centre initial de la carte
- `zoom` (double) - Niveau de zoom (3-18)
- `markers` (List<MapMarker>) - Liste des marqueurs à afficher
- `onMarkerTap` (Function?) - Callback lors du tap sur un marqueur
- `height` (double?) - Hauteur de la carte (défaut: 400)
- `showControls` (bool) - Afficher les boutons de zoom (défaut: true)
- `enableInteraction` (bool) - Autoriser les interactions (défaut: true)

---

### 2. `MapMarker`

Classe représentant un marqueur sur la carte.

```dart
// Depuis une destination
MapMarker.fromDestination(destinationResult)

// Depuis un hôtel
MapMarker.fromHotel(hotel)

// Depuis une activité
MapMarker.fromActivity(activity)

// Position actuelle
MapMarker.currentLocation(latitude, longitude)

// Personnalisé
MapMarker(
  id: 'custom_marker',
  position: LatLng(45.764, 4.835),
  type: MarkerType.destination,
  title: 'Ma destination',
  subtitle: 'Description optionnelle',
  data: customData, // Données associées
)
```

**Types de marqueurs** :
- `MarkerType.destination` - Orange avec icône location_on
- `MarkerType.hotel` - Bleu avec icône hotel
- `MarkerType.activity` - Vert avec icône attractions
- `MarkerType.currentLocation` - Rouge avec icône my_location

---

### 3. `CompactMap`

Carte compacte non-interactive pour les aperçus.

```dart
CompactMap(
  latitude: 48.8566,
  longitude: 2.3522,
  label: 'Paris',
  height: 150,
  zoom: 13,
  onTap: () {
    // Ouvrir la carte en plein écran
  },
)
```

**Utilisation typique** :
- Aperçu dans une card de résultat
- Miniature cliquable
- Preview d'emplacement

---

### 4. `FullScreenMapDialog`

Dialogue plein écran pour explorer la carte.

```dart
FullScreenMapDialog.show(
  context,
  center: LatLng(48.8566, 2.3522),
  markers: allMarkers,
  title: '15 destinations trouvées',
);
```

**Fonctionnalités** :
- Carte en grand format
- Tous les contrôles disponibles
- Header avec titre et bouton fermer
- Bottom sheet d'info au tap sur marqueur

---

### 5. `ResultsMapView`

Vue carte spécialisée pour l'écran de résultats.

```dart
ResultsMapView(
  results: searchResults,
  selectedResult: currentResult,
  onResultSelected: (result) {
    // Naviguer vers les détails
  },
  showFullScreenButton: true,
)
```

**Caractéristiques** :
- Affiche tous les résultats de recherche
- Calcul automatique du centre et du zoom optimal
- Légende des marqueurs
- Bouton plein écran
- Bottom sheet de détails au tap

**Calcul du zoom** :
- < 10 km → zoom 12
- < 50 km → zoom 10
- < 100 km → zoom 9
- < 200 km → zoom 8
- < 500 km → zoom 7
- \> 500 km → zoom 6

---

### 6. `ViewToggleButton`

Bouton flottant pour basculer entre vue liste et vue carte.

```dart
ViewToggleButton(
  isMapView: _isMapView,
  onToggle: () {
    setState(() => _isMapView = !_isMapView);
  },
)
```

---

## 💡 Exemples d'Utilisation

### Exemple 1: Écran de résultats avec toggle

```dart
class SearchResultsScreen extends StatefulWidget {
  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isMapView
        ? ResultsMapView(
            results: searchResults,
            onResultSelected: _navigateToDetails,
          )
        : ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              return ResultCard(result: searchResults[index]);
            },
          ),
      floatingActionButton: ViewToggleButton(
        isMapView: _isMapView,
        onToggle: () => setState(() => _isMapView = !_isMapView),
      ),
    );
  }
}
```

### Exemple 2: Card de destination avec mini-carte

```dart
class DestinationCard extends StatelessWidget {
  final DestinationResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Infos de la destination
          ListTile(
            title: Text(result.location.name),
            subtitle: Text('${result.matchScore}% de correspondance'),
          ),

          // Mini-carte cliquable
          CompactMap(
            latitude: result.location.latitude,
            longitude: result.location.longitude,
            label: result.location.name,
            height: 150,
            onTap: () {
              FullScreenMapDialog.show(
                context,
                center: LatLng(
                  result.location.latitude,
                  result.location.longitude,
                ),
                markers: [MapMarker.fromDestination(result)],
                title: result.location.name,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### Exemple 3: Carte avec hôtels et activités

```dart
void _showDestinationOnMap(DestinationResult destination) {
  // Créer marqueurs pour destination, hôtels et activités
  final markers = <MapMarker>[
    MapMarker.fromDestination(destination),
    ...destination.hotels.map((h) => MapMarker.fromHotel(h)),
    ...destination.activities.map((a) => MapMarker.fromActivity(a)),
  ];

  FullScreenMapDialog.show(
    context,
    center: LatLng(
      destination.location.latitude,
      destination.location.longitude,
    ),
    markers: markers,
    title: '${destination.location.name} - Points d\'intérêt',
  );
}
```

### Exemple 4: Navigation avec position actuelle

```dart
Future<void> _showNavigationMap() async {
  // Obtenir la position actuelle
  final position = await LocationService().getCurrentPosition();

  final markers = [
    MapMarker.currentLocation(
      position.latitude,
      position.longitude,
    ),
    MapMarker.fromDestination(destination),
  ];

  FullScreenMapDialog.show(
    context,
    center: LatLng(position.latitude, position.longitude),
    markers: markers,
    title: 'Navigation',
  );
}
```

---

## 🎨 Personnalisation

### Couleurs des marqueurs

Les couleurs sont définies dans `interactive_map.dart` :

```dart
// Dans _buildMarkerIcon()
switch (marker.type) {
  case MarkerType.destination:
    markerColor = AppColors.primaryOrange;
    markerIcon = Icons.location_on;
    break;
  case MarkerType.hotel:
    markerColor = AppColors.primaryBlue;
    markerIcon = Icons.hotel;
    break;
  // ... etc
}
```

Pour personnaliser, modifiez ces valeurs ou créez vos propres types.

### Tuiles de carte

Par défaut, OpenStreetMap est utilisé :

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.iwantsun.app',
)
```

**Alternatives disponibles** :
- **OpenTopoMap** : `https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png`
- **Stamen Terrain** : `https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg`
- **CartoDB** : `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png`

---

## ⚙️ Configuration

### Contrôles de carte

Personnaliser les boutons de contrôle :

```dart
InteractiveMap(
  showControls: true, // Afficher les contrôles
  // Les boutons incluent: zoom+, zoom-, center
)
```

### Limites de zoom

Configurées dans `MapOptions` :

```dart
MapOptions(
  minZoom: 3,   // Zoom minimum (vue monde)
  maxZoom: 18,  // Zoom maximum (rue)
)
```

### Interaction

```dart
InteractiveMap(
  enableInteraction: true, // Autoriser pan, zoom, etc.
)

// Pour une carte statique :
enableInteraction: false
```

---

## 🔧 Intégration dans l'Application

### 1. Écran de résultats

Le widget `ResultsMapView` peut être intégré directement :

```dart
// Dans search_results_screen.dart
body: Column(
  children: [
    // Autres widgets...
    ResultsMapView(
      results: filteredResults,
      onResultSelected: (result) {
        // Navigation ou affichage détails
      },
    ),
  ],
)
```

### 2. Page de détails destination

Ajouter une section carte dans les détails :

```dart
// Section carte dans destination_details_screen.dart
CompactMap(
  latitude: destination.location.latitude,
  longitude: destination.location.longitude,
  label: destination.location.name,
  onTap: () => _showFullMap(),
)
```

### 3. Page favoris

Afficher tous les favoris sur une carte :

```dart
// favorites_screen.dart
final favoriteMarkers = favorites.map((fav) =>
  MapMarker.fromDestination(fav)
).toList();

InteractiveMap(
  center: _calculateCenter(favorites),
  markers: favoriteMarkers,
)
```

---

## 📊 Performance

### Optimisations appliquées

1. **Lazy loading des tuiles** - Les tuiles sont chargées uniquement quand visibles
2. **Cache des tuiles** - flutter_map met automatiquement en cache les tuiles
3. **Limitation du nombre de marqueurs** - Envisager le clustering si > 100 marqueurs
4. **Déchargement des marqueurs hors vue** - flutter_map gère automatiquement

### Recommandations

- ✅ Utiliser `CompactMap` pour les aperçus (pas d'interaction = meilleure performance)
- ✅ Limiter le nombre de marqueurs affichés simultanément
- ✅ Utiliser `enableInteraction: false` pour les cartes statiques
- ⚠️ Éviter d'animer la position de la carte en boucle

---

## 🐛 Résolution de Problèmes

### Les tuiles ne se chargent pas

**Problème** : Carré gris au lieu des tuiles

**Solutions** :
1. Vérifier la connexion internet
2. Vérifier que le `userAgentPackageName` est défini
3. Vérifier les logs pour erreurs 429 (trop de requêtes)

### Les marqueurs ne s'affichent pas

**Problème** : Carte visible mais pas de marqueurs

**Solutions** :
1. Vérifier que `markers` n'est pas vide
2. Vérifier que les coordonnées sont valides (latitude: -90 à 90, longitude: -180 à 180)
3. Vérifier le niveau de zoom (trop dézoomé = marqueurs invisibles)

### Performance lente

**Problème** : Lag lors du pan/zoom

**Solutions** :
1. Réduire le nombre de marqueurs
2. Implémenter le clustering pour grouper les marqueurs proches
3. Utiliser `enableInteraction: false` si pas besoin d'interaction

---

## 🚀 Améliorations Futures

### Clustering de marqueurs

Pour les écrans avec beaucoup de résultats :

```dart
// TODO: Implémenter flutter_map_marker_cluster
MarkerClusterLayerOptions(
  maxClusterRadius: 120,
  size: Size(40, 40),
  markers: allMarkers,
)
```

### Itinéraires

Intégrer des routes entre points :

```dart
// TODO: Utiliser Nominatim pour le routing
PolylineLayer(
  polylines: [
    Polyline(
      points: routePoints,
      strokeWidth: 4,
      color: AppColors.primaryBlue,
    ),
  ],
)
```

### Heatmap

Afficher la densité de destinations :

```dart
// TODO: Implémenter flutter_map_heatmap
HeatMapLayer(
  heatMapDataSource: HeatMapDataSource(
    data: destinationDensity,
  ),
)
```

---

## 📚 Ressources

- [Documentation flutter_map](https://docs.fleaflet.dev/)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [Tile Servers](https://wiki.openstreetmap.org/wiki/Tile_servers)
- [latlong2 Package](https://pub.dev/packages/latlong2)

---

*Guide créé pour IWantSun - Phase 2: Intégration Cartes Interactives*
