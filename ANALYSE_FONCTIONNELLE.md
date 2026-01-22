# Analyse Fonctionnelle Complète - IWantSun

**Date de l'analyse** : 2026-01-21  
**Version analysée** : 1.0.0+1  
**Analyste** : Auto (Claude)

---

## 📱 1. Architecture des Écrans

### 1.1 Structure de Navigation

L'application utilise **Go Router** pour la navigation avec 13 écrans principaux :

#### Écrans d'Accueil et Authentification
1. **WelcomeScreen** (`/`)
   - Premier écran affiché au lancement
   - Animation de fondu avec logo et titre
   - Délai de 2 secondes
   - Redirection automatique selon l'état d'onboarding

2. **OnboardingScreen** (`/onboarding`)
   - Présentation des fonctionnalités pour nouveaux utilisateurs
   - Transition : Slide up

3. **HomeScreen** (`/home`)
   - Écran d'accueil principal
   - Affiche 2 modes de recherche :
     - Recherche de Destination
     - Recherche d'Activité
   - Boutons favoris et paramètres
   - Affichage des recherches récentes (max 3)

#### Écrans de Recherche
4. **SearchDestinationScreen** (`/search/destination`)
   - Formulaire de recherche avec :
     - Centre de recherche (localisation)
     - Rayon de recherche (slider 1-200 km)
     - Période (date picker)
     - Créneaux horaires (matin, après-midi, soirée, nuit)
     - Température souhaitée (range slider -10°C à 45°C)
     - Conditions météo (clear, partly_cloudy, cloudy, rain)
   - Pré-remplissage intelligent des températures via Firebase
   - Validation complète avant soumission

5. **SearchActivityScreen** (`/search/activity`)
   - Même structure que SearchDestinationScreen
   - Ajout de sélection d'activités souhaitées

6. **SearchResultsScreen** (`/search/results`)
   - Affichage des résultats de recherche
   - Vue liste avec pagination (10 par page)
   - Vue carte interactive
   - Filtres et tri dynamiques
   - Actions : favoris, partage, booking

#### Écrans Secondaires
7. **FavoritesScreenEnhanced** (`/favorites`)
   - Liste des destinations favorites
   - Tri et filtrage

8. **HistoryScreen** (`/history`)
   - Historique des recherches
   - Réutilisation des critères

9. **SettingsScreen** (`/settings`)
   - Configuration de l'application

10. **ProfileScreen** (`/profile`)
    - Profil utilisateur

11. **BadgesScreen** (`/badges`)
    - Système de gamification

12. **OfflineModeScreen**
    - Mode hors ligne (si accessible)

---

## 🧮 2. Calculs et Algorithmes

### 2.1 Calcul de Distance (Formule de Haversine)

**Fichier** : `lib/data/datasources/remote/location_remote_datasource.dart`

```dart
distance = 2 * R * atan2(√a, √(1-a))
```

Où :
- R = 6371 km (rayon terrestre)
- a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)

**Usage** : Calcul de la distance entre le centre de recherche et chaque destination trouvée.

### 2.2 Calcul du Score Météo

**Fichier** : `lib/core/utils/score_calculator.dart`

#### Score de Compatibilité Météo (0-100)

**Formule** :
```
Score = (ScoreTempérature × 0.35) + (ScoreCondition × 0.50) + (Stabilité × 0.15)
```

#### A. Score de Température

**Méthode** : Courbe exponentielle décroissante

```
Écart = |Température_moyenne_réelle - Température_moyenne_souhaitée|
Score = 100 × e^(-Écart / 10.0)
```

**Exemples** :
- 0°C d'écart = 100%
- 5°C d'écart ≈ 60%
- 10°C d'écart ≈ 35%
- 15°C d'écart ≈ 15%
- 25°C d'écart ≈ 0%

#### B. Score de Condition Météo

**Matrice de compatibilité** :

| Souhaité | Obtenu | Score |
|----------|--------|-------|
| clear | clear | 100% |
| clear | partly_cloudy | 85% |
| clear | cloudy | 65% |
| clear | overcast | 35% |
| clear | rain | 10% |
| partly_cloudy | clear | 85% |
| partly_cloudy | cloudy | 65% |
| partly_cloudy | rain | 35% |
| cloudy | partly_cloudy | 65% |
| cloudy | rain | 35% |

#### C. Stabilité Météo (0-100)

**Calcul** :
1. **Stabilité température** (60% du poids)
   - Variance = moyenne((temp - moyenne)²)
   - Écart-type = √(variance)
   - Score = (1 - min(écart-type/10, 1)) × 100
   - Écart-type de 0°C = 100% stable
   - Écart-type de 10°C+ = 0% stable

2. **Stabilité conditions** (40% du poids)
   - Condition la plus fréquente
   - Score = (nb_jours_condition_dominante / total_jours) × 100

### 2.3 Calcul de Température Moyenne

**Fichier** : `lib/data/repositories/weather_repository_impl.dart`

```dart
Température_moyenne = Σ(températures_jour) / nombre_jours
```

**Usage** : Calcul de la température moyenne sur la période de voyage pour chaque destination.

### 2.4 Score d'Activités

**Formule** :
```dart
Score = (activités_trouvées / activités_souhaitées) × 100
```

**Exemple** :
- Activités souhaitées : 3
- Activités trouvées : 2
- Score = 2/3 × 100 = 66.7%

### 2.5 Score Global (Overall Score)

Le score global combine :
- Score météo (principal)
- Score activités (si recherche d'activité)
- Distance (pénalité si très loin)

---

## 🔄 3. Flux Utilisateur Principaux

### 3.1 Flux de Première Utilisation

```
WelcomeScreen (2s)
    ↓
OnboardingScreen
    ↓
HomeScreen
```

### 3.2 Flux de Recherche de Destination

```
HomeScreen
    ↓ (Clic "Recherche de Destination")
SearchDestinationScreen
    ↓ (Saisie critères)
    ├─ Validation formulaire
    ├─ Recherche localisation (si nécessaire)
    ├─ Pré-remplissage température (Firebase)
    ↓ (Clic "Rechercher")
SearchProvider.search()
    ├─ Vérification connexion
    ├─ Étape 1: Recherche villes (simulation)
    ├─ Étape 2: Vérification météo (simulation)
    ├─ Étape 3: Appel Firebase Cloud Function
    ↓
SearchResultsScreen
    ├─ Affichage résultats
    ├─ Actions: Favoris, Partager, Booking
    └─ Filtres et tri
```

### 3.3 Flux de Recherche d'Activité

```
HomeScreen
    ↓ (Clic "Recherche d'Activité")
SearchActivityScreen
    ↓ (Saisie critères + activités)
    ↓ (Clic "Rechercher")
SearchProvider.search() (avec activités)
    ↓
SearchResultsScreen (résultats filtrés par activités)
```

### 3.4 Flux de Gestion des Favoris

```
SearchResultsScreen
    ↓ (Clic cœur)
FavoritesService.addFavorite()
    ↓
[Favoris sauvegardé localement]
    ↓
FavoritesScreenEnhanced
    ├─ Affichage liste
    ├─ Tri/filtrage
    └─ Actions sur favoris
```

### 3.5 Flux d'Historique

```
HistoryScreen
    ↓ (Clic recherche historique)
SearchDestinationScreen (pré-rempli)
    ↓ (Modification possible)
    ↓ (Clic "Rechercher")
SearchResultsScreen
```

---

## 🔧 4. Services et Logique Métier

### 4.1 FirebaseSearchService

**Responsabilité** : Gestion des recherches via Firebase Cloud Functions

**Méthodes principales** :
- `searchDestinations(SearchParams)` : Recherche complète
- Parsing sécurisé des résultats
- Gestion d'erreurs typées

**Flow** :
1. Préparation paramètres
2. Appel Firebase Function
3. Parsing réponses
4. Retour liste SearchResult

### 4.2 LocationService

**Responsabilité** : Géolocalisation utilisateur

**Méthodes** :
- `getLocationWithFallback()` : GPS → IP si échec
- `getCurrentLocation()` : Position GPS pure

**Fallback** :
- GPS (précis)
- IP Geolocation (approximatif)

### 4.3 CacheService (Hive)

**Responsabilité** : Cache local avec stratégie LRU

**Boxes** :
- `weather_cache` : Prévisions météo (TTL: 24h)
- `location_cache` : Recherches de lieux
- `hotel_cache` : Données hôtels (TTL: 6h)
- `activity_cache` : Activités
- `favorites` : Favoris
- `search_history` : Historique

**Stratégie** :
- LRU (Least Recently Used)
- Taille max : 100 entrées par box
- Éviction automatique si limite atteinte

### 4.4 SearchHistoryService

**Responsabilité** : Historique des recherches

**Stockage** :
- Local (Hive)
- Recherches avec paramètres complets
- Date et résultats

**Fonctionnalités** :
- Ajout recherche
- Récupération historique
- Réutilisation critères

### 4.5 FavoritesService

**Responsabilité** : Gestion des favoris

**Stockage** : Hive (`favorites` box)

**Fonctionnalités** :
- Ajout/suppression favoris
- Vérification statut
- Liste complète

### 4.6 NetworkService

**Responsabilité** : Détection connectivité

**Méthodes** :
- `isConnected` : Statut connexion
- Écoute changements réseau

### 4.7 GamificationService

**Responsabilité** : Système de gamification

**Fonctionnalités** :
- Enregistrement recherches
- Badges et achievements
- Statistiques utilisateur

---

## 📊 5. États et Gestion d'État

### 5.1 SearchProvider States

**États possibles** :
1. **SearchInitial** : Aucune recherche
2. **SearchLoading** : Recherche en cours
   - Sous-états : searchingCities, checkingWeather, searchingHotels, finalizing
   - Progression affichée
3. **SearchSuccess** : Résultats disponibles
4. **SearchEmpty** : Aucun résultat
5. **SearchError** : Erreur avec Failure typé

### 5.2 Protection Recherches Concurrentes

**Mécanisme** : Flag `_isSearching`

- Empêche lancement de nouvelle recherche pendant une recherche en cours
- Log warning si tentative

---

## ✅ 6. Validations et Contrôles

### 6.1 Validation Formulaire Recherche

**Champs validés** :
1. **Dates** :
   - Présence obligatoire
   - `endDate > startDate`
   
2. **Localisation** :
   - Latitude/longitude requises
   - Géocodage si nécessaire
   
3. **Rayon** :
   - Minimum 1 km
   - Maximum 200 km
   
4. **Température** :
   - `minTemp < maxTemp`
   - Plage -10°C à 45°C
   
5. **Conditions météo** :
   - Au moins une condition sélectionnée
   
6. **Créneaux horaires** :
   - Au moins un créneau sélectionné

### 6.2 Validation Données Firebase

**Parsing sécurisé** :
- Vérification null
- Casts sécurisés avec fallback
- Validation formats (dates, nombres)
- Clamp valeurs (heures 0-23)

---

## 🗺️ 7. Géolocalisation et Cartes

### 7.1 Recherche de Lieux

**Méthodes** :
1. **Recherche textuelle** : Via Nominatim (Firebase Function)
2. **Géocodage inverse** : Coordonnées → Nom de lieu
3. **GPS utilisateur** : Position actuelle
4. **IP Geolocation** : Fallback si GPS indisponible

### 7.2 Carte Interactive

**Fonctionnalités** :
- Affichage toutes destinations
- Marqueurs avec rang (Top 10 en vert)
- Zoom automatique (fitBounds)
- Sélection marqueur → Détails destination
- Centrage automatique sur résultats

---

## 🔗 8. Intégrations Externes

### 8.1 Firebase Cloud Functions

**Fonctions utilisées** :
- `searchDestinations` : Recherche complète
- `searchLocations` : Recherche lieux
- `geocodeLocation` : Géocodage inverse
- `getWeatherForecast` : Prévisions météo
- `calculateAverageTemperature` : Calcul températures moyennes

### 8.2 APIs Externes (via Firebase)

**Nominatim** (OpenStreetMap) :
- Recherche géographique
- Géocodage

**Open-Meteo** :
- Prévisions météo
- Données horaires

**Overpass API** :
- Points d'intérêt
- Activités

### 8.3 Booking.com

**Intégration** :
- URL avec paramètres :
  - Ville
  - Dates (check-in/check-out)
  - Tri par distance
- Ouverture navigateur externe

---

## 💾 9. Persistance et Cache

### 9.1 Stratégie de Cache

**TTL par type** :
- Météo : 24h
- Lieux : 24h
- Hôtels : 6h
- Activités : Variable

**LRU** :
- Taille max : 100 entrées/box
- Éviction automatique

### 9.2 Stockage Local

**Hive** :
- Favoris
- Historique
- Préférences utilisateur

**SharedPreferences** :
- Settings
- État onboarding

---

## 🎨 10. Interface Utilisateur

### 10.1 Composants Réutilisables

**Widgets principaux** :
- `DestinationResultCard` : Carte résultat
- `InteractiveMap` : Carte avec marqueurs
- `LoadingButton` : Bouton avec état chargement
- `EnhancedLoadingIndicator` : Indicateur avec progression
- `EnhancedErrorMessage` : Gestion erreurs
- `EmptyState` : États vides
- `FavoriteButton` : Bouton favoris

### 10.2 Animations et Transitions

**Transitions d'écran** :
- Fade : Welcome, Home
- Slide : Recherche, Résultats
- Scale : Favoris, Badges

**Animations** :
- Loading progressif
- Skeleton loaders
- Hero transitions (logo)

---

## 📈 11. Performance et Optimisations

### 11.1 Pagination

**Résultats** :
- 10 items par page
- Chargement progressif
- Bouton "Charger plus"

### 11.2 Cache Agressif

**Stratégie** :
- Cache toutes requêtes API
- Réutilisation données identiques
- Réduction coûts API

### 11.3 Optimisations UI

**Techniques** :
- Lazy loading listes
- Images cachées
- Debounce recherche
- Skeleton screens

---

## 🔒 12. Sécurité et Gestion d'Erreurs

### 12.1 Gestion d'Erreurs Typée

**Exceptions** :
- `NetworkFailure` : Problème réseau
- `ServerFailure` : Erreur serveur
- `ApiKeyFailure` : Clé API invalide
- `RateLimitFailure` : Rate limiting
- `TimeoutFailure` : Timeout
- `FirebaseSearchException` : Erreurs Firebase

### 12.2 Validation Données

**Protections** :
- Parsing sécurisé
- Validation formats
- Clamp valeurs
- Fallback valeurs par défaut

### 12.3 Authentification

**Firebase Auth** :
- Authentification anonyme
- Sécurisation appels Cloud Functions

---

## 📝 13. Logging et Debugging

### 13.1 Système de Logging

**Niveaux** :
- Debug : Informations détaillées
- Info : Opérations importantes
- Warning : Avertissements
- Error : Erreurs avec stack trace

**Logs automatiques** :
- Appels API
- Erreurs parsing
- Opérations cache
- Actions utilisateur

---

## 🎯 14. Points d'Amélioration Fonctionnels Identifiés

### 14.1 Fonctionnalités Manquantes

1. **Recherche d'activité** : Interface existe mais logique incomplète
2. **Tri avancé** : Tri par score, distance, température
3. **Comparaison** : Comparer plusieurs destinations
4. **Export** : Export résultats (PDF, partage)

### 14.2 Optimisations Possibles

1. **Cache prévisionnel** : Pré-charger données communes
2. **Recherche incrémentale** : Résultats au fur et à mesure
3. **Suggestions** : Suggestions basées sur historique
4. **Notifications** : Alertes météo pour destinations favorites

---

## 📊 15. Métriques et Analytics

### 15.1 Événements Trackés

- Recherches effectuées
- Résultats affichés
- Favoris ajoutés
- Partages
- Clics booking
- Erreurs rencontrées

### 15.2 Statistiques Utilisateur

- Nombre recherches
- Destinations favorites
- Badges obtenus
- Activités recherchées

---

## ✅ Conclusion

L'application IWantSun présente une architecture fonctionnelle complète avec :

**Points forts** :
- ✅ Navigation fluide et intuitive
- ✅ Calculs précis (score, distance, météo)
- ✅ Gestion d'état robuste
- ✅ Cache efficace
- ✅ Gestion d'erreurs complète
- ✅ Interface utilisateur moderne

**Domaines d'amélioration** :
- 🔄 Recherche d'activité à compléter
- 🔄 Tests unitaires des calculs
- 🔄 Documentation API interne
- 🔄 Optimisations performance supplémentaires

---

*Cette analyse fonctionnelle a été générée par examen du code source. Pour toute question, se référer au code ou à la documentation technique.*
