# IWantSun ☀️

Application mobile Flutter professionnelle pour trouver des destinations avec la météo idéale.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Clean_Architecture-4CAF50?style=for-the-badge" />
</p>

## 📋 Description

**IWantSun** est une application mobile sophistiquée qui aide les utilisateurs à trouver leur destination de voyage idéale en fonction de critères météorologiques et d'activités. L'application utilise des APIs réelles pour fournir des informations précises et à jour.

### Fonctionnalités principales

- 🌡️ **Recherche météo avancée** : Trouvez des destinations en fonction de la température et conditions météo souhaitées
- 📍 **Géolocalisation intelligente** : Recherchez autour d'un point central avec rayon personnalisable
- 🏨 **Recommandations d'hôtels** : Intégration avec l'API Amadeus pour des suggestions d'hébergement réelles
- 🎯 **Activités extérieures** : Découvrez les points d'intérêt et activités disponibles
- 💾 **Cache intelligent** : Performances optimisées avec système de cache local
- 🔒 **Sécurité** : Gestion sécurisée des clés API avec variables d'environnement
- 📊 **Logging professionnel** : Suivi détaillé des opérations et erreurs

## 🚀 Installation

### Prérequis

- Flutter SDK 3.0.0 ou supérieur
- Dart SDK
- Un éditeur de code (VS Code, Android Studio, etc.)

### Configuration

1. **Cloner le repository**

```bash
git clone <votre-repo>
cd iwantsun
```

2. **Installer les dépendances**

```bash
flutter pub get
```

3. **Configurer les variables d'environnement**

Copiez le fichier `.env.example` vers `.env` et remplissez vos clés API :

```bash
cp .env.example .env
```

Éditez le fichier `.env` avec vos clés API :

```env
# Amadeus API (OBLIGATOIRE pour les hôtels)
AMADEUS_API_KEY=votre_cle_api_amadeus
AMADEUS_API_SECRET=votre_secret_amadeus

# Google Places API (OPTIONNEL pour enrichir les données)
GOOGLE_PLACES_API_KEY=votre_cle_google_places

# Configuration
ENABLE_LOGGING=true
CACHE_DURATION_HOURS=24
API_TIMEOUT_SECONDS=30
```

### Obtenir les clés API

#### Amadeus API (Gratuit pour développement)

1. Créez un compte sur [Amadeus for Developers](https://developers.amadeus.com/)
2. Créez une nouvelle application
3. Copiez votre API Key et API Secret
4. Gratuit jusqu'à 2000 requêtes/mois en mode test

#### Google Places API (Optionnel)

1. Créez un projet sur [Google Cloud Console](https://console.cloud.google.com/)
2. Activez l'API Places
3. Créez une clé API
4. Note: 300$ de crédits gratuits pour commencer

## 🏗️ Architecture

Le projet suit les principes de **Clean Architecture** pour une séparation claire des responsabilités :

```
lib/
├── core/                       # Fonctionnalités transversales
│   ├── config/                 # Configuration (env, constantes)
│   ├── constants/              # Constantes de l'application
│   ├── error/                  # Gestion des erreurs
│   │   ├── exceptions.dart     # Exceptions personnalisées
│   │   └── failures.dart       # Classes de Failure
│   ├── network/                # Configuration réseau
│   │   ├── dio_client.dart     # Client Dio configuré
│   │   └── dio_interceptors.dart # Intercepteurs (logging, erreurs)
│   ├── router/                 # Navigation
│   ├── services/               # Services transversaux
│   │   ├── cache_service.dart  # Service de cache Hive
│   │   ├── logger_service.dart # Service de logging
│   │   ├── network_service.dart # Service de connectivité
│   │   ├── rate_limiter_service.dart # Rate limiting
│   │   └── amadeus_auth_service.dart # Authentification Amadeus
│   ├── theme/                  # Thème et styles
│   └── utils/                  # Utilitaires
├── data/                       # Couche de données
│   ├── datasources/
│   │   ├── local/              # Sources de données locales
│   │   └── remote/             # Sources de données distantes (APIs)
│   │       ├── weather_remote_datasource.dart
│   │       ├── location_remote_datasource.dart
│   │       ├── hotel_remote_datasource.dart
│   │       └── activity_remote_datasource.dart
│   ├── models/                 # Modèles de données (DTO)
│   └── repositories/           # Implémentations des repositories
├── domain/                     # Logique métier
│   ├── entities/               # Entités métier
│   ├── repositories/           # Interfaces des repositories
│   └── usecases/               # Cas d'utilisation
└── presentation/               # Interface utilisateur
    ├── screens/                # Écrans
    ├── widgets/                # Widgets réutilisables
    └── providers/              # State management (Provider)
```

## 🔧 Technologies utilisées

### APIs Externes

- **Open-Meteo** : Prévisions météorologiques (gratuit, sans clé)
- **Amadeus API** : Recherche d'hôtels et informations de voyage
- **Nominatim (OpenStreetMap)** : Géocodage et recherche de lieux
- **Overpass API** : Points d'intérêt et activités

### Packages principaux

- `dio` : Client HTTP avancé
- `provider` : State management
- `go_router` : Navigation déclarative
- `hive` : Base de données locale rapide
- `logger` : Logging professionnel
- `flutter_dotenv` : Gestion des variables d'environnement
- `connectivity_plus` : Détection de la connectivité réseau
- `google_maps_flutter` : Intégration Google Maps
- `fl_chart` : Graphiques et visualisations

## 💻 Développement

### Lancer l'application

```bash
# Mode debug
flutter run

# Mode release
flutter run --release

# Sur un appareil spécifique
flutter run -d <device_id>
```

### Générer les fichiers Hive

Si vous modifiez les modèles Hive :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Tests

```bash
# Lancer tous les tests
flutter test

# Lancer les tests avec coverage
flutter test --coverage
```

## 🎯 Fonctionnalités avancées

### Gestion du cache

L'application utilise Hive pour un cache local performant :
- Cache automatique des prévisions météo (24h par défaut)
- Cache des résultats de recherche de lieux
- Cache des résultats d'hôtels et activités
- Durée de cache configurable via `.env`

### Rate Limiting

Protection contre les dépassements de quotas API :
- Limitation automatique des requêtes par API
- File d'attente intelligente
- Retry automatique avec backoff

### Gestion des erreurs

Système de gestion d'erreurs robuste :
- Exceptions typées pour chaque type d'erreur
- Messages d'erreur localisés et explicites
- Logging détaillé pour le debugging
- Fallback gracieux en cas d'échec

### Logging

Système de logging professionnel :
- Logs colorés et formatés
- Différents niveaux (debug, info, warning, error)
- Logs automatiques des requêtes API
- Désactivable via configuration

## 📱 Utilisation

### Mode Recherche Simple

1. Ouvrez l'application
2. Sélectionnez "Recherche Simple"
3. Définissez vos critères :
   - Température souhaitée
   - Conditions météo
   - Point central de recherche
   - Rayon de recherche
   - Dates de voyage
4. Consultez les résultats avec météo et hôtels

### Mode Recherche Avancée

1. Sélectionnez "Recherche avec Activités"
2. En plus des critères simples, ajoutez :
   - Types d'activités souhaitées (plage, ski, randonnée, etc.)
3. Obtenez des résultats filtrés par activités disponibles

## 🔐 Sécurité

- Clés API stockées dans fichier `.env` (non versionné)
- Utilisation de `flutter_secure_storage` pour données sensibles
- Validation des données d'entrée
- Protection contre les injections
- Timeout configurables pour éviter les blocages

## 🚀 Déploiement

### Android

```bash
flutter build apk --release
# ou pour un bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Windows

```bash
flutter build windows --release
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Ouvrez une issue sur GitHub
- Consultez la documentation des APIs utilisées

## 🙏 Remerciements

- [Amadeus for Developers](https://developers.amadeus.com/) pour l'API hôtels
- [Open-Meteo](https://open-meteo.com/) pour les données météo gratuites
- [OpenStreetMap](https://www.openstreetmap.org/) pour les données géographiques
- La communauté Flutter pour les packages excellents

---

Développé avec ❤️ et Flutter
