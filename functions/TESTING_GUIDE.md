# Guide de Test des Firebase Functions

## ⚠️ Note Importante

Les tests des Firebase Functions nécessitent une configuration spéciale avec `firebase-functions-test` et les Firebase Emulators. Le fichier de test créé (`src/__tests__/searchDestinations.test.ts`) définit la structure des tests, mais nécessite une configuration supplémentaire pour être exécuté.

## 📋 Tests Définis

7 cas de tests ont été définis pour la fonction `searchDestinations` :

1. **Recherche basique** - Lyon, 20km, toutes conditions
2. **Filtres température** - 15-25°C
3. **Condition spécifique** - Ciel dégagé uniquement
4. **Validation valeurs globales** - Scores et données cohérentes
5. **Validation villes conservées** - Lyon présent et unicité
6. **Edge case rayon max** - Limitation à 200km
7. **Validation paramètres** - Erreurs sur paramètres invalides

## 🔧 Configuration Requise

### 1. Installer firebase-functions-test

```bash
cd functions
npm install --save-dev firebase-functions-test
```

### 2. Configuration Jest pour Firebase

Le fichier `jest.config.js` doit être mis à jour pour utiliser `firebase-functions-test`.

### 3. Tester avec Firebase Emulators

Les tests nécessitent Firebase Emulators pour fonctionner correctement :

```bash
# Installer les emulators
npm install -g firebase-tools

# Démarrer les emulators
firebase emulators:start --only functions
```

### 4. Alternative : Tests Manuels

En attendant la configuration complète, vous pouvez tester manuellement via :

1. **Console Firebase** : Utiliser la console Firebase Functions
2. **Postman/Insomnia** : Appeler directement l'endpoint
3. **Firebase CLI** : Utiliser `firebase functions:shell`

## 🧪 Test Manuel via Firebase CLI

```bash
# Démarrer le shell Firebase
cd functions
npm run shell

# Dans le shell, tester la fonction
searchDestinations({
  centerLatitude: 45.7640,
  centerLongitude: 4.8357,
  searchRadius: 20,
  startDate: '2026-01-24',
  endDate: '2026-01-31',
  desiredConditions: ['clear', 'partly_cloudy'],
  timeSlots: ['morning', 'afternoon']
})
```

## 📊 Validations à Effectuer Manuellement

### Structure des données
- ✅ `results` est un array
- ✅ Chaque résultat a `location`, `weatherForecast`, `overallScore`
- ✅ `location` a `id`, `name`, `latitude`, `longitude`, `distance`
- ✅ `weatherForecast` a `locationId`, `forecasts`, `averageTemperature`, `weatherScore`
- ✅ Chaque `forecast` a `date`, `temperature`, `minTemperature`, `maxTemperature`, `condition`, `hourlyData`

### Valeurs globales
- ✅ Scores entre 0-100
- ✅ `overallScore` = `weatherScore`
- ✅ Températures cohérentes (min <= temp <= max)
- ✅ `averageTemperature` correspond à la moyenne des forecasts

### Villes conservées
- ✅ Lyon présent dans les résultats (rayon 20-30km)
- ✅ Villes uniques (pas de doublons)
- ✅ Noms de villes valides

### Paramètres d'entrée
- ✅ Rayon négatif → erreur
- ✅ Dates inversées → erreur
- ✅ MinTemp > MaxTemp → erreur
- ✅ Rayon > 200km → limité à 200km

## ✅ Correctifs Appliqués

Les correctifs suivants ont été appliqués au code :

1. ✅ **Validation des paramètres d'entrée** - Rayon, dates, températures
2. ✅ **Filtrage des conditions amélioré** - Au moins 50% des jours doivent correspondre
3. ✅ **Filtrage par température avec tolérance** - 5°C de tolérance
4. ✅ **Tri amélioré** - Par score puis par distance
5. ✅ **Logs améliorés** - Avertissement pour villes sans météo

## 🚀 Prochaines Étapes

1. **Configurer firebase-functions-test** pour les tests automatisés
2. **Créer des mocks** pour Overpass et Open-Meteo (tests unitaires)
3. **Configurer CI/CD** pour exécuter les tests automatiquement
4. **Tester en production** avec des données réelles

## 📝 Notes

- Les tests actuels sont des **tests d'intégration** (appellent les APIs réelles)
- Pour des **tests unitaires**, il faudrait mocker Overpass et Open-Meteo
- Les tests prennent du temps (~30s-2min par test) à cause des appels API
- Utiliser des timeouts appropriés (120000ms = 2 minutes)

---

*Document créé le 19 janvier 2026*
*Les tests nécessitent une configuration Firebase complète pour être exécutés automatiquement*
