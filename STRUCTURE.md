# Structure du Projet IWantSun

## 📁 Architecture des Dossiers

### ✅ Structure créée

```
lib/
├── main.dart                    # Point d'entrée de l'application
│
├── core/                        # Code partagé et réutilisable
│   ├── constants/              # Constantes de l'application
│   │   ├── api_constants.dart  # URLs et clés API
│   │   └── app_constants.dart  # Constantes générales
│   ├── theme/                  # Thème et design
│   │   ├── app_colors.dart     # Palette de couleurs
│   │   └── app_theme.dart      # Configuration du thème Material
│   ├── utils/                  # Utilitaires
│   │   ├── date_utils.dart     # Gestion des dates
│   │   └── score_calculator.dart # Calcul des scores de compatibilité
│   └── widgets/                # Widgets réutilisables du core
│
├── data/                        # Couche de données
│   ├── models/                 # Modèles de données (JSON)
│   ├── repositories/           # Implémentations des repositories
│   └── datasources/
│       ├── remote/             # APIs distantes
│       └── local/              # Cache, SQLite, Hive
│
├── domain/                      # Couche métier (Clean Architecture)
│   ├── entities/               # Entités pures du domaine
│   ├── repositories/           # Interfaces des repositories
│   └── usecases/               # Cas d'usage (logique métier)
│
└── presentation/                # Couche présentation
    ├── screens/                # Écrans de l'application
    ├── widgets/                # Widgets de l'UI
    └── providers/              # State management (Provider)
```

## 📦 Dépendances configurées

Toutes les dépendances nécessaires ont été ajoutées dans `pubspec.yaml` :

- **State Management** : Provider
- **Navigation** : Go Router
- **HTTP** : http, dio
- **Storage** : shared_preferences, hive, sqflite
- **Maps/Location** : google_maps_flutter, geolocator, geocoding
- **UI** : fl_chart, cached_network_image, shimmer, intl
- **Utils** : url_launcher, package_info_plus

## ✅ Fichiers créés

### Core
- ✅ `core/constants/api_constants.dart` - Configuration des APIs
- ✅ `core/constants/app_constants.dart` - Constantes de l'app
- ✅ `core/theme/app_colors.dart` - Palette de couleurs
- ✅ `core/theme/app_theme.dart` - Thème Material Design
- ✅ `core/utils/date_utils.dart` - Utilitaires de dates
- ✅ `core/utils/score_calculator.dart` - Calcul des scores

### Point d'entrée
- ✅ `main.dart` - Application de base

### Configuration
- ✅ `pubspec.yaml` - Dépendances configurées
- ✅ `analysis_options.yaml` - Règles de linting
- ✅ `.gitignore` - Fichiers à ignorer

## 🚀 Prochaines étapes

1. Exécuter `flutter pub get` pour installer les dépendances
2. Développer les entités du domaine
3. Créer les modèles de données
4. Implémenter les datasources (APIs)
5. Développer les écrans de l'interface
