import 'package:flutter/foundation.dart';
import 'package:iwantsun/core/error/failures.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/core/services/network_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/search_result.dart';
import 'package:iwantsun/domain/usecases/search_locations_usecase.dart';
import 'package:iwantsun/presentation/providers/search_state.dart';

/// Provider pour gérer l'état de la recherche
class SearchProvider extends ChangeNotifier {
  final SearchLocationsUseCase _searchLocationsUseCase;
  final NetworkService _networkService;
  final SearchHistoryService _historyService;
  final AppLogger _logger;

  SearchState _state = const SearchInitial();
  SearchState get state => _state;
  SearchParams? _currentParams; // Conserver les paramètres de recherche

  SearchProvider({
    required SearchLocationsUseCase searchLocationsUseCase,
    NetworkService? networkService,
    SearchHistoryService? historyService,
    AppLogger? logger,
  })  : _searchLocationsUseCase = searchLocationsUseCase,
        _networkService = networkService ?? NetworkService(),
        _historyService = historyService ?? SearchHistoryService(),
        _logger = logger ?? AppLogger();

  /// Effectue une recherche avec les paramètres donnés
  Future<void> search(SearchParams params) async {
    _currentParams = params; // Stocker les paramètres
    _logger.info('Starting search with params: ${params.toString()}');

    // Vérifier la connexion Internet
    final isConnected = await _networkService.isConnected;
    if (!isConnected) {
      _updateState(const SearchError(
        failure: NetworkFailure('Aucune connexion Internet'),
        message: 'Vérifiez votre connexion Internet et réessayez.',
      ));
      return;
    }

    try {
      // Étape 1: Recherche des villes
      _updateState(SearchLoading.searchingCities());
      await Future.delayed(const Duration(milliseconds: 300)); // Petit délai pour l'animation

      // Simuler la progression de la recherche de villes
      _updateState(SearchLoading.searchingCities(citiesFound: 50));
      await Future.delayed(const Duration(milliseconds: 200));

      _updateState(SearchLoading.searchingCities(citiesFound: 127));
      await Future.delayed(const Duration(milliseconds: 200));

      // Étape 2: Vérification de la météo
      _updateState(SearchLoading.checkingWeather());
      await Future.delayed(const Duration(milliseconds: 300));

      // Simuler la progression de la vérification météo
      _updateState(SearchLoading.checkingWeather(locationsChecked: 10, totalLocations: 50));
      await Future.delayed(const Duration(milliseconds: 400));

      _updateState(SearchLoading.checkingWeather(locationsChecked: 25, totalLocations: 50));
      await Future.delayed(const Duration(milliseconds: 400));

      _updateState(SearchLoading.checkingWeather(locationsChecked: 40, totalLocations: 50));
      await Future.delayed(const Duration(milliseconds: 300));

      // Étape 3: Recherche d'hôtels
      _updateState(SearchLoading.searchingHotels());
      await Future.delayed(const Duration(milliseconds: 300));

      // Exécuter la recherche réelle
      final results = await _searchLocationsUseCase.execute(params);

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
        );
      } catch (e) {
        _logger.warning('Failed to save search to history', e);
      }

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
    } catch (e, stackTrace) {
      _logger.error('Unexpected error during search', e, stackTrace);
      _updateState(SearchError(
        failure: UnexpectedFailure(e.toString()),
        message: 'Une erreur inattendue est survenue.\n${e.toString()}',
      ));
    }
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
