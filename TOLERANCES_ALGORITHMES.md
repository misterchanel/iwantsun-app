# Tolérances dans les Algorithmes IWantSun

Ce document liste toutes les tolérances, seuils et valeurs de précision utilisées dans les algorithmes de recherche et de calcul de scores.

---

## 📍 1. Filtrage des Températures

### Tolérance de Filtrage : **5°C**

**Localisation** : `functions/src/index.ts` (ligne 147)

**Utilisation** :
```typescript
const tolerance = 5; // Tolérance de 5°C
if (avgTemp < minTemp - tolerance || avgTemp > maxTemp + tolerance) {
  continue; // Exclure si trop en dehors de la plage
}
```

**Explication** :
- Une ville est exclue seulement si sa température moyenne est en dehors de la plage souhaitée **plus 5°C de tolérance**
- **Exemple** : Si l'utilisateur demande 20-25°C, les villes entre **15-30°C** sont acceptées
- Cette tolérance évite d'exclure des destinations valides à cause de petites différences de température

**Impact** :
- Rend la recherche plus flexible
- Permet de trouver des destinations proches des critères de l'utilisateur
- Compense les variations quotidiennes de température

---

## 🎯 2. Tri des Résultats par Score

### Tolérance d'Égalité de Score : **0.01**

**Localisation** : `functions/src/index.ts` (ligne 168)

**Utilisation** :
```typescript
if (Math.abs(b.overallScore - a.overallScore) > 0.01) {
  return b.overallScore - a.overallScore;
}
// En cas d'égalité de score (différence <= 0.01), trier par distance
return a.location.distance - b.location.distance;
```

**Explication** :
- Si la différence entre deux scores est **≤ 0.01**, ils sont considérés comme **égaux**
- En cas d'égalité, on trie par **distance croissante** (les plus proches en premier)
- Cette tolérance évite les comparaisons strictes qui pourraient être affectées par les erreurs d'arrondi

**Impact** :
- Assure un tri stable et prévisible
- Privilégie les destinations proches en cas de scores très proches
- Améliore l'expérience utilisateur (on préfère voir les destinations proches en premier)

---

## ☁️ 3. Filtrage des Conditions Météo

### Seuil de Correspondance : **50% des jours**

**Localisation** : `functions/src/index.ts` (ligne 488-489)

**Utilisation** :
```typescript
// Au moins 50% des jours doivent correspondre aux conditions désirées
const threshold = Math.ceil(forecasts.length * 0.5);
return daysMatching >= threshold;
```

**Explication** :
- Une destination est acceptée si **au moins 50% des jours** de la période correspondent aux conditions météo souhaitées
- Permet d'accepter des destinations avec quelques jours de mauvais temps
- Assure une flexibilité tout en maintenant la qualité des résultats

**Exemple** :
- Période de 6 jours
- Seuil = `Math.ceil(6 * 0.5) = 3` jours
- Si 3 jours ou plus correspondent aux conditions, la destination est acceptée

**Impact** :
- Plus flexible que l'exigence de 100% de jours correspondants
- Permet de trouver des destinations même avec quelques jours de météo moins favorable
- Améliore le nombre de résultats disponibles

---

## 📏 4. Calcul des Distances

### Tolérance de Précision (Tests) : **0.1 km**

**Localisation** : `functions/test-runner.js` (ligne 52)

**Utilisation** (tests) :
```javascript
const dist = calculateDistance(45.7640, 4.8357, 45.7640, 4.8357);
if (dist > 0.1) throw new Error(`Attendu ~0, obtenu: ${dist}`);
```

**Explication** :
- Utilisée uniquement pour les tests de validation
- Distance entre deux points identiques doit être < 0.1 km (pour gérer les erreurs d'arrondi)

### Tolérances de Validation des Distances (Tests)

**Lyon-Paris** : ±10 km (380-400 km acceptés)  
**Lyon-Marseille** : ±7.5 km (270-285 km acceptés)

**Explication** :
- Les tests acceptent une marge d'erreur pour compenser les variations dans le calcul de distance géodésique
- Permet de valider que la formule de Haversine fonctionne correctement

---

## 🌡️ 5. Calcul du Score de Température

### Coefficient de Décroissance Exponentielle : **10°C**

**Localisation** : `functions/src/index.ts` (ligne 398) et `lib/core/utils/score_calculator.dart` (ligne 48)

**Formule** :
```typescript
const tempScore = 100 * Math.exp(-tempDiff / 10);
```

**Tableau de correspondance** :

| Écart de température | Score obtenu |
|---------------------|--------------|
| 0°C (exact) | 100% |
| 5°C | ~61% |
| 10°C | ~37% |
| 15°C | ~22% |
| 20°C | ~14% |
| 25°C | ~8% |
| 30°C | ~5% |

**Explication** :
- Plus l'écart augmente, plus le score diminue rapidement
- **10°C d'écart = score divisé par ~3** (100% → 37%)
- Cette décroissance exponentielle privilégie fortement les températures proches des critères

**Impact** :
- Donne beaucoup d'importance aux températures proches des critères
- Réduit significativement le score des températures trop différentes
- Assure une différenciation claire entre les destinations

---

## 📊 6. Calcul de la Stabilité Météo

### Seuil de Stabilité des Températures : **10°C (écart-type)**

**Localisation** : `lib/core/utils/score_calculator.dart` (ligne 149)

**Formule** :
```dart
final stability = (1 - (stdDev / 10.0).clamp(0.0, 1.0)) * 100;
```

**Explication** :
- Un écart-type de **0°C** = 100% stable
- Un écart-type de **10°C ou plus** = 0% stable
- Écart-type entre 0-10°C = score proportionnel

**Exemple** :
- Écart-type de 5°C → `(1 - 5/10) * 100 = 50%` de stabilité

---

## 🎨 7. Score de Correspondance des Conditions

### Seuils de Score

**Localisation** : `functions/src/index.ts` (lignes 493-498) et `lib/core/utils/score_calculator.dart`

| Correspondance | Score | Exemple |
|----------------|-------|---------|
| **Exacte** | 100% | clear → clear |
| **Très similaire** | 85% | clear ↔ partly_cloudy |
| **Moyennement similaire** | 65% | clear ↔ cloudy |
| **Peu compatible** | 35% | clear ↔ rain, rain ↔ clear |
| **Par défaut** | 50% | Autres combinaisons |

**Règles spéciales** :
- `partly_cloudy` avec `clear` = 85% (très similaire)
- Si `rain` présent dans l'une des deux conditions = 35% (faible score)
- Autres combinaisons non spécifiées = 50% (score neutre)

---

## ⏱️ 8. Créneaux Horaires

### Heures Incluses par Créneau

**Localisation** : `functions/src/index.ts` (lignes 462-467)

| Créneau | Heures incluses | Nombre d'heures |
|---------|----------------|-----------------|
| **morning** | 7h, 8h, 9h, 10h, 11h | 5 heures |
| **afternoon** | 12h, 13h, 14h, 15h, 16h, 17h | 6 heures |
| **evening** | 18h, 19h, 20h, 21h | 4 heures |
| **night** | 22h, 23h, 0h, 1h, 2h, 3h, 4h, 5h, 6h | 9 heures |

**Note** : Les créneaux ne se chevauchent pas (pas de doublon d'heures entre créneaux).

---

## 🔢 9. Limites et Contraintes

### Rayon de Recherche Maximum : **200 km**

**Localisation** : `functions/src/index.ts` (ligne 17 et 82-84)

```typescript
const MAX_SEARCH_RADIUS_KM = 200;
if (data.searchRadius > MAX_SEARCH_RADIUS_KM) {
  data.searchRadius = MAX_SEARCH_RADIUS_KM;
}
```

**Explication** :
- Tout rayon > 200 km est automatiquement limité à 200 km
- Évite les recherches trop étendues qui seraient trop lentes ou coûteuses

---

### Nombre Maximum de Villes Traitées : **60 villes**

**Localisation** : `functions/src/index.ts` (ligne 15)

```typescript
const MAX_CITIES_TO_PROCESS = 60;
```

**Explication** :
- Limite le nombre de villes pour lesquelles on récupère la météo
- Permet de contrôler les temps de réponse et les coûts d'API

---

### Nombre Maximum de Résultats Retournés : **50 résultats**

**Localisation** : `functions/src/index.ts` (ligne 178)

```typescript
return { results: results.slice(0, 50), error: null };
```

**Explication** :
- Seuls les 50 meilleurs résultats sont retournés à l'utilisateur
- Améliore les performances et l'expérience utilisateur

---

### Durée de Cache : **24 heures**

**Localisation** : `functions/src/index.ts` (ligne 16)

```typescript
const CACHE_DURATION_HOURS = 24;
```

**Explication** :
- Les données de villes (Overpass) sont mises en cache pendant 24 heures
- Réduit les appels API pour des recherches similaires

---

## 📝 10. Pondération des Scores

### Pondération du Score Météo Global

**Localisation** : `functions/src/index.ts` (ligne 407) et `lib/core/utils/score_calculator.dart` (ligne 28)

**Formule** :
```typescript
totalScore = (tempScore × 0.35) + (conditionScore × 0.50) + (70 × 0.15);
```

| Composant | Poids | Description |
|-----------|-------|-------------|
| **Température** | 35% | Score basé sur l'écart de température |
| **Condition météo** | 50% | Score basé sur la correspondance des conditions |
| **Stabilité** | 15% | Score fixe de 70 (stabilité de base) |

**Note** : La condition météo a le poids le plus important (50%), suivie de la température (35%).

---

### Pondération de la Stabilité Météo

**Localisation** : `lib/core/utils/score_calculator.dart` (ligne 127)

**Formule** :
```dart
return (tempStability × 0.6) + (conditionStability × 0.4);
```

| Composant | Poids | Description |
|-----------|-------|-------------|
| **Stabilité température** | 60% | Basée sur l'écart-type des températures |
| **Stabilité conditions** | 40% | Basée sur le pourcentage de jours avec la condition dominante |

---

## 🔍 11. Résumé des Tolérances

| Tolérance | Valeur | Utilisation |
|-----------|--------|-------------|
| **Filtrage température** | ±5°C | Accepte villes jusqu'à 5°C en dehors de la plage |
| **Égalité de score** | 0.01 | Différence de score pour considérer deux résultats égaux |
| **Correspondance conditions** | 50% | Pourcentage minimum de jours correspondants |
| **Précision distance (test)** | 0.1 km | Tolérance pour distance zéro dans les tests |
| **Décroissance température** | 10°C | Coefficient pour calcul exponentiel du score |
| **Stabilité température** | 10°C | Écart-type maximum (0% stable) |
| **Rayon maximum** | 200 km | Limite automatique du rayon de recherche |
| **Villes max** | 60 | Nombre maximum de villes traitées |
| **Résultats max** | 50 | Nombre maximum de résultats retournés |
| **Cache** | 24h | Durée de mise en cache des données |

---

## 💡 Recommandations

### Modifier les Tolérances

Si vous souhaitez ajuster les tolérances :

1. **Filtrage température** : Modifier la constante `tolerance = 5` dans `functions/src/index.ts:147`
   - **Plus élevée** (ex: 10°C) = plus de résultats, mais moins précis
   - **Plus faible** (ex: 2°C) = moins de résultats, mais plus précis

2. **Seuil conditions** : Modifier `0.5` dans `functions/src/index.ts:489`
   - **Plus élevé** (ex: 0.7 = 70%) = résultats plus stricts
   - **Plus faible** (ex: 0.3 = 30%) = résultats plus flexibles

3. **Égalité de score** : Modifier `0.01` dans `functions/src/index.ts:168`
   - **Plus élevée** (ex: 0.1) = plus de destinations triées par distance
   - **Plus faible** (ex: 0.001) = tri principalement par score

4. **Décroissance température** : Modifier `10` dans `functions/src/index.ts:398`
   - **Plus élevé** (ex: 15) = décroissance plus lente
   - **Plus faible** (ex: 5) = décroissance plus rapide

**Important** : Après modification, pensez à :
- Tester avec différentes valeurs
- Redéployer sur Firebase (`firebase deploy --only functions`)
- Mettre à jour ce document

---

*Document généré le 19 janvier 2026*  
*Dernière mise à jour après analyse complète des algorithmes*
