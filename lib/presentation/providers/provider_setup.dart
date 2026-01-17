import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:iwantsun/data/datasources/remote/activity_remote_datasource.dart';
import 'package:iwantsun/data/datasources/remote/hotel_remote_datasource.dart';
import 'package:iwantsun/data/datasources/remote/location_remote_datasource.dart';
import 'package:iwantsun/data/datasources/remote/weather_remote_datasource.dart';
import 'package:iwantsun/data/repositories/activity_repository_impl.dart';
import 'package:iwantsun/data/repositories/hotel_repository_impl.dart';
import 'package:iwantsun/data/repositories/location_repository_impl.dart';
import 'package:iwantsun/data/repositories/weather_repository_impl.dart';
import 'package:iwantsun/domain/repositories/activity_repository.dart';
import 'package:iwantsun/domain/repositories/hotel_repository.dart';
import 'package:iwantsun/domain/repositories/location_repository.dart';
import 'package:iwantsun/domain/repositories/weather_repository.dart';
import 'package:iwantsun/domain/usecases/get_hotels_usecase.dart';
import 'package:iwantsun/domain/usecases/search_locations_usecase.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/presentation/providers/result_filter_provider.dart';
import 'package:iwantsun/presentation/providers/favorites_provider.dart';
import 'package:iwantsun/presentation/providers/theme_provider.dart';
import 'package:iwantsun/core/l10n/app_localizations.dart';
import 'package:iwantsun/core/services/offline_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';

/// Configuration de tous les providers de l'application
class ProviderSetup {
  /// Retourne la liste de tous les providers à injecter
  static List<SingleChildWidget> getProviders() {
    return [
      // Data Sources
      Provider<WeatherRemoteDataSource>(
        create: (_) => WeatherRemoteDataSourceImpl(),
      ),
      Provider<LocationRemoteDataSource>(
        create: (_) => LocationRemoteDataSourceImpl(),
      ),
      Provider<ActivityRemoteDataSource>(
        create: (_) => ActivityRemoteDataSourceImpl(),
      ),
      Provider<HotelRemoteDataSource>(
        create: (_) => HotelRemoteDataSourceImpl(),
      ),

      // Repositories
      ProxyProvider<WeatherRemoteDataSource, WeatherRepository>(
        update: (_, dataSource, __) => WeatherRepositoryImpl(remoteDataSource: dataSource),
      ),
      ProxyProvider<LocationRemoteDataSource, LocationRepository>(
        update: (_, dataSource, __) => LocationRepositoryImpl(remoteDataSource: dataSource),
      ),
      ProxyProvider<ActivityRemoteDataSource, ActivityRepository>(
        update: (_, dataSource, __) => ActivityRepositoryImpl(remoteDataSource: dataSource),
      ),
      ProxyProvider<HotelRemoteDataSource, HotelRepository>(
        update: (_, dataSource, __) => HotelRepositoryImpl(remoteDataSource: dataSource),
      ),

      // Use Cases
      ProxyProvider3<LocationRepository, WeatherRepository, ActivityRepository,
          SearchLocationsUseCase>(
        update: (_, locationRepo, weatherRepo, activityRepo, __) =>
            SearchLocationsUseCase(
          locationRepository: locationRepo,
          weatherRepository: weatherRepo,
          activityRepository: activityRepo,
        ),
      ),
      ProxyProvider<HotelRepository, GetHotelsUseCase>(
        update: (_, hotelRepo, __) => GetHotelsUseCase(hotelRepository: hotelRepo),
      ),

      // Providers (State Management)
      ChangeNotifierProxyProvider<SearchLocationsUseCase, SearchProvider>(
        create: (_) {
          final locationRepo = LocationRepositoryImpl(
            remoteDataSource: LocationRemoteDataSourceImpl(),
          );
          final weatherRepo = WeatherRepositoryImpl(
            remoteDataSource: WeatherRemoteDataSourceImpl(),
          );
          final activityRepo = ActivityRepositoryImpl(
            remoteDataSource: ActivityRemoteDataSourceImpl(),
          );
          final useCase = SearchLocationsUseCase(
            locationRepository: locationRepo,
            weatherRepository: weatherRepo,
            activityRepository: activityRepo,
          );
          return SearchProvider(searchLocationsUseCase: useCase);
        },
        update: (_, useCase, previous) =>
            previous ?? SearchProvider(searchLocationsUseCase: useCase),
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
    ];
  }
}
