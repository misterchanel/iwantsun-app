# Guide de Démarrage Rapide

Ce guide vous permettra de démarrer rapidement avec IWantSun.

## ⚡ Installation en 5 minutes

### 1. Cloner le projet
```bash
git clone <votre-repo>
cd iwantsun
```

### 2. Installer les dépendances
```bash
flutter pub get
```

### 3. Configurer les clés API

Créez un fichier `.env` à la racine :
```bash
cp .env.example .env
```

**Option A : Configuration Minimale (Sans hôtels)**
```env
ENABLE_LOGGING=true
CACHE_DURATION_HOURS=24
API_TIMEOUT_SECONDS=30
```
L'application fonctionnera avec météo et activités, mais sans hôtels.

**Option B : Configuration Complète (Avec hôtels)**

1. Créez un compte gratuit sur [Amadeus](https://developers.amadeus.com/)
2. Créez une application
3. Copiez vos clés dans `.env` :
```env
AMADEUS_API_KEY=votre_cle_ici
AMADEUS_API_SECRET=votre_secret_ici
AMADEUS_API_URL=https://test.api.amadeus.com

ENABLE_LOGGING=true
CACHE_DURATION_HOURS=24
API_TIMEOUT_SECONDS=30
```

### 4. Lancer l'application
```bash
flutter run
```

C'est tout ! 🎉

## 🔧 Obtenir les clés API Amadeus (2 minutes)

1. Allez sur https://developers.amadeus.com/
2. Cliquez sur "Register"
3. Créez votre compte
4. Créez une nouvelle application (bouton "Create New App")
5. Donnez un nom à votre app
6. Sélectionnez les APIs : "Hotel Search"
7. Copiez API Key et API Secret
8. Collez-les dans `.env`

**Limites gratuites :**
- 2000 requêtes/mois
- 10 requêtes/seconde
- Parfait pour le développement !

## 📱 Utiliser l'application

### Recherche de Destination

1. Lancez l'app
2. Cliquez sur "Recherche de Destination"
3. Définissez :
   - Température souhaitée (ex: 25°C)
   - Ville de départ (ex: Paris)
   - Rayon de recherche (ex: 500 km)
   - Dates (ex: du 1er au 7 juin)
4. Cliquez sur "Rechercher"
5. Consultez les destinations proposées avec :
   - Prévisions météo
   - Distance depuis votre point central
   - Hôtels disponibles (si API configurée)

### Recherche d'Activité

1. Cliquez sur "Recherche d'Activité"
2. Définissez vos critères de recherche (température, localisation, période, etc.)
3. L'app vous proposera des destinations ensoleillées correspondant à vos critères

## 🐛 Résolution rapide des problèmes

### L'app ne démarre pas

**Problème** : Erreur au démarrage
```bash
# Solution : Nettoyer et reconstruire
flutter clean
flutter pub get
flutter run
```

### Erreur "Failed to load .env"

**Problème** : Le fichier `.env` n'existe pas ou est mal placé

**Solution** :
```bash
# Vérifier que .env existe à la racine
ls -la .env

# Si absent, créer depuis l'exemple
cp .env.example .env
```

### Pas d'hôtels affichés

**Problème 1** : Clés API non configurées
```env
# Vérifiez .env
AMADEUS_API_KEY=votre_vraie_cle  # Pas "your_amadeus_api_key_here"
```

**Problème 2** : Compte Amadeus non activé
- Vérifiez vos emails pour un lien de confirmation
- Activez votre compte

**Problème 3** : Quota dépassé
- Vérifiez sur le dashboard Amadeus
- Attendez le mois suivant ou passez à un plan payant

### Erreur "Rate limit exceeded"

**Problème** : Trop de requêtes
- Attendez quelques secondes
- L'app respecte automatiquement les limites
- Vérifiez les logs pour voir quelle API est limitée

### Logs non affichés

**Problème** : ENABLE_LOGGING=false dans .env

**Solution** :
```env
ENABLE_LOGGING=true
```

## 🎯 Prochaines étapes

### Personnaliser l'app

1. **Modifier le thème**
   - Éditez `lib/core/theme/app_colors.dart`
   - Changez les couleurs primaires

2. **Ajouter une API**
   - Suivez le guide dans [CONTRIBUTING.md](CONTRIBUTING.md)
   - Exemple : Google Places pour activités enrichies

3. **Modifier les critères de recherche**
   - Éditez `lib/domain/entities/search_params.dart`
   - Ajoutez de nouveaux filtres

### Déployer l'app

#### Android
```bash
flutter build apk --release
# APK dans build/app/outputs/flutter-apk/
```

#### iOS
```bash
flutter build ios --release
# Nécessite un Mac et un compte développeur Apple
```

#### Windows
```bash
flutter build windows --release
# EXE dans build/windows/runner/Release/
```

## 📚 Documentation complète

- [README.md](README.md) - Vue d'ensemble et installation
- [API_GUIDE.md](API_GUIDE.md) - Guide détaillé des APIs
- [CONTRIBUTING.md](CONTRIBUTING.md) - Guide de contribution
- [CHANGELOG.md](CHANGELOG.md) - Historique des versions

## 🆘 Besoin d'aide ?

1. Consultez [API_GUIDE.md](API_GUIDE.md) pour les détails des APIs
2. Vérifiez les [Issues](https://github.com/votre-repo/issues) existantes
3. Créez une nouvelle issue si votre problème n'existe pas

## 🎓 Tutoriels vidéo (à venir)

- Installation et configuration
- Utilisation basique
- Personnalisation
- Déploiement

## 💡 Conseils de développement

### Activer Hot Reload
Le hot reload est activé par défaut en mode debug :
- `r` : hot reload
- `R` : hot restart
- `q` : quitter

### Déboguer les requêtes API
```env
# Dans .env
ENABLE_LOGGING=true
```
Puis vérifiez la console pour voir toutes les requêtes/réponses.

### Vider le cache
```dart
// Dans votre code
final cache = CacheService();
await cache.clearAll();
```

### Tester avec de fausses données
Créez des mocks dans `test/` :
```dart
class MockHotelDataSource extends Mock implements HotelRemoteDataSource {}
```

## 🚀 Améliorations suggérées

Fonctionnalités que vous pourriez ajouter :

1. **Mode hors ligne**
   - Sauvegarder les destinations favorites
   - Consulter l'historique sans connexion

2. **Filtres avancés**
   - Budget min/max pour les hôtels
   - Note minimale des hôtels
   - Types d'hébergement (hôtel, airbnb, etc.)

3. **Notifications**
   - Alertes pour changements météo
   - Offres d'hôtels

4. **Partage**
   - Partager une destination sur les réseaux sociaux
   - Exporter un itinéraire

5. **Carte interactive**
   - Visualiser toutes les destinations sur une carte
   - Clusters de destinations proches

## 📊 Métriques de performance

Attendez-vous à :
- **Temps de démarrage** : 2-3 secondes
- **Première recherche** : 5-10 secondes (appels API)
- **Recherches suivantes** : < 1 seconde (cache)
- **Utilisation mémoire** : ~150MB

## 🔐 Sécurité

**Important :**
- Ne commitez JAMAIS le fichier `.env`
- Ne partagez JAMAIS vos clés API publiquement
- Utilisez des clés API de test pour le développement
- Passez en production uniquement quand l'app est finalisée

## 🎉 Prêt à coder !

Vous êtes maintenant prêt à utiliser et développer IWantSun !

Pour aller plus loin, consultez :
- [Architecture détaillée](README.md#architecture)
- [Guide des APIs](API_GUIDE.md)
- [Guide de contribution](CONTRIBUTING.md)

**Bon développement !** ☀️

---

Dernière mise à jour : Janvier 2024
