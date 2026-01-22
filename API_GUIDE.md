# Guide d'utilisation des APIs

Ce guide détaille toutes les APIs utilisées dans IWantSun, comment les configurer et les bonnes pratiques d'utilisation.

## 📋 Table des matières

- [APIs Gratuites](#apis-gratuites)
- [APIs Nécessitant une Clé](#apis-nécessitant-une-clé)
- [Configuration](#configuration)
- [Rate Limiting](#rate-limiting)
- [Gestion du Cache](#gestion-du-cache)
- [Gestion des Erreurs](#gestion-des-erreurs)

## 🆓 APIs Gratuites

### Open-Meteo API

**Utilisation** : Prévisions météorologiques

**Avantages** :
- Entièrement gratuite
- Pas de clé API requise
- Pas de limite de requêtes stricte
- Données de haute qualité

**Documentation** : https://open-meteo.com/en/docs

**Exemple d'utilisation** :
```dart
final weatherDataSource = WeatherRemoteDataSourceImpl();
final forecasts = await weatherDataSource.getWeatherForecast(
  latitude: 48.8566,
  longitude: 2.3522,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
);
```

**Données retournées** :
- Température min/max
- Conditions météo (codes WMO)
- Prévisions jusqu'à 16 jours

### Nominatim (OpenStreetMap)

**Utilisation** : Géocodage et recherche de lieux

**Avantages** :
- Gratuit
- Pas de clé API
- Données du monde entier

**Limitations** :
- Maximum 1 requête par seconde
- User-Agent obligatoire dans les headers

**Documentation** : https://nominatim.org/release-docs/latest/api/Overview/

**Bonnes pratiques** :
- Toujours inclure un User-Agent
- Respecter le rate limit de 1 req/s
- Mettre en cache les résultats

**Exemple d'utilisation** :
```dart
final locationDataSource = LocationRemoteDataSourceImpl();
final locations = await locationDataSource.searchLocations('Paris');
```

### Overpass API

**Utilisation** : Points d'intérêt et activités extérieures

**Avantages** :
- Gratuit
- Données détaillées d'OpenStreetMap
- Requêtes personnalisables

**Limitations** :
- Maximum 1 requête toutes les 2 secondes
- Timeout de 25 secondes par requête

**Documentation** : https://wiki.openstreetmap.org/wiki/Overpass_API

**Exemple d'utilisation** :
```dart
final activityDataSource = ActivityRemoteDataSourceImpl();
final activities = await activityDataSource.getActivitiesNearLocation(
  latitude: 43.6047,
  longitude: 1.4442,
  radiusKm: 50,
  activityTypes: [ActivityType.hiking, ActivityType.cycling],
);
```

## 🔑 APIs Nécessitant une Clé

### Amadeus API

**Utilisation** : Recherche d'hôtels et informations de voyage

**Type de compte** : Test (gratuit) ou Production (payant)

**Limites compte Test** :
- 2000 requêtes par mois
- Données de test seulement
- 10 requêtes par seconde

**Limites compte Production** :
- Payant selon l'utilisation
- Données réelles en temps réel
- Limites plus élevées

**Inscription** :

1. Allez sur https://developers.amadeus.com/
2. Créez un compte gratuit
3. Créez une nouvelle application
4. Notez votre API Key et API Secret
5. Choisissez l'environnement (Test ou Production)

**URLs** :
- Test: `https://test.api.amadeus.com`
- Production: `https://api.amadeus.com`

**Authentification** :

L'API utilise OAuth2 avec client credentials flow :
```dart
// Géré automatiquement par AmadeusAuthService
final authService = AmadeusAuthService();
final token = await authService.getAccessToken();
```

**Endpoints utilisés** :

1. **Hotels by Geocode** : Rechercher des hôtels par coordonnées
```
GET /v1/reference-data/locations/hotels/by-geocode
?latitude={lat}&longitude={lon}&radius={radius}
```

**Exemple d'utilisation** :
```dart
final hotelDataSource = HotelRemoteDataSourceImpl();
final hotels = await hotelDataSource.getHotelsForLocation(
  locationId: 'PARIS',
  latitude: 48.8566,
  longitude: 2.3522,
  checkIn: DateTime(2024, 6, 1),
  checkOut: DateTime(2024, 6, 7),
);
```

**Bonnes pratiques** :
- Le token d'accès est mis en cache automatiquement
- Validité du token : 30 minutes
- Gestion automatique du renouvellement
- Rate limiting respecté automatiquement

**Documentation** : https://developers.amadeus.com/self-service/category/hotels

### Google Places API (Optionnel)

**Utilisation** : Enrichissement des données de lieux et activités

**Type de compte** : Google Cloud Platform

**Crédits gratuits** :
- 300$ de crédits pour commencer
- Certaines requêtes gratuites chaque mois

**Inscription** :

1. Créez un compte sur https://console.cloud.google.com/
2. Créez un nouveau projet
3. Activez l'API Places
4. Créez une clé API
5. Configurez les restrictions (HTTP referrer ou IP)

**Endpoints utilisés** :

1. **Nearby Search** : Rechercher des lieux à proximité
```
GET /maps/api/place/nearbysearch/json
?location={lat},{lng}&radius={radius}&type={type}&key={API_KEY}
```

2. **Place Details** : Détails d'un lieu
```
GET /maps/api/place/details/json
?place_id={place_id}&key={API_KEY}
```

**Coûts approximatifs** :
- Nearby Search: $32 per 1000 requêtes
- Place Details: $17 per 1000 requêtes
- Text Search: $32 per 1000 requêtes

**Bonnes pratiques** :
- Mettre en cache agressivement les résultats
- Utiliser les Basic Data fields (moins chers)
- Éviter les Contact et Atmosphere Data si non nécessaires

**Documentation** : https://developers.google.com/maps/documentation/places/web-service

## ⚙️ Configuration

### Fichier .env

Toutes les clés API doivent être configurées dans le fichier `.env` :

```env
# Amadeus API (OBLIGATOIRE pour les hôtels)
AMADEUS_API_KEY=votre_cle_api
AMADEUS_API_SECRET=votre_secret_api
AMADEUS_API_URL=https://test.api.amadeus.com

# Google Places API (OPTIONNEL)
GOOGLE_PLACES_API_KEY=votre_cle_google

# Configuration générale
ENABLE_LOGGING=true
CACHE_DURATION_HOURS=24
API_TIMEOUT_SECONDS=30
```

### Accès aux variables

Utilisez la classe `EnvConfig` pour accéder aux variables :

```dart
import 'package:iwantsun/core/config/env_config.dart';

// Vérifier si les clés sont configurées
if (EnvConfig.hasAmadeusConfig) {
  // Utiliser l'API Amadeus
  final apiKey = EnvConfig.amadeusApiKey;
}

// Accéder aux paramètres de configuration
final cacheDuration = EnvConfig.cacheDurationHours;
final timeout = EnvConfig.apiTimeoutSeconds;
```

## 🚦 Rate Limiting

Le service `RateLimiterService` gère automatiquement les limites de taux pour chaque API.

### Configuration par API

| API | Limite | Période |
|-----|--------|---------|
| Open-Meteo | 10 req | 10 secondes |
| Nominatim | 1 req | 1 seconde |
| Overpass | 1 req | 2 secondes |
| Amadeus (Test) | 10 req | 1 seconde |
| Google Places | Variable | Selon le plan |

### Utilisation

Le rate limiting est appliqué automatiquement dans les datasources :

```dart
// Vérifier le rate limit
await _rateLimiter.checkRateLimit(
  'api_name',
  maxRequests: 10,
  duration: Duration(seconds: 10),
);

// Si dépassé, une RateLimitException est levée
// avec l'heure à laquelle réessayer
```

### Gestion des dépassements

En cas de dépassement :
1. Une exception `RateLimitException` est levée
2. L'exception contient le temps d'attente recommandé
3. L'utilisateur est informé avec un message clair

## 💾 Gestion du Cache

### Durée de cache par type

| Type de données | Durée par défaut | Box Hive |
|----------------|------------------|----------|
| Météo | 24 heures | `weather_cache` |
| Lieux | 24 heures | `location_cache` |
| Hôtels | 24 heures | `hotel_cache` |
| Activités | 24 heures | `activity_cache` |

### Clés de cache

Les clés de cache sont générées automatiquement en fonction des paramètres :

```dart
// Exemple pour la météo
final cacheKey = 'weather_${latitude}_${longitude}_${startDate}_${endDate}';

// Exemple pour les hôtels
final cacheKey = 'hotel_${latitude}_${longitude}_${checkIn}_${checkOut}';
```

### Vider le cache

```dart
final cacheService = CacheService();

// Vider un box spécifique
await cacheService.clearBox(CacheService.weatherCacheBox);

// Vider tout le cache
await cacheService.clearAll();
```

## ❌ Gestion des Erreurs

### Types d'erreurs

L'application utilise des exceptions typées :

| Exception | Cause | Action recommandée |
|-----------|-------|-------------------|
| `NetworkException` | Pas de connexion | Vérifier la connexion |
| `ServerException` | Erreur serveur (5xx) | Réessayer plus tard |
| `ApiKeyException` | Clé API invalide | Vérifier la configuration |
| `RateLimitException` | Trop de requêtes | Attendre et réessayer |
| `TimeoutException` | Timeout dépassé | Réessayer |
| `ValidationException` | Données invalides | Corriger les données |

### Gestion dans le code

```dart
try {
  final hotels = await hotelDataSource.getHotelsForLocation(...);
} on ApiKeyException catch (e) {
  // Clé API manquante ou invalide
  showError('Veuillez configurer vos clés API');
} on RateLimitException catch (e) {
  // Trop de requêtes
  showError('Trop de requêtes, veuillez patienter');
} on NetworkException catch (e) {
  // Problème de connexion
  showError('Vérifiez votre connexion Internet');
} catch (e) {
  // Erreur inconnue
  showError('Une erreur est survenue');
}
```

## 🔍 Debugging

### Activer les logs détaillés

Dans votre fichier `.env` :
```env
ENABLE_LOGGING=true
```

### Types de logs

- 🐛 **DEBUG** : Informations détaillées pour le debugging
- ℹ️ **INFO** : Informations générales (requêtes API, cache hits)
- ⚠️ **WARNING** : Avertissements (cache failures, retries)
- ❌ **ERROR** : Erreurs avec stack trace

### Exemple de logs

```
[I] 2024-01-15 10:30:45 | API Request: GET https://api.open-meteo.com/v1/forecast
[I] 2024-01-15 10:30:46 | API Response: https://api.open-meteo.com/v1/forecast - Status: 200
[I] 2024-01-15 10:30:46 | Successfully fetched 7 weather forecasts
```

## 📊 Monitoring et Analytics

### Surveiller l'utilisation des APIs

Pour surveiller votre utilisation :

1. **Amadeus** : Dashboard sur developers.amadeus.com
2. **Google Places** : Console Google Cloud Platform
3. **Autres APIs** : Pas de dashboard officiel

### Métriques importantes

- Nombre de requêtes par jour
- Taux d'erreur
- Temps de réponse moyen
- Cache hit rate

## 🚀 Optimisations

### Réduire les coûts

1. **Maximiser le cache** : Augmenter la durée de cache
2. **Batching** : Grouper plusieurs requêtes si possible
3. **Lazy loading** : Charger uniquement les données nécessaires
4. **Compression** : Activer la compression gzip pour les réponses

### Améliorer les performances

1. **Parallélisation** : Effectuer plusieurs requêtes en parallèle
2. **Prefetching** : Précharger les données anticipées
3. **Optimistic updates** : Afficher les données du cache pendant le chargement
4. **Progressive loading** : Charger les données par étapes

## 📞 Support

### En cas de problème

1. Vérifiez les logs de l'application
2. Vérifiez votre connexion Internet
3. Vérifiez vos clés API sur les dashboards respectifs
4. Consultez la documentation officielle de l'API
5. Ouvrez une issue sur GitHub

### Ressources utiles

- [Documentation Amadeus](https://developers.amadeus.com/self-service)
- [Documentation Open-Meteo](https://open-meteo.com/en/docs)
- [Documentation Nominatim](https://nominatim.org/release-docs/latest/)
- [Documentation Overpass](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [Documentation Google Places](https://developers.google.com/maps/documentation/places)

---

Dernière mise à jour : Janvier 2024
