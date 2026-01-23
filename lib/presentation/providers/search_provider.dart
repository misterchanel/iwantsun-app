import 'package:flutter/foundation.dart';
import 'package:iwantsun/core/error/failures.dart';
import 'package:iwantsun/core/error/exceptions.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/network_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/core/services/analytics_service.dart';
import 'package:iwantsun/core/services/firebase_search_service.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/presentation/providers/search_state.dart';

/// Provider pour gérer l'état de la recherche
/// Utilise Firebase Cloud Functions pour toutes les recherches
class SearchProvider extends ChangeNotifier {
  final FirebaseSearchService _firebaseSearchService;
  final NetworkService _networkService;
  final SearchHistoryService _historyService;
  final GamificationService _gamificationService;
  final AnalyticsService _analyticsService;
  final AppLogger _logger;

  SearchState _state = const SearchInitial();
  SearchState get state => _state;
  SearchParams? _currentParams; // Conserver les paramètres de recherche
  bool _isSearching = false; // Protection contre les recherches concurrentes

  SearchProvider({
    FirebaseSearchService? firebaseSearchService,
    NetworkService? networkService,
    SearchHistoryService? historyService,
    GamificationService? gamificationService,
    AnalyticsService? analyticsService,
    AppLogger? logger,
  })  : _firebaseSearchService = firebaseSearchService ?? FirebaseSearchService(),
        _networkService = networkService ?? NetworkService(),
        _historyService = historyService ?? SearchHistoryService(),
        _gamificationService = gamificationService ?? GamificationService(),
        _analyticsService = analyticsService ?? AnalyticsService(),
        _logger = logger ?? AppLogger();

  /// Effectue une recherche avec les paramètres donnés
  Future<void> search(SearchParams params) async {
    // Protection contre les recherches concurrentes
    if (_isSearching) {
      _logger.warning('Search already in progress, ignoring new search request');
      return;
    }

    _isSearching = true;
    _currentParams = params; // Stocker les paramètres
    _logger.info('Starting search with params: ${params.toString()}');

    try {
        // Vérifier la connexion Internet
      final isConnected = await _networkService.isConnected;
      if (!isConnected) {
        _updateState(const SearchError(
          failure: NetworkFailure('Aucune connexion Internet'),
          message: 'Vérifiez votre connexion Internet et réessayez.',
        ));
        return;
      }
      // Étape 1: Recherche des villes (Point 23 - Simplifié)
      _updateState(SearchLoading.searchingCities());
      await Future.delayed(const Duration(milliseconds: 500));

      // Étape 2: Vérification de la météo (Point 23 - Simplifié)
      _updateState(SearchLoading.checkingWeather());
      await Future.delayed(const Duration(milliseconds: 500));

      // Étape 3: Appel à Firebase Cloud Function (Point 23 - Simplifié)
      _updateState(SearchLoading.searchingHotels());
      await Future.delayed(const Duration(milliseconds: 300));

      // Exécuter la recherche via Firebase Cloud Function
      _logger.info('Calling Firebase Cloud Function for search...');
      final results = await _firebaseSearchService.searchDestinations(params);

      // Simuler le nombre d'hôtels trouvés basé sur les résultats
      _updateState(SearchLoading.searchingHotels(hotelsFound: results.length * 5));
      await Future.delayed(const Duration(milliseconds: 300));

      // Finalisation
      _updateState(SearchLoading.finalizing());
      await Future.delayed(const Duration(milliseconds: 500));

      _logger.info('Search completed with ${results.length} results');

      // Sauvegarder dans l'historique
      String? locationName;
      if (results.isNotEmpty) {
        locationName = results.first.location.name;
      }

      try {
        await _historyService.addSearch(
          params: params,
          resultsCount: results.length,
          locationName: locationName,
          results: results, // Sauvegarder les résultats (Point 12)
        );
      } catch (e) {
        _logger.warning('Failed to save search to history', e);
      }

      // Enregistrer la recherche dans la gamification
      try {
        await _gamificationService.recordSearch();
      } catch (e) {
        _logger.warning('Failed to record search in gamification', e);
      }

      // Tracker dans les analytics
      _analyticsService.trackSearch(
        location: locationName ?? 'Unknown',
        minTemp: params.desiredMinTemperature ?? 0,
        maxTemp: params.desiredMaxTemperature ?? 40,
        radius: params.searchRadius.toInt(),
        resultsCount: results.length,
      );

      // Mettre à jour l'état selon les résultats
      if (results.isEmpty) {
        _updateState(const SearchEmpty(
          message: 'Aucune destination trouvée pour vos critères.\n'
              'Essayez d\'élargir votre zone de recherche ou d\'ajuster vos critères.',
        ));
      } else {
        _updateState(SearchSuccess(
          results: results,
          searchTimestamp: DateTime.now(),
          searchParams: params,
        ));
      }
    } on NetworkFailure catch (e) {
      _logger.error('Network error during search', e);
      _updateState(SearchError(
        failure: e,
        message: 'Erreur de connexion. Vérifiez votre connexion Internet.',
      ));
    } on ServerFailure catch (e) {
      _logger.error('Server error during search', e);
      _updateState(SearchError(
        failure: e,
        message: 'Le serveur ne répond pas. Veuillez réessayer plus tard.',
      ));
    } on ApiKeyFailure catch (e) {
      _logger.error('API key error during search', e);
      _updateState(SearchError(
        failure: e,
        message: 'Configuration API invalide. Vérifiez votre fichier .env.',
      ));
    } on RateLimitFailure catch (e) {
      _logger.error('Rate limit error during search', e);
      _updateState(SearchError(
        failure: e,
        message: 'Trop de requêtes. Veuillez patienter quelques instants.',
      ));
    } on TimeoutFailure catch (e) {
      _logger.error('Timeout error during search', e);
      _updateState(SearchError(
        failure: e,
        message: 'La requête a pris trop de temps. Veuillez réessayer.',
      ));
    } on FirebaseSearchException catch (e) {
      _logger.error('Firebase search error', e);
      String message;
      Failure failure;
      
      switch (e.type) {
        case FirebaseErrorType.noResults:
          message = e.message;
          failure = ValidationFailure(e.message);
          _updateState(SearchEmpty(message: message));
          return;
        case FirebaseErrorType.networkError:
          // Message spécifique pour erreurs Overpass
          if (e.message.contains('serveurs de données géographiques') || 
              e.message.contains('indisponibles')) {
            message = 'Les serveurs de données géographiques sont temporairement indisponibles.\n\n'
                'Veuillez réessayer dans quelques instants. Si le problème persiste, essayez d\'élargir votre zone de recherche.';
          } else {
            message = 'Erreur de connexion avec le serveur. Vérifiez votre connexion Internet.';
          }
          failure = NetworkFailure(message);
          break;
        case FirebaseErrorType.timeout:
          message = 'La requête a pris trop de temps. Veuillez réessayer.';
          failure = TimeoutFailure(message);
          break;
        case FirebaseErrorType.invalidData:
          message = 'Données invalides reçues du serveur. Veuillez réessayer.';
          failure = ServerFailure(message);
          break;
        case FirebaseErrorType.generic:
        default:
          message = 'Erreur lors de la recherche: ${e.message}';
          failure = ServerFailure(message);
          break;
      }
      
      _updateState(SearchError(
        failure: failure,
        message: message,
      ));
    } catch (e, stackTrace) {
      _logger.error('Unexpected error during search', e, stackTrace);
      _updateState(SearchError(
        failure: UnexpectedFailure(e.toString()),
        message: 'Une erreur inattendue est survenue.\n${e.toString()}',
      ));
    } finally {
      _isSearching = false;
    }
  }

  /// Définit directement les résultats (pour historique - Point 12)
  void setResults(List<SearchResult> results) {
    _updateState(SearchSuccess(
      results: results,
      searchTimestamp: DateTime.now(),
      searchParams: _currentParams,
    ));
    _logger.info('Results set directly (from history): ${results.length} results');
  }

  /// Réinitialise l'état de recherche
  void reset() {
    _logger.debug('Resetting search state');
    _updateState(const SearchInitial());
  }

  /// Met à jour l'état et notifie les listeners
  void _updateState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Vérifie si on est dans un état de chargement
  bool get isLoading => _state is SearchLoading;

  /// Vérifie si on a des résultats
  bool get hasResults =>
      _state is SearchSuccess && (_state as SearchSuccess).hasResults;

  /// Récupère les résultats s'ils existent
  List<SearchResult>? get results =>
      _state is SearchSuccess ? (_state as SearchSuccess).results : null;

  /// Récupère l'erreur si elle existe
  Failure? get failure =>
      _state is SearchError ? (_state as SearchError).failure : null;

  /// Récupère les paramètres de recherche actuels
  SearchParams? get currentParams => _currentParams;
}
