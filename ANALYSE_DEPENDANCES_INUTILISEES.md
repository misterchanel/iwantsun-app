# Analyse des Dépendances Inutilisées

## 📋 Résumé

Après analyse complète du code, **8 dépendances** ne sont plus utilisées dans le projet et peuvent être supprimées.

## ❌ Dépendances à supprimer

### 1. **`http: ^1.1.0`** ❌
- **Raison** : Le projet utilise uniquement `dio` pour les requêtes HTTP
- **Fichiers utilisant dio** :
  - `lib/core/network/dio_client.dart`
  - `lib/core/network/dio_interceptors.dart`
  - `lib/core/services/amadeus_auth_service.dart`

### 2. **`sqflite: ^2.3.0`** ❌
- **Raison** : Le projet utilise uniquement `hive` pour le stockage local
- **Fichier utilisant hive** :
  - `lib/core/services/cache_service.dart`

### 3. **`google_maps_flutter: ^2.5.0`** ❌
- **Raison** : Le projet utilise uniquement `flutter_map` pour les cartes
- **Fichiers utilisant flutter_map** :
  - `lib/presentation/widgets/interactive_map.dart`

### 4. **`fl_chart: ^0.65.0`** ❌
- **Raison** : Aucune utilisation de graphiques/charts trouvée dans le code
- **Action** : Peut être supprimé sauf si prévu pour une fonctionnalité future

### 5. **`cached_network_image: ^3.3.0`** ❌
- **Raison** : Le projet utilise uniquement `AssetImage` pour les images locales
- **Fichiers utilisant AssetImage** :
  - `lib/presentation/screens/home_screen.dart`
  - `lib/presentation/screens/welcome_screen.dart`
  - `lib/presentation/screens/search_results_screen.dart`

### 6. **`cupertino_icons: ^1.0.6`** ❌
- **Raison** : Aucune utilisation de `CupertinoIcons` trouvée dans le code
- **Action** : Peut être supprimé si vous n'utilisez pas de widgets iOS natifs

### 7. **`dartz: ^0.10.1`** ❌
- **Raison** : Aucune utilisation de la programmation fonctionnelle avec `dartz` trouvée
- **Action** : Peut être supprimé si vous n'utilisez pas `Either`, `Option`, etc.

### 8. **`geocoding: ^4.0.0`** ❌
- **Raison** : Aucune utilisation trouvée dans le code
- **Note** : Le projet utilise `geolocator` pour la localisation, mais pas `geocoding` pour le géocodage inverse

## ✅ Dépendances utilisées (à conserver)

### HTTP & API
- ✅ `dio: ^5.4.0` - Utilisé pour toutes les requêtes HTTP

### Local Storage
- ✅ `shared_preferences: ^2.2.2` - Utilisé dans 7 fichiers
- ✅ `hive: ^2.2.3` - Utilisé pour le cache
- ✅ `hive_flutter: ^1.1.0` - Nécessaire pour Hive
- ✅ `path_provider: ^2.1.1` - Utilisé par Hive pour les chemins

### Maps & Location
- ✅ `flutter_map: ^6.1.0` - Utilisé pour les cartes
- ✅ `latlong2: ^0.9.0` - Utilisé avec flutter_map (4 fichiers)
- ✅ `geolocator: ^14.0.2` - Utilisé pour la localisation

### UI Components
- ✅ `shimmer: ^3.0.0` - Utilisé dans `loading_shimmer.dart`
- ✅ `intl: ^0.20.2` - Utilisé pour le formatage des dates (2 fichiers)
- ✅ `equatable: ^2.0.5` - Utilisé dans 4 fichiers (entities, providers)

### Utils
- ✅ `url_launcher: ^6.2.2` - Utilisé pour ouvrir des URLs
- ✅ `share_plus: ^7.2.2` - Utilisé pour partager (4 fichiers)

### Network
- ✅ `connectivity_plus: ^5.0.2` - Utilisé pour détecter la connectivité

### Firebase
- ✅ `firebase_core: ^3.8.1` - Utilisé
- ✅ `cloud_functions: ^5.2.1` - Utilisé
- ✅ `firebase_auth: ^5.3.4` - Utilisé dans `main.dart`
- ✅ `firebase_app_check: ^0.3.2+2` - Configuré (actuellement désactivé)

## 🔧 Actions recommandées

### Option 1 : Suppression immédiate
Supprimez les 8 dépendances inutilisées du `pubspec.yaml` :

```yaml
# À supprimer :
  http: ^1.1.0
  sqflite: ^2.3.0
  google_maps_flutter: ^2.5.0
  fl_chart: ^0.65.0
  cached_network_image: ^3.3.0
  cupertino_icons: ^1.0.6
  dartz: ^0.10.1
  geocoding: ^4.0.0
```

### Option 2 : Vérification avant suppression
Si certaines dépendances sont prévues pour des fonctionnalités futures, vous pouvez les garder mais les commenter avec une note :

```yaml
# Dépendances prévues pour futures fonctionnalités
  # fl_chart: ^0.65.0  # TODO: Graphiques météo
  # geocoding: ^4.0.0  # TODO: Géocodage inverse
```

## 📊 Impact de la suppression

- **Réduction de la taille de l'APK** : ~2-5 MB
- **Temps de build réduit** : Moins de dépendances à compiler
- **Maintenance simplifiée** : Moins de packages à mettre à jour
- **Sécurité améliorée** : Moins de surface d'attaque potentielle

## ⚠️ Notes importantes

1. **`hive_flutter`** : Nécessaire si vous utilisez Hive avec Flutter (initialisation)
2. **`path_provider`** : Nécessaire pour Hive (obtenir le répertoire de l'application)
3. **`latlong2`** : Nécessaire pour `flutter_map` (gestion des coordonnées)
4. **`firebase_app_check`** : Actuellement désactivé mais configuré pour la production

## 🧪 Test après suppression

Après avoir supprimé les dépendances, exécutez :

```bash
flutter pub get
flutter clean
flutter pub get
flutter analyze
```

Vérifiez que l'application compile et fonctionne correctement.
