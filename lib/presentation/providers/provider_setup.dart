import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:iwantsun/data/datasources/remote/hotel_remote_datasource.dart';
import 'package:iwantsun/data/repositories/hotel_repository_impl.dart';
import 'package:iwantsun/domain/repositories/hotel_repository.dart';
import 'package:iwantsun/domain/usecases/get_hotels_usecase.dart';
import 'package:iwantsun/core/services/firebase_search_service.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/presentation/providers/result_filter_provider.dart';
import 'package:iwantsun/presentation/providers/favorites_provider.dart';
import 'package:iwantsun/presentation/providers/theme_provider.dart';
import 'package:iwantsun/core/l10n/app_localizations.dart';
import 'package:iwantsun/core/services/offline_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';
import 'package:iwantsun/core/services/user_profile_service.dart';

/// Configuration de tous les providers de l'application
/// NOTE: La recherche principale utilise Firebase Cloud Functions
/// Les appels API directs (Open-Meteo, Overpass) sont désormais gérés côté serveur
class ProviderSetup {
  /// Retourne la liste de tous les providers à injecter
  static List<SingleChildWidget> getProviders() {
    return [
      // Firebase Search Service (singleton)
      Provider<FirebaseSearchService>(
        create: (_) => FirebaseSearchService(),
      ),

      // Hotel Data Source (pour l'affichage des hôtels après recherche)
      Provider<HotelRemoteDataSource>(
        create: (_) => HotelRemoteDataSourceImpl(),
      ),

      // Hotel Repository
      ProxyProvider<HotelRemoteDataSource, HotelRepository>(
        update: (_, dataSource, __) => HotelRepositoryImpl(remoteDataSource: dataSource),
      ),

      // Use Cases (hôtels uniquement, la recherche est via Firebase)
      ProxyProvider<HotelRepository, GetHotelsUseCase>(
        update: (_, hotelRepo, __) => GetHotelsUseCase(hotelRepository: hotelRepo),
      ),

      // Search Provider (utilise Firebase Cloud Functions)
      ChangeNotifierProvider<SearchProvider>(
        create: (_) => SearchProvider(),
      ),

      // Result Filter Provider
      ChangeNotifierProvider<ResultFilterProvider>(
        create: (_) => ResultFilterProvider(),
      ),

      // Offline Service Provider
      ChangeNotifierProvider<OfflineService>(
        create: (_) => OfflineService(),
      ),

      // Favorites Provider (with init)
      ChangeNotifierProvider<FavoritesProvider>(
        create: (_) {
          final provider = FavoritesProvider();
          provider.init(); // Initialize asynchronously
          return provider;
        },
      ),

      // Theme Provider
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) {
          final provider = ThemeProvider();
          provider.init();
          return provider;
        },
      ),

      // Locale Provider
      ChangeNotifierProvider<LocaleProvider>(
        create: (_) {
          final provider = LocaleProvider();
          provider.init();
          return provider;
        },
      ),

      // Gamification Service
      ChangeNotifierProvider<GamificationService>(
        create: (_) {
          final service = GamificationService();
          service.init();
          return service;
        },
      ),

      // Analytics Service
      Provider<AnalyticsService>(
        create: (_) {
          final service = AnalyticsService();
          service.init();
          return service;
        },
      ),

      // User Profile Service
      ChangeNotifierProvider<UserProfileService>(
        create: (_) {
          final service = UserProfileService();
          service.init();
          return service;
        },
      ),
    ];
  }
}
