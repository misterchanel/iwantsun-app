# 📊 Analyse des Logs Firebase - 18 Janvier 2026

## 🔴 Problèmes Identifiés

### 1. Erreurs API Overpass (504 Gateway Timeout)

**Erreur principale** : L'API Overpass (`https://overpass-api.de/api/interpreter`) retourne des erreurs **504 Gateway Timeout**.

**Détails** :
- **Timestamp** : 18 Janvier 2026, 20:38:27 UTC et 20:39:09 UTC
- **Code d'erreur** : `ERR_BAD_RESPONSE` avec status 504
- **Message du serveur** : "The server is probably too busy to handle your request."

**Impact** :
- ❌ Impossible de récupérer les villes depuis OpenStreetMap
- ❌ La recherche de destinations échoue complètement
- ❌ L'expansion automatique du rayon de recherche échoue également

**Requête qui échoue** :
```
[out:json][timeout:30];
(
  node["place"="city"](42.917..., 1.271..., 48.322..., 9.000...);
  node["place"="town"](...);
  node["place"="village"](...);
  way["place"="city"](...);
  way["place"="town"](...);
  way["place"="village"](...);
);
out center;
```

### 2. Expansion du Rayon de Recherche

**Tentatives d'expansion** :
- La fonction tente d'élargir le rayon de recherche à **300km** lorsque moins de 20 villes sont trouvées
- Toutes les tentatives échouent à cause des erreurs Overpass

**Logs observés** :
```
2026-01-18T20:38:27.680985Z - Expanding search radius to 300km (found 0 cities)
2026-01-18T20:39:02.082270Z - Expanding search radius to 300km (found 0 cities)
```

## 🔍 Analyse Détaillée

### Cause Racine

L'API Overpass est **surchargée** ou **temporairement indisponible**. Le serveur `overpass-api.de` ne peut pas traiter les requêtes dans le délai imparti (35 secondes de timeout).

### Zones Géographiques Affectées

Les requêtes échouent pour des zones de recherche très étendues :
- **Latitude** : 42.917° à 48.322° (environ 600km)
- **Longitude** : 1.271° à 9.000° (environ 600km)
- **Surface totale** : ~360,000 km²

Cette zone couvre une grande partie de l'Europe (France, Allemagne, Suisse, etc.), ce qui explique la lourdeur de la requête.

## 💡 Solutions Recommandées

### Solution 1 : Réduire la Zone de Recherche Initiale

Modifier la fonction pour :
1. Commencer avec des zones plus petites
2. Augmenter progressivement le rayon (pas de façon exponentielle)
3. Limiter la surface maximale de recherche

**Code à modifier** : `functions/src/index.ts` - fonction `getCitiesWithExpansion`

### Solution 2 : Utiliser un Serveur Overpass Alternatif

Tester d'autres instances d'Overpass API :
- `https://overpass.kumi.systems/api/interpreter`
- `https://overpass-api.openstreetmap.fr/api/interpreter`
- Instance auto-hébergée si possible

### Solution 3 : Améliorer la Gestion d'Erreurs et le Cache

1. **Meilleure utilisation du cache** : Vérifier le cache **avant** d'appeler Overpass
2. **Retry avec backoff exponentiel** : Réessayer les requêtes qui échouent
3. **Fallback** : Retourner des résultats partiels depuis le cache si Overpass échoue

### Solution 4 : Optimiser les Requêtes Overpass

1. **Réduire le timeout Overpass** : `[timeout:15]` au lieu de `[timeout:30]`
2. **Diviser les requêtes** : Diviser les grandes zones en plusieurs petites requêtes
3. **Limiter les types de lieux** : Commencer par `city` seulement, puis ajouter `town` et `village`

### Solution 5 : Monitoring et Alertes

Ajouter des alertes Firebase pour :
- Taux d'erreur Overpass > 50%
- Temps de réponse moyen > 30 secondes
- Nombre de requêtes échouées consécutives

## 📈 Statistiques des Erreurs

- **Nombre d'erreurs observées** : Au moins 2 erreurs 504 (probablement plus)
- **Période** : Entre 20:38 et 20:39 UTC
- **Taux d'échec** : 100% des requêtes Overpass échouent
- **Impact utilisateur** : **Blocage total** de la recherche de destinations

## 🛠️ Actions Immédiates

1. ✅ **Vérifier l'état d'Overpass API** : 
   - https://overpass-api.de/status/
   - https://overpass-api.de/api/status

2. ✅ **Tester avec une zone plus petite** :
   - Commencer avec un rayon de 50km au lieu de 100km+
   - Vérifier que le cache fonctionne correctement

3. ✅ **Améliorer les logs** :
   - Ajouter plus de logs détaillés pour le debugging
   - Logger la taille des zones de recherche

4. ✅ **Implémenter un fallback** :
   - Si Overpass échoue, utiliser des données en cache
   - Ou utiliser une alternative (Google Places API, etc.)

## 📝 Notes Techniques

### Configuration Actuelle

- **Timeout Axios** : 35000ms (35 secondes)
- **Timeout Overpass** : 30 secondes
- **Rayon initial** : Variable selon les paramètres utilisateur
- **Rayon maximum** : `searchRadius * 3` ou 500km (le plus petit)

### Recommandations de Timeout

Pour une meilleure résilience :
- **Timeout Overpass dans la requête** : 15 secondes
- **Timeout Axios** : 20000ms (20 secondes)
- **Retry** : 3 tentatives avec backoff (1s, 2s, 4s)

---

**Date d'analyse** : 18 Janvier 2026  
**Derniers logs analysés** : 18 Janvier 2026, 20:39:09 UTC