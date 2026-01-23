import 'package:flutter_test/flutter_test.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  // Initialiser Flutter binding pour les tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService - Corruption Handling Tests', () {
    late CacheService cacheService;
    late Directory tempDir;

    setUpAll(() async {
      // Initialiser Hive avec un répertoire temporaire pour les tests
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await getTemporaryDirectory();
      Hive.init('${tempDir.path}/test_hive');
    });

    setUp(() async {
      cacheService = CacheService();
      try {
        await cacheService.init();
      } catch (e) {
        // Ignore si déjà initialisé
      }
    });

    tearDown(() async {
      // Nettoyer après chaque test
      try {
        await cacheService.clearAll();
      } catch (e) {
        // Ignore les erreurs de nettoyage
      }
    });

    test('get - handles null timestamp (Bug 13)', () async {
      // Simuler une entrée de cache avec timestamp null
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      await box.put('test_key', {
        'data': {'test': 'value'},
        'timestamp': null, // Timestamp manquant
      });

      final result = await cacheService.get<Map>('test_key', CacheService.weatherCacheBox);
      expect(result, isNull); // Devrait retourner null et supprimer l'entrée
      
      // Vérifier que l'entrée a été supprimée
      expect(box.get('test_key'), isNull);
    });

    test('get - handles wrong timestamp type (Bug 13)', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      await box.put('test_key', {
        'data': {'test': 'value'},
        'timestamp': 12345, // Wrong type (should be String)
      });

      final result = await cacheService.get<Map>('test_key', CacheService.weatherCacheBox);
      expect(result, isNull);
      expect(box.get('test_key'), isNull);
    });

    test('get - handles invalid timestamp format (Bug 13)', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      await box.put('test_key', {
        'data': {'test': 'value'},
        'timestamp': 'invalid-date-format',
      });

      final result = await cacheService.get<Map>('test_key', CacheService.weatherCacheBox);
      expect(result, isNull);
      expect(box.get('test_key'), isNull);
    });

    test('get - handles missing data field (Bug 11)', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      await box.put('test_key', {
        'timestamp': DateTime.now().toIso8601String(),
        // 'data' field missing
      });

      final result = await cacheService.get<Map>('test_key', CacheService.weatherCacheBox);
      expect(result, isNull);
      expect(box.get('test_key'), isNull);
    });

    test('get - handles corrupted cache entry structure', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      await box.put('test_key', 'not-a-map'); // Wrong structure

      // Ne devrait pas planter
      expect(() async {
        final result = await cacheService.get<Map>('test_key', CacheService.weatherCacheBox);
        expect(result, isNull);
      }, returnsNormally);
    });

    test('get - handles valid cache entry', () async {
      final testData = {'test': 'value', 'number': 42};
      await cacheService.put('valid_key', testData, CacheService.weatherCacheBox);

      final result = await cacheService.get<Map>('valid_key', CacheService.weatherCacheBox);
      expect(result, isNotNull);
      expect(result!['test'], 'value');
      expect(result['number'], 42);
    });

    test('get - handles expired cache entry', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      final oldDate = DateTime.now().subtract(const Duration(days: 2));
      await box.put('expired_key', {
        'data': {'test': 'value'},
        'timestamp': oldDate.toIso8601String(),
        'lastAccessed': oldDate.toIso8601String(),
      });

      final result = await cacheService.get<Map>('expired_key', CacheService.weatherCacheBox);
      expect(result, isNull); // Should be expired
      expect(box.get('expired_key'), isNull);
    });

    test('_cleanExpiredEntriesInBox - handles invalid timestamp format', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      await box.put('key1', {
        'data': {'test': 'value'},
        'timestamp': 'invalid-format',
        'lastAccessed': DateTime.now().toIso8601String(),
      });
      await box.put('key2', {
        'data': {'test': 'value2'},
        'timestamp': null,
        'lastAccessed': DateTime.now().toIso8601String(),
      });

      // Ne devrait pas planter lors du nettoyage
      expect(() async {
        await cacheService.cleanExpiredEntries();
      }, returnsNormally);
    });

    test('_evictLRU - handles invalid lastAccessed format', () async {
      final box = await Hive.openBox(CacheService.weatherCacheBox);
      // Remplir le cache jusqu'à la limite
      for (int i = 0; i < 101; i++) {
        await box.put('key_$i', {
          'data': {'test': 'value'},
          'timestamp': DateTime.now().toIso8601String(),
          'lastAccessed': i == 50 ? 'invalid-format' : DateTime.now().toIso8601String(),
        });
      }

      // Ajouter une nouvelle entrée qui devrait déclencher LRU
      expect(() async {
        await cacheService.put('new_key', {'test': 'new'}, CacheService.weatherCacheBox);
      }, returnsNormally);
    });
  });
}
