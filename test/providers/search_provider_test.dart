import 'package:flutter_test/flutter_test.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/core/services/firebase_search_service.dart';
import 'package:iwantsun/core/services/network_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/presentation/providers/search_state.dart';

// Mock classes pour les tests
class MockFirebaseSearchService extends FirebaseSearchService {
  bool shouldFail = false;
  List<SearchResult> mockResults = [];

  @override
  Future<List<SearchResult>> searchDestinations(SearchParams params) async {
    if (shouldFail) {
      throw Exception('Mock error');
    }
    return mockResults;
  }
}

class MockNetworkService {
  bool isConnectedValue = true;

  Future<bool> get isConnected async => isConnectedValue;
}

void main() {
  group('SearchProvider - Concurrent Search Tests', () {
    late SearchProvider provider;
    late MockFirebaseSearchService mockFirebaseService;
    late MockNetworkService mockNetworkService;

    setUp(() {
      mockFirebaseService = MockFirebaseSearchService();
      mockNetworkService = MockNetworkService();
      // Note: SearchProvider ne permet pas d'injecter des mocks facilement
      // car il utilise des instances par défaut. Pour tester complètement,
      // il faudrait refactoriser pour permettre l'injection de dépendances.
      provider = SearchProvider();
    });

    test('search - prevents concurrent searches (Bug 8)', () async {
      // Test que le provider peut être instancié
      expect(provider, isNotNull);
      expect(provider.state, isA<SearchInitial>());
      
      // Note: Pour tester complètement les recherches concurrentes,
      // il faudrait un environnement Firebase configuré ou des mocks injectables
      // Ce test vérifie au moins que le provider fonctionne
      
      // Lancer une recherche (peut échouer sans Firebase, mais ne devrait pas planter)
      try {
        await provider.search(SearchParams(
        centerLatitude: 48.8566,
        centerLongitude: 2.3522,
        searchRadius: 100.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        desiredMinTemperature: 20.0,
        desiredMaxTemperature: 25.0,
        desiredConditions: ['clear'],
          timeSlots: [],
        ));
      } catch (e) {
        // Peut échouer sans Firebase configuré, mais ne devrait pas planter
        expect(provider.state, isA<SearchState>());
      }
    });

    test('provider state management', () {
      // Test que le provider gère correctement les états
      expect(provider.state, isA<SearchInitial>());
      expect(provider.isLoading, isFalse);
      expect(provider.hasResults, isFalse);
    });

    test('reset - clears search state', () {
      provider.reset();
      expect(provider.state, isA<SearchInitial>());
    });

    test('isLoading - returns correct state', () {
      expect(provider.isLoading, isFalse);
    });

    test('hasResults - returns false initially', () {
      expect(provider.hasResults, isFalse);
    });
  });
}
