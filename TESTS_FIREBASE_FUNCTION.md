# Tests de la Fonction Firebase `searchDestinations`

## 📋 Vue d'ensemble

Suite de tests complète pour la fonction Firebase `searchDestinations` avec Lyon comme ville de référence.

### Coordonnées de référence
- **Lyon** : 45.7640°N, 4.8357°E
- **Rayon de test** : 5km à 50km
- **Période** : 7 jours à partir d'aujourd'hui

---

## 🧪 Cas de tests définis

### Test 1: Recherche basique - Lyon, rayon 20km, toutes conditions
**Objectif** : Vérifier que la fonction retourne des résultats valides avec une recherche standard.

**Paramètres** :
- Rayon : 20km
- Conditions : Toutes (clear, partly_cloudy, cloudy, rain)
- Créneaux : Tous (morning, afternoon, evening, night)

**Validations** :
- ✅ Retourne entre 10 et 50 résultats
- ✅ Lyon est présent dans les résultats
- ✅ Structure de données complète et valide
- ✅ Résultats triés par score décroissant

---

### Test 2: Recherche avec filtres température - 15-25°C
**Objectif** : Vérifier le filtrage par température.

**Paramètres** :
- Rayon : 30km
- Température : 15-25°C
- Conditions : clear, partly_cloudy
- Créneaux : morning, afternoon

**Validations** :
- ✅ Températures moyennes cohérentes
- ✅ Structure valide pour tous les résultats

---

### Test 3: Recherche condition spécifique - Ciel dégagé uniquement
**Objectif** : Vérifier le filtrage par condition météo.

**Paramètres** :
- Rayon : 40km
- Conditions : clear uniquement
- Créneaux : morning, afternoon

**Validations** :
- ✅ Si résultats, condition dominante doit être clear ou partly_cloudy

---

### Test 4: Recherche petit rayon - 5km
**Objectif** : Vérifier la recherche avec un rayon restreint.

**Paramètres** :
- Rayon : 5km
- Toutes conditions

**Validations** :
- ✅ Moins de résultats qu'avec 20km
- ✅ Toutes les villes à ≤ 5km
- ✅ Lyon inclus

---

### Test 5: Recherche grand rayon - 50km
**Objectif** : Vérifier la recherche avec un grand rayon.

**Paramètres** :
- Rayon : 50km
- Toutes conditions

**Validations** :
- ✅ Plus de 30 résultats
- ✅ Distance max ≤ 50km
- ✅ Villes périphériques incluses

---

### Test 6: Recherche créneaux horaires spécifiques - Matin uniquement
**Objectif** : Vérifier le calcul des scores par créneaux horaires.

**Paramètres** :
- Rayon : 25km
- Créneaux : morning uniquement (7h-11h)

**Validations** :
- ✅ Scores calculés correctement
- ✅ Données horaires disponibles

---

### Test 7: Recherche température restrictive - 25-30°C
**Objectif** : Tester avec des critères très restrictifs.

**Paramètres** :
- Température : 25-30°C
- Condition : clear uniquement

**Validations** :
- ✅ Peut retourner 0 résultat (normal selon la saison)
- ✅ Structure valide si résultats

---

### Test 8: Recherche sans filtres - Maximum de résultats
**Objectif** : Vérifier le retour maximum de résultats.

**Paramètres** :
- Rayon : 35km
- Toutes conditions incluses
- Tous créneaux

**Validations** :
- ✅ Minimum 40 résultats
- ✅ Tous les résultats valides

---

### Test 9: Validation valeurs globales
**Objectif** : Vérifier la cohérence des valeurs globales retournées.

**Validations** :
- ✅ Scores variés (écart > 5)
- ✅ Températures moyennes cohérentes (-10°C à 40°C)
- ✅ Distances dans le rayon
- ✅ Meilleur score en premier

---

### Test 10: Validation villes conservées
**Objectif** : Vérifier que les villes principales sont conservées.

**Validations** :
- ✅ Lyon présent dans les résultats
- ✅ Villes uniques (pas de doublons)
- ✅ Noms de villes valides et non vides

---

### Test 11: Edge case - Rayon max (200km)
**Objectif** : Vérifier la limitation du rayon.

**Paramètres** :
- Rayon : 300km (dépassant le max de 200km)

**Validations** :
- ✅ Rayon limité à 200km
- ✅ Distance max ≤ 202km

---

### Test 12: Edge case - Dates invalides
**Objectif** : Vérifier la robustesse avec dates fixes.

**Validations** :
- ✅ Gestion correcte des dates
- ✅ Pas de crash

---

## 🔍 Validations détaillées par résultat

Pour chaque résultat, les tests vérifient :

### Structure Location
- ✅ `id` : String définie
- ✅ `name` : String définie et non vide
- ✅ `latitude` : Number valide (45.0-46.0 pour Lyon)
- ✅ `longitude` : Number valide (4.5-5.2 pour Lyon)
- ✅ `distance` : Number ≥ 0
- ✅ `country` : Optionnel

### Structure WeatherForecast
- ✅ `locationId` : Correspond à `location.id`
- ✅ `forecasts` : Array avec ≥ 1 élément
- ✅ `averageTemperature` : Number valide
- ✅ `weatherScore` : Number entre 0-100

### Structure Forecast (chaque prévision)
- ✅ `date` : String format ISO
- ✅ `temperature` : Number
- ✅ `minTemperature` : Number ≤ temperature
- ✅ `maxTemperature` : Number ≥ temperature
- ✅ `condition` : String valide (clear, partly_cloudy, cloudy, rain, snow)
- ✅ `hourlyData` : Array

### Valeurs globales
- ✅ `overallScore` : Number entre 0-100
- ✅ `overallScore` = `weatherForecast.weatherScore`
- ✅ `averageTemperature` correspond à la moyenne des forecasts

---

## 🐛 Problèmes identifiés et correctifs

### ❌ Problème 1: Filtrage des conditions météo trop strict

**Symptôme** : La fonction `matchesDesiredConditions` ne vérifie que la condition dominante, ce qui peut exclure des destinations valides.

**Fichier** : `functions/src/index.ts` ligne 434-456

**Correctif proposé** :
```typescript
function matchesDesiredConditions(forecasts: WeatherData[], desiredConditions: string[]): boolean {
  if (desiredConditions.length === 0) return true;
  
  // Vérifier que chaque jour a au moins une condition correspondante
  const daysMatching = forecasts.filter(forecast => {
    const condition = forecast.condition.toLowerCase();
    return desiredConditions.some(desired => {
      const desiredLower = desired.toLowerCase();
      return condition === desiredLower ||
             (condition === "partly_cloudy" && desiredLower === "clear") ||
             ((condition === "clear" || condition === "sunny") && 
              (desiredLower === "clear" || desiredLower === "sunny"));
    });
  }).length;

  // Au moins 50% des jours doivent correspondre
  return daysMatching >= Math.ceil(forecasts.length * 0.5);
}
```

---

### ❌ Problème 2: Calcul de averageTemperature peut être inexact

**Symptôme** : `averageTemperature` est calculé dans `getWeatherBatch` comme la moyenne des températures quotidiennes, mais ne prend pas en compte les créneaux horaires filtrés.

**Fichier** : `functions/src/index.ts` ligne 192-194

**Correctif proposé** :
```typescript
// Dans getWeatherBatch, calculer avgTemp après filtrage par créneaux
const avgTemp = forecasts.length > 0
  ? forecasts.reduce((sum, f) => {
      // Utiliser la température filtrée si créneaux spécifiés
      const filtered = getFilteredWeatherData(f, new Set()); // Tous les créneaux
      return sum + filtered.avgTemp;
    }, 0) / forecasts.length
  : 0;
```

---

### ❌ Problème 3: Limitation à 60 villes peut exclure Lyon

**Symptôme** : Si plus de 60 villes sont trouvées, les villes au-delà sont ignorées, même si elles ont un meilleur score.

**Fichier** : `functions/src/index.ts` ligne 98

**Correctif proposé** :
```typescript
// Au lieu de prendre les 60 premières, trier par distance d'abord
const citiesToProcess = cities
  .slice(0, MAX_CITIES_TO_PROCESS * 2) // Prendre plus pour compenser
  .sort((a, b) => a.distance - b.distance)
  .slice(0, MAX_CITIES_TO_PROCESS);
```

---

### ❌ Problème 4: Scores peuvent être identiques pour plusieurs villes

**Symptôme** : Si plusieurs villes ont le même score météo, l'ordre n'est pas stable.

**Correctif proposé** :
```typescript
// Dans la fonction principale, trier par score puis par distance
results.sort((a, b) => {
  if (b.overallScore !== a.overallScore) {
    return b.overallScore - a.overallScore;
  }
  // En cas d'égalité, privilégier les plus proches
  return a.location.distance - b.location.distance;
});
```

---

### ❌ Problème 5: Pas de validation des paramètres d'entrée

**Symptôme** : Si `startDate > endDate`, la fonction peut échouer silencieusement.

**Correctif proposé** :
```typescript
// Au début de la fonction
if (new Date(data.startDate) > new Date(data.endDate)) {
  return { results: [], error: "startDate must be before endDate" };
}

if (data.searchRadius <= 0) {
  return { results: [], error: "searchRadius must be positive" };
}
```

---

### ❌ Problème 6: Gestion d'erreur Open-Meteo peut retourner résultats partiels

**Symptôme** : Si l'API Open-Meteo échoue pour certaines villes, elles sont ignorées sans log.

**Correctif proposé** :
```typescript
// Dans getWeatherBatch, loguer les échecs
for (let i = 0; i < cities.length && i < dataArray.length; i++) {
  const cityData = dataArray[i];
  const city = cities[i];

  if (!cityData || !cityData.daily) {
    console.warn(`Missing weather data for city ${city.name} (${city.id})`);
    continue;
  }
  // ...
}
```

---

### ❌ Problème 7: Filtrage par température pas utilisé

**Symptôme** : Les paramètres `desiredMinTemperature` et `desiredMaxTemperature` sont utilisés pour le calcul du score mais pas pour filtrer les résultats.

**Correctif proposé** :
```typescript
// Après le calcul du score météo
if (data.desiredMinTemperature !== undefined || data.desiredMaxTemperature !== undefined) {
  const avgTemp = weather.avgTemp;
  const minTemp = data.desiredMinTemperature ?? -Infinity;
  const maxTemp = data.desiredMaxTemperature ?? Infinity;
  
  // Accepter avec tolérance de 5°C
  if (avgTemp < minTemp - 5 || avgTemp > maxTemp + 5) {
    continue; // Exclure si trop en dehors de la plage
  }
}
```

---

## 📊 Métriques à surveiller

### Performance
- ⏱️ Temps de réponse < 30 secondes
- 🌍 Récupération villes < 15 secondes
- ☀️ Récupération météo < 5 secondes

### Qualité des données
- ✅ Taux de succès parsing > 95%
- ✅ Villes avec météo > 80% des villes trouvées
- ✅ Scores variés (écart min-max > 5)

### Robustesse
- ✅ Gestion erreurs Overpass (fallback)
- ✅ Validation paramètres d'entrée
- ✅ Limites respectées (rayon, nombre de résultats)

---

## 🚀 Exécution des tests

### Installation des dépendances
```bash
cd functions
npm install
```

### Exécution des tests
```bash
# Tous les tests
npm test

# Mode watch
npm run test:watch

# Avec couverture
npm run test:coverage
```

### Exécution avec Firebase Emulators
```bash
# Démarrer les emulators
npm run serve

# Dans un autre terminal, exécuter les tests
npm test
```

---

## 📝 Notes importantes

1. **Tests dépendants du réseau** : Les tests appellent réellement Overpass et Open-Meteo. Pour des tests unitaires purs, il faudrait mocker ces APIs.

2. **Dates variables** : Les dates utilisent `getStartDate()` et `getEndDate()` qui sont calculées dynamiquement.

3. **Tolérances** : Certaines validations utilisent des tolérances (ex: 0.5km pour les distances) pour compenser les imprécisions de calcul.

4. **Cache** : Le cache Firestore peut affecter les résultats. Penser à le nettoyer entre tests si nécessaire.

5. **Région** : La fonction est déployée sur `europe-west1`. Les tests locaux utilisent les emulators.

---

## ✅ Checklist avant déploiement

- [ ] Tous les tests passent
- [ ] Couverture de code > 80%
- [ ] Validation des paramètres d'entrée implémentée
- [ ] Gestion d'erreurs complète
- [ ] Logs suffisants pour le debugging
- [ ] Performance validée (< 30s pour 50km)
- [ ] Correctifs appliqués

---

*Document créé le 19 janvier 2026*
*Tests basés sur Lyon (45.7640°N, 4.8357°E)*
