# Algorithme de Recherche IWantSun

Ce document décrit l'algorithme de recherche de destinations, le calcul du pourcentage de compatibilité, et la gestion du cache.

---

## 1. Vue d'ensemble du flux de recherche

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Paramètres     │────▶│  SearchProvider  │────▶│  Résultats      │
│  utilisateur    │     │  (orchestration) │     │  triés par %    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ SearchLocationsUseCase│
                    └──────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │ Location     │ │ Weather      │ │ Activity     │
      │ Repository   │ │ Repository   │ │ Repository   │
      └──────────────┘ └──────────────┘ └──────────────┘
              │                │                │
              ▼                ▼                ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │ Overpass API │ │ Open-Meteo   │ │ Overpass API │
      │ (villes)     │ │ (météo)      │ │ (activités)  │
      └──────────────┘ └──────────────┘ └──────────────┘
```

---

## 2. Paramètres de recherche (SearchParams)

| Paramètre | Type | Description |
|-----------|------|-------------|
| `centerLatitude` | double | Latitude du centre de recherche |
| `centerLongitude` | double | Longitude du centre de recherche |
| `searchRadius` | double | Rayon de recherche en km (0-200) |
| `startDate` | DateTime | Date de début du séjour |
| `endDate` | DateTime | Date de fin du séjour |
| `desiredMinTemperature` | double? | Température minimum souhaitée (°C) |
| `desiredMaxTemperature` | double? | Température maximum souhaitée (°C) |
| `desiredConditions` | List<String> | Conditions météo souhaitées (clear, partly_cloudy, cloudy, rain) |
| `timeSlots` | List<TimeSlot> | Créneaux horaires à considérer (matin, après-midi, soirée, nuit) |

### Créneaux horaires (TimeSlot)

| Créneau | Heures | Par défaut |
|---------|--------|------------|
| Matin | 7h-12h | ✅ Sélectionné |
| Après-midi | 12h-18h | ✅ Sélectionné |
| Soirée | 18h-22h | ✅ Sélectionné |
| Nuit | 22h-7h | ❌ Non sélectionné |

---

## 3. Étapes de l'algorithme de recherche

### Étape 1 : Récupération des villes proches

```dart
// Appel Overpass API avec bounding box
getNearbyCities(latitude, longitude, radiusKm)
```

**Processus :**
1. Calcul de la bounding box depuis le centre + rayon
2. Requête Overpass API pour les `node/way/relation` avec `place=city|town|village`
3. Calcul de la distance réelle (Haversine) pour chaque ville
4. Filtrage des villes hors du rayon
5. **Tri par distance croissante (les plus proches en premier)**
6. **Retour de TOUTES les villes triées (pas de limite précoce)**

**Optimisation :** Toutes les villes dans le rayon sont récupérées et triées. La sélection finale se fait après vérification météo.

### Étape 2 : Récupération des prévisions météo (traitement par batch avec arrêt anticipé)

**Stratégie optimisée :**

1. **Traitement par batch** : Les villes sont traitées par groupes de 10 en parallèle
2. **Utilisation du cache** : Chaque requête météo vérifie d'abord le cache (TTL 24h)
   - Si présent et valide → utilisation du cache (pas d'appel API)
   - Si expiré → suppression du cache, puis appel API
   - Si absent → appel API puis mise en cache
3. **Filtrage immédiat** : Dès réception des données météo, vérification de compatibilité
   - Si incompatible avec les paramètres utilisateur → ville oubliée
   - Si compatible → ajout aux résultats
4. **Arrêt anticipé** : Dès que 20 villes compatibles sont trouvées, arrêt du traitement

```dart
// Traitement par batch avec arrêt anticipé
for (batch in villes) {
  futures = batch.map((ville) => getWeatherForecast(...))  // Cache automatique
  results = await Future.wait(futures)
  
  // Filtrage immédiat des incompatibles
  valides = results.filter(compatible)
  
  if (valides.length >= 20) break  // Arrêt anticipé
}
```

**Données récupérées :**
- **Journalières** : temp_min, temp_max, weathercode
- **Horaires** : temperature_2m (24h), weathercode (24h)

### Étape 3 : Filtrage par créneaux horaires

Pour chaque jour de prévision :

```dart
_getFilteredWeatherData(weather, selectedHours)
```

1. Filtrer les données horaires selon les créneaux sélectionnés
2. Calculer la température moyenne sur les heures filtrées
3. Calculer min/max sur les heures filtrées
4. Déterminer la condition météo dominante (mode)

**Exemple :**
- Créneaux sélectionnés : Matin + Après-midi
- Heures considérées : 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
- Température moyenne = moyenne des températures sur ces 11 heures

### Étape 4 : Calcul du score météo

```dart
ScoreCalculator.calculateWeatherScore(...)
```

**Formule globale :**
```
Score = (TempScore × 0.35) + (ConditionScore × 0.50) + (StabilityScore × 0.15)
```

---

## 4. Détail du calcul des scores

### 4.1 Score de température (35%)

```dart
_calculateTemperatureScore(desiredMin, desiredMax, actualMin, actualMax)
```

**Formule :**
```
diff = |moyenneActuelle - moyenneSouhaitée|
score = 100 × e^(-diff/10)
```

| Écart (°C) | Score |
|------------|-------|
| 0 | 100% |
| 5 | ~61% |
| 10 | ~37% |
| 15 | ~22% |
| 25 | ~8% |

### 4.2 Score de condition météo (50%)

```dart
_calculateConditionScore(desired, actual)
```

| Correspondance | Score | Exemple |
|----------------|-------|---------|
| Exacte | 100% | clear → clear |
| Très similaire | 85% | clear → partly_cloudy |
| Moyennement similaire | 65% | clear → cloudy |
| Peu compatible | 35% | partly_cloudy → rain |
| Incompatible | 10% | clear → snow |

### 4.3 Score de stabilité météo (15%)

```dart
calculateWeatherStability(temperatures, conditions)
```

**Composants :**
- **Stabilité température (60%)** : basée sur l'écart-type
  ```
  stabilité = (1 - écart_type/10) × 100
  ```
- **Stabilité conditions (40%)** : pourcentage de la condition dominante
  ```
  stabilité = (nbJoursConditionDominante / nbJoursTotal) × 100
  ```

### 4.4 Score d'activités (optionnel)

Si recherche avancée avec activités :

```
activityScore = (activitésCorrespondantes / activitésDemandées) × 100
```

### 4.5 Score global

```
Si activités demandées :
  overallScore = (weatherScore × 0.70) + (activityScore × 0.30)
Sinon :
  overallScore = weatherScore
```

---

## 5. Filtrage des résultats

Après calcul des scores, filtrage optionnel par conditions météo :

```dart
_matchesDesiredConditions(forecast, desiredConditions)
```

1. Compter les occurrences de chaque condition sur la période
2. Identifier la condition dominante
3. Vérifier si elle correspond aux conditions souhaitées

---

## 6. Gestion du cache

### 6.1 Architecture du cache

```
┌─────────────────────────────────────────────────────┐
│                   CacheService                       │
│  (Singleton avec Hive + stratégie LRU)              │
├─────────────────────────────────────────────────────┤
│  Boxes :                                            │
│  ├── weather_cache      (prévisions météo)          │
│  ├── location_cache     (villes Overpass)           │
│  ├── hotel_cache        (hôtels)                    │
│  ├── activity_cache     (activités)                 │
│  ├── user_preferences   (préférences utilisateur)   │
│  └── favorites          (destinations favorites)    │
└─────────────────────────────────────────────────────┘
```

### 6.2 Structure d'une entrée cache

```json
{
  "data": <données>,
  "timestamp": "2024-01-15T10:30:00.000Z",
  "lastAccessed": "2024-01-15T14:22:00.000Z"
}
```

### 6.3 Politique de cache

| Paramètre | Valeur |
|-----------|--------|
| TTL par défaut | Configurable (EnvConfig.cacheDurationHours) |
| TTL locations | 24 heures |
| Taille max par box | 100 entrées |
| Stratégie d'éviction | LRU (Least Recently Used) |

### 6.4 Flux de lecture cache

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Demande     │────▶│ Cache hit ? │────▶│ TTL expiré ?│
│ données     │     └─────────────┘     └─────────────┘
└─────────────┘            │                   │
                     non   │             oui   │ non
                           ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │ Appel API   │     │ Retourner   │
                    │ externe     │     │ données     │
                    └─────────────┘     │ cache       │
                           │            └─────────────┘
                           ▼
                    ┌─────────────┐
                    │ Stocker en  │
                    │ cache       │
                    └─────────────┘
```

### 6.5 Clés de cache

**Météo :**
```
weather_{latitude}_{longitude}_{startDate}_{endDate}
```

**Locations (Overpass) :**
```
overpass_{lat.toFixed(2)}_{lon.toFixed(2)}_{radiusKm}
```

### 6.6 Éviction LRU

Quand une box atteint 100 entrées :
1. Parcourir toutes les entrées
2. Trouver celle avec `lastAccessed` le plus ancien
3. Supprimer cette entrée
4. Ajouter la nouvelle entrée

### 6.7 Statistiques de cache

Le service maintient des statistiques :
- `hits` : nombre de lectures réussies depuis le cache
- `misses` : nombre de lectures échouées (cache miss)
- `hitRate` : pourcentage de hits

---

## 7. Optimisations de performance

1. **Traitement par batch avec arrêt anticipé** :
   - Villes traitées par groupes de 10 en parallèle
   - Arrêt dès que 20 résultats compatibles sont trouvés
   - Réduit drastiquement les appels API inutiles

2. **Utilisation optimale du cache** :
   - Vérification cache avant chaque appel API (TTL 24h)
   - Suppression automatique des entrées expirées
   - Clé de cache basée sur `ville/date/horaire`
   - Réduction significative des appels API pour recherches similaires

3. **Tri précoce par distance** :
   - Toutes les villes triées par distance depuis le centre
   - Priorité aux villes proches (traitées en premier)

4. **Filtrage immédiat** :
   - Villes incompatibles météo oubliées immédiatement
   - Pas de calcul de score inutile pour villes incompatibles
   - Villes sans prévisions valides ignorées
   - Températures irréalistes (<-60°C ou >60°C) filtrées

5. **Garantie de résultats** :
   - Traitement de toutes les villes disponibles si nécessaire
   - Retour d'au moins 20 villes si disponibles et compatibles

6. **Streaming** (optionnel) :
   - Version `executeStream()` pour affichage progressif des résultats

---

## 8. Exemple de calcul complet

**Paramètres :**
- Température souhaitée : 22-28°C
- Condition souhaitée : clear
- Créneaux : Matin + Après-midi

**Ville A - Données filtrées :**
- Température moyenne : 25°C
- Condition dominante : clear
- Écart-type températures : 2°C
- Stabilité conditions : 80%

**Calcul :**
```
TempScore = 100 × e^(-(25-25)/10) = 100
ConditionScore = 100 (exact match)
TempStability = (1 - 2/10) × 100 = 80
CondStability = 80
WeatherStability = (80 × 0.6) + (80 × 0.4) = 80

Score final = (100 × 0.35) + (100 × 0.50) + (80 × 0.15)
            = 35 + 50 + 12
            = 97%
```

---

*Document généré automatiquement - IWantSun v1.0*
