import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iwantsun/firebase_options.dart';
import 'package:iwantsun/core/router/app_router.dart';
import 'package:iwantsun/core/config/env_config.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/favorites_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/offline_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/event_notification_service.dart';
import 'package:iwantsun/core/l10n/app_localizations.dart';
import 'package:iwantsun/presentation/providers/provider_setup.dart';
import 'package:iwantsun/core/theme/app_theme.dart';
import 'package:iwantsun/presentation/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check désactivé temporairement pour le développement
  // TODO: Réactiver avant la mise en production
  // try {
  //   await FirebaseAppCheck.instance.activate(
  //     androidProvider: AndroidProvider.playIntegrity,
  //   );
  //   debugPrint('Firebase: App Check activated');
  // } catch (e) {
  //   debugPrint('Firebase App Check error: $e');
  // }

  // Authentification anonyme pour sécuriser les appels Cloud Functions
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      debugPrint('Firebase: Signed in anonymously');
    }
  } catch (e) {
    debugPrint('Firebase Auth error: $e');
  }

  // Configurer l'affichage système (barre de navigation Android)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // S'assurer que l'app respecte les zones sécurisées
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Initialiser l'environnement
  try {
    await EnvConfig.load();
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
    debugPrint('The app will continue with default configuration.');
  }

  // Initialiser le logger
  final logger = AppLogger();

  // Initialiser le cache
  try {
    await CacheService().init();
    logger.info('Cache service initialized successfully');
  } catch (e) {
    logger.error('Failed to initialize cache service', e);
  }

  // Initialiser le service des favoris
  try {
    await FavoritesService().init();
    logger.info('Favorites service initialized successfully');
  } catch (e) {
    logger.error('Failed to initialize favorites service', e);
  }

  // Initialiser le service d'historique
  try {
    await SearchHistoryService().init();
    logger.info('Search history service initialized successfully');
  } catch (e) {
    logger.error('Failed to initialize search history service', e);
  }

  // Initialiser le service offline
  try {
    await OfflineService().init();
    logger.info('Offline service initialized successfully');
  } catch (e) {
    logger.error('Failed to initialize offline service', e);
  }

  // Initialiser le service de gamification
  try {
    await GamificationService().init();
    logger.info('Gamification service initialized successfully');
  } catch (e) {
    logger.error('Failed to initialize gamification service', e);
  }

  // Initialiser le service de notifications d'événements
  try {
    final notificationService = EventNotificationService();
    await notificationService.initialize();
    
    // Configurer le callback de navigation
    notificationService.setNavigationCallback((eventId) {
      // Navigation sera gérée par l'app via le router
      // On navigue vers la recherche d'événements
      // L'utilisateur pourra rechercher l'événement ou voir l'historique
      AppRouter.router.go('/search/event');
      logger.info('Notification callback: navigating to event search for event $eventId');
    });
    
    logger.info('Event notification service initialized successfully');
  } catch (e) {
    logger.error('Failed to initialize event notification service', e);
  }

  runApp(const IWantSunApp());
}

class IWantSunApp extends StatelessWidget {
  const IWantSunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProviderSetup.getProviders(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: 'IWantSun',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            locale: localeProvider.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return OfflineBanner(
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
