# Guide de Contribution

Merci de votre intérêt pour contribuer à IWantSun ! Ce document fournit les directives pour contribuer au projet.

## 📋 Table des matières

- [Code de conduite](#code-de-conduite)
- [Comment contribuer](#comment-contribuer)
- [Standards de code](#standards-de-code)
- [Structure du projet](#structure-du-projet)
- [Tests](#tests)
- [Commit et Pull Requests](#commit-et-pull-requests)

## 🤝 Code de conduite

En participant à ce projet, vous acceptez de respecter notre code de conduite :

- Soyez respectueux et professionnel
- Acceptez les critiques constructives
- Concentrez-vous sur ce qui est meilleur pour la communauté
- Faites preuve d'empathie envers les autres membres

## 🚀 Comment contribuer

### Signaler un bug

1. Vérifiez que le bug n'a pas déjà été signalé dans les [Issues](https://github.com/votre-repo/issues)
2. Créez une nouvelle issue avec le label `bug`
3. Utilisez un titre clair et descriptif
4. Décrivez les étapes pour reproduire le problème
5. Incluez des captures d'écran si pertinent
6. Précisez votre environnement (OS, version Flutter, etc.)

**Template de bug report :**

```markdown
## Description
Brève description du bug

## Étapes pour reproduire
1. Aller à '...'
2. Cliquer sur '...'
3. Voir l'erreur

## Comportement attendu
Ce qui devrait se passer

## Comportement actuel
Ce qui se passe réellement

## Environnement
- OS: [e.g. Windows 11]
- Flutter version: [e.g. 3.16.0]
- App version: [e.g. 2.0.0]

## Logs
```
[Coller les logs pertinents ici]
```

## Captures d'écran
[Si applicable]
```

### Proposer une fonctionnalité

1. Créez une issue avec le label `enhancement`
2. Expliquez pourquoi cette fonctionnalité serait utile
3. Décrivez comment elle devrait fonctionner
4. Proposez une implémentation si possible

### Soumettre une Pull Request

1. Fork le repository
2. Créez une branche depuis `main` :
   ```bash
   git checkout -b feature/ma-nouvelle-fonctionnalite
   ```
3. Faites vos modifications en suivant les [standards de code](#standards-de-code)
4. Écrivez ou mettez à jour les tests
5. Assurez-vous que tous les tests passent
6. Committez vos changements (voir [Commit](#commit-et-pull-requests))
7. Poussez vers votre fork :
   ```bash
   git push origin feature/ma-nouvelle-fonctionnalite
   ```
8. Ouvrez une Pull Request vers `main`

## 💻 Standards de code

### Architecture

Le projet suit **Clean Architecture** avec 3 couches :

```
presentation ← domain ← data
```

**Règles importantes :**
- `domain` ne dépend d'aucune autre couche
- `data` implémente les interfaces définies dans `domain`
- `presentation` utilise `domain` via les use cases

### Style de code Dart

Suivez les [Effective Dart guidelines](https://dart.dev/guides/language/effective-dart) :

- Utilisez `lowerCamelCase` pour les variables et fonctions
- Utilisez `UpperCamelCase` pour les classes et types
- Utilisez `snake_case` pour les fichiers
- Préférez `const` quand c'est possible
- Utilisez `final` pour les variables non réassignées

**Exemple :**
```dart
// ✅ Bon
class UserRepository {
  final ApiService _apiService;

  const UserRepository(this._apiService);

  Future<User> getCurrentUser() async {
    // ...
  }
}

// ❌ Mauvais
class userRepository {
  var apiService;

  getUser() {
    // ...
  }
}
```

### Nommage

#### Classes
- **Entities** : Nom du concept (ex: `User`, `Hotel`)
- **Models** : Suffixe `Model` (ex: `UserModel`, `HotelModel`)
- **Repositories** : Suffixe `Repository` (ex: `UserRepository`)
- **Use Cases** : Format `VerbNounUseCase` (ex: `GetHotelsUseCase`)
- **Services** : Suffixe `Service` (ex: `CacheService`)
- **Datasources** : Suffixe `DataSource` (ex: `WeatherRemoteDataSource`)

#### Fichiers
```
lib/
├── domain/
│   ├── entities/
│   │   └── user.dart                    # Entité
│   ├── repositories/
│   │   └── user_repository.dart         # Interface
│   └── usecases/
│       └── get_current_user_usecase.dart
├── data/
│   ├── models/
│   │   └── user_model.dart              # DTO
│   ├── repositories/
│   │   └── user_repository_impl.dart    # Implémentation
│   └── datasources/
│       └── user_remote_datasource.dart
└── presentation/
    ├── screens/
    │   └── home_screen.dart
    └── widgets/
        └── user_card.dart
```

### Documentation

Documentez toutes les classes publiques et méthodes complexes :

```dart
/// Service de gestion du cache local
///
/// Utilise Hive pour stocker les données avec une durée d'expiration.
/// Les données expirées sont automatiquement supprimées lors de la lecture.
class CacheService {
  /// Récupère une valeur du cache
  ///
  /// Retourne `null` si la clé n'existe pas ou si les données sont expirées.
  ///
  /// [key] La clé de cache
  /// [boxName] Le nom du box Hive
  Future<T?> get<T>(String key, String boxName) async {
    // ...
  }
}
```

### Gestion des erreurs

Utilisez les classes d'erreur personnalisées :

```dart
// ✅ Bon
try {
  final hotels = await _hotelDataSource.getHotels();
} on NetworkException catch (e) {
  return Left(NetworkFailure(e.message));
} on ServerException catch (e) {
  return Left(ServerFailure(e.message));
}

// ❌ Mauvais
try {
  final hotels = await _hotelDataSource.getHotels();
} catch (e) {
  return Left(Failure('Error: $e'));
}
```

### Logging

Utilisez `AppLogger` pour tous les logs :

```dart
final _logger = AppLogger();

// Différents niveaux
_logger.debug('Message de debug détaillé');
_logger.info('Information générale');
_logger.warning('Avertissement');
_logger.error('Erreur critique', error, stackTrace);
```

### Async/Await

Préférez `async/await` aux callbacks :

```dart
// ✅ Bon
Future<List<Hotel>> getHotels() async {
  try {
    final response = await _dio.get('/hotels');
    return _parseHotels(response.data);
  } catch (e) {
    throw ServerException('Failed to fetch hotels');
  }
}

// ❌ Mauvais
Future<List<Hotel>> getHotels() {
  return _dio.get('/hotels').then((response) {
    return _parseHotels(response.data);
  }).catchError((e) {
    throw ServerException('Failed to fetch hotels');
  });
}
```

## 🏗️ Structure du projet

### Ajouter une nouvelle entité

1. **Créer l'entité** dans `domain/entities/`
```dart
// domain/entities/review.dart
class Review {
  final String id;
  final String content;
  final double rating;

  const Review({
    required this.id,
    required this.content,
    required this.rating,
  });
}
```

2. **Créer le modèle** dans `data/models/`
```dart
// data/models/review_model.dart
class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.content,
    required super.rating,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      content: json['content'],
      rating: json['rating'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'rating': rating,
    };
  }
}
```

3. **Créer le repository interface** dans `domain/repositories/`
```dart
// domain/repositories/review_repository.dart
abstract class ReviewRepository {
  Future<Either<Failure, List<Review>>> getReviews(String hotelId);
}
```

4. **Créer le datasource** dans `data/datasources/remote/`
```dart
// data/datasources/remote/review_remote_datasource.dart
abstract class ReviewRemoteDataSource {
  Future<List<ReviewModel>> getReviews(String hotelId);
}
```

5. **Implémenter le repository** dans `data/repositories/`
```dart
// data/repositories/review_repository_impl.dart
class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Review>>> getReviews(String hotelId) async {
    try {
      final reviews = await remoteDataSource.getReviews(hotelId);
      return Right(reviews);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

6. **Créer le use case** dans `domain/usecases/`
```dart
// domain/usecases/get_reviews_usecase.dart
class GetReviewsUseCase {
  final ReviewRepository repository;

  GetReviewsUseCase(this.repository);

  Future<Either<Failure, List<Review>>> call(String hotelId) {
    return repository.getReviews(hotelId);
  }
}
```

### Ajouter une nouvelle API

1. **Ajouter les constantes** dans `core/constants/api_constants.dart`
```dart
static const String newApiBaseUrl = 'https://api.example.com';
static const int newApiRateLimit = 10;
```

2. **Ajouter la configuration** dans `.env.example`
```env
NEW_API_KEY=your_api_key_here
```

3. **Ajouter dans EnvConfig** `core/config/env_config.dart`
```dart
static String get newApiKey => dotenv.get('NEW_API_KEY', fallback: '');
```

4. **Implémenter le datasource** avec cache et rate limiting
```dart
class NewRemoteDataSourceImpl implements NewRemoteDataSource {
  final Dio _dio;
  final CacheService _cacheService;
  final RateLimiterService _rateLimiter;
  final AppLogger _logger;

  // ... implémentation
}
```

## 🧪 Tests

### Tests unitaires

Placez les tests dans `test/` avec la même structure que `lib/` :

```dart
// test/domain/usecases/get_hotels_usecase_test.dart
void main() {
  late GetHotelsUseCase useCase;
  late MockHotelRepository mockRepository;

  setUp(() {
    mockRepository = MockHotelRepository();
    useCase = GetHotelsUseCase(mockRepository);
  });

  group('GetHotelsUseCase', () {
    test('should return hotels from repository', () async {
      // Arrange
      final tHotels = [Hotel(...)];
      when(mockRepository.getHotels(any))
          .thenAnswer((_) async => Right(tHotels));

      // Act
      final result = await useCase(locationId: 'PARIS');

      // Assert
      expect(result, Right(tHotels));
      verify(mockRepository.getHotels('PARIS'));
    });
  });
}
```

### Lancer les tests

```bash
# Tous les tests
flutter test

# Tests spécifiques
flutter test test/domain/usecases/

# Avec coverage
flutter test --coverage
```

## 📝 Commit et Pull Requests

### Messages de commit

Utilisez [Conventional Commits](https://www.conventionalcommits.org/) :

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types :**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage, point-virgule manquant, etc.
- `refactor`: Refactorisation de code
- `perf`: Amélioration de performance
- `test`: Ajout ou modification de tests
- `chore`: Tâches de maintenance

**Exemples :**
```
feat(hotels): add amadeus api integration

fix(cache): prevent memory leak in cache service

docs(readme): update installation instructions

refactor(weather): simplify weather data parsing

test(hotels): add unit tests for hotel repository
```

### Pull Request Template

```markdown
## Description
Brève description des changements

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Checklist
- [ ] Mon code suit les standards du projet
- [ ] J'ai commenté le code complexe
- [ ] J'ai mis à jour la documentation
- [ ] J'ai ajouté des tests
- [ ] Tous les tests passent
- [ ] J'ai mis à jour le CHANGELOG.md

## Tests
Description de comment tester les changements

## Screenshots (si applicable)
[Ajouter des screenshots]

## Issues liées
Closes #123
```

## 🔍 Review Process

### Pour les reviewers

1. Vérifiez que le code suit les standards
2. Vérifiez que les tests passent
3. Testez les changements localement si possible
4. Donnez des feedbacks constructifs
5. Approuvez ou demandez des changements

### Pour les contributeurs

1. Répondez aux commentaires de review
2. Faites les changements demandés
3. Poussez les changements
4. Demandez une nouvelle review si nécessaire

## 📚 Ressources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## 🙏 Remerciements

Merci à tous les contributeurs qui ont participé à ce projet !

---

Si vous avez des questions, n'hésitez pas à ouvrir une issue avec le label `question`.
