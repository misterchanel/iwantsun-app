import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langues supportées par l'application
enum AppLanguage {
  french('fr', 'Français', '🇫🇷'),
  english('en', 'English', '🇬🇧'),
  spanish('es', 'Español', '🇪🇸'),
  german('de', 'Deutsch', '🇩🇪'),
  italian('it', 'Italiano', '🇮🇹');

  const AppLanguage(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.french,
    );
  }
}

/// Provider pour gérer la langue de l'application
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('fr');
  AppLanguage _language = AppLanguage.french;
  bool _isInitialized = false;

  Locale get locale => _locale;
  AppLanguage get language => _language;
  bool get isInitialized => _isInitialized;

  /// Initialiser le provider
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_localeKey);

      if (savedCode != null) {
        _language = AppLanguage.fromCode(savedCode);
        _locale = Locale(_language.code);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Changer la langue
  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;

    _language = language;
    _locale = Locale(language.code);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, language.code);
    } catch (e) {
      // Ignorer l'erreur de sauvegarde
    }
  }

  /// Langues supportées
  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((lang) => Locale(lang.code)).toList();
}

/// Classe de localisation avec les traductions
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('fr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Obtenir une traduction
  String get(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['fr']?[key] ??
        key;
  }

  // Traductions
  static final Map<String, Map<String, String>> _translations = {
    'fr': _frenchTranslations,
    'en': _englishTranslations,
    'es': _spanishTranslations,
    'de': _germanTranslations,
    'it': _italianTranslations,
  };

  // === Traductions françaises ===
  static const Map<String, String> _frenchTranslations = {
    // Général
    'app_name': 'IWantSun',
    'app_tagline': 'Trouvez le soleil, partout dans le monde',
    'continue': 'Continuer',
    'cancel': 'Annuler',
    'confirm': 'Confirmer',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'edit': 'Modifier',
    'search': 'Rechercher',
    'retry': 'Réessayer',
    'close': 'Fermer',
    'back': 'Retour',
    'next': 'Suivant',
    'skip': 'Passer',
    'done': 'Terminé',
    'see_all': 'Tout voir',
    'share': 'Partager',

    // Accueil
    'greeting_morning': 'Bonjour',
    'greeting_afternoon': 'Bon après-midi',
    'greeting_evening': 'Bonsoir',
    'home_subtitle': 'Où souhaitez-vous trouver le soleil ?',
    'quick_search': 'Recherche rapide',
    'advanced_search': 'Recherche avancée',
    'recent_searches': 'Recherches récentes',
    'my_favorites': 'Mes favoris',

    // Recherche
    'search_title': 'Trouver le soleil',
    'location_label': 'Point de départ',
    'dates_label': 'Dates de voyage',
    'temperature_label': 'Température idéale',
    'radius_label': 'Rayon de recherche',
    'find_destination': 'Trouver ma destination',

    // Résultats
    'results_title': 'Destinations ensoleillées',
    'results_found': '{count} destination(s) trouvée(s)',
    'no_results': 'Aucune destination trouvée',
    'modify_search': 'Modifier ma recherche',
    'filter': 'Filtrer',
    'sort': 'Trier',
    'map_view': 'Vue carte',
    'list_view': 'Vue liste',

    // Favoris
    'favorites_title': 'Mes Favoris',
    'favorites_empty': 'Aucun favori pour le moment',
    'add_to_favorites': 'Ajouter aux favoris',
    'remove_from_favorites': 'Retirer des favoris',
    'personal_notes': 'Notes personnelles',

    // Historique
    'history_title': 'Historique',
    'history_empty': 'Aucun historique',
    'clear_history': 'Vider l\'historique',

    // Paramètres
    'settings_title': 'Paramètres',
    'appearance': 'Apparence',
    'theme': 'Thème',
    'theme_light': 'Clair',
    'theme_dark': 'Sombre',
    'theme_system': 'Système',
    'language': 'Langue',
    'units': 'Unités',
    'temperature_unit': 'Température',
    'distance_unit': 'Distance',
    'notifications': 'Notifications',
    'about': 'À propos',

    // Erreurs
    'error_generic': 'Une erreur est survenue',
    'error_network': 'Problème de connexion',
    'error_offline': 'Mode hors ligne',

    // Météo
    'sunny_days': 'jours ensoleillés',
    'rainy_days': 'jours de pluie',
    'average_temp': 'Température moyenne',
    'score': 'Score',
  };

  // === Traductions anglaises ===
  static const Map<String, String> _englishTranslations = {
    // General
    'app_name': 'IWantSun',
    'app_tagline': 'Find sunshine, anywhere in the world',
    'continue': 'Continue',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'retry': 'Retry',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'skip': 'Skip',
    'done': 'Done',
    'see_all': 'See all',
    'share': 'Share',

    // Home
    'greeting_morning': 'Good morning',
    'greeting_afternoon': 'Good afternoon',
    'greeting_evening': 'Good evening',
    'home_subtitle': 'Where would you like to find sunshine?',
    'quick_search': 'Quick search',
    'advanced_search': 'Advanced search',
    'recent_searches': 'Recent searches',
    'my_favorites': 'My favorites',

    // Search
    'search_title': 'Find sunshine',
    'location_label': 'Starting point',
    'dates_label': 'Travel dates',
    'temperature_label': 'Ideal temperature',
    'radius_label': 'Search radius',
    'find_destination': 'Find my destination',

    // Results
    'results_title': 'Sunny destinations',
    'results_found': '{count} destination(s) found',
    'no_results': 'No destinations found',
    'modify_search': 'Modify search',
    'filter': 'Filter',
    'sort': 'Sort',
    'map_view': 'Map view',
    'list_view': 'List view',

    // Favorites
    'favorites_title': 'My Favorites',
    'favorites_empty': 'No favorites yet',
    'add_to_favorites': 'Add to favorites',
    'remove_from_favorites': 'Remove from favorites',
    'personal_notes': 'Personal notes',

    // History
    'history_title': 'History',
    'history_empty': 'No history',
    'clear_history': 'Clear history',

    // Settings
    'settings_title': 'Settings',
    'appearance': 'Appearance',
    'theme': 'Theme',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'theme_system': 'System',
    'language': 'Language',
    'units': 'Units',
    'temperature_unit': 'Temperature',
    'distance_unit': 'Distance',
    'notifications': 'Notifications',
    'about': 'About',

    // Errors
    'error_generic': 'An error occurred',
    'error_network': 'Connection problem',
    'error_offline': 'Offline mode',

    // Weather
    'sunny_days': 'sunny days',
    'rainy_days': 'rainy days',
    'average_temp': 'Average temperature',
    'score': 'Score',
  };

  // === Traductions espagnoles ===
  static const Map<String, String> _spanishTranslations = {
    'app_name': 'IWantSun',
    'app_tagline': 'Encuentra el sol, en cualquier parte del mundo',
    'continue': 'Continuar',
    'cancel': 'Cancelar',
    'confirm': 'Confirmar',
    'save': 'Guardar',
    'delete': 'Eliminar',
    'search': 'Buscar',
    'retry': 'Reintentar',
    'close': 'Cerrar',
    'back': 'Atrás',
    'greeting_morning': 'Buenos días',
    'greeting_afternoon': 'Buenas tardes',
    'greeting_evening': 'Buenas noches',
    'home_subtitle': '¿Dónde te gustaría encontrar el sol?',
    'favorites_title': 'Mis Favoritos',
    'history_title': 'Historial',
    'settings_title': 'Configuración',
    'theme': 'Tema',
    'language': 'Idioma',
    'sunny_days': 'días soleados',
    'score': 'Puntuación',
  };

  // === Traductions allemandes ===
  static const Map<String, String> _germanTranslations = {
    'app_name': 'IWantSun',
    'app_tagline': 'Finde Sonne, überall auf der Welt',
    'continue': 'Weiter',
    'cancel': 'Abbrechen',
    'confirm': 'Bestätigen',
    'save': 'Speichern',
    'delete': 'Löschen',
    'search': 'Suchen',
    'retry': 'Wiederholen',
    'close': 'Schließen',
    'back': 'Zurück',
    'greeting_morning': 'Guten Morgen',
    'greeting_afternoon': 'Guten Tag',
    'greeting_evening': 'Guten Abend',
    'home_subtitle': 'Wo möchtest du Sonne finden?',
    'favorites_title': 'Meine Favoriten',
    'history_title': 'Verlauf',
    'settings_title': 'Einstellungen',
    'theme': 'Design',
    'language': 'Sprache',
    'sunny_days': 'Sonnentage',
    'score': 'Bewertung',
  };

  // === Traductions italiennes ===
  static const Map<String, String> _italianTranslations = {
    'app_name': 'IWantSun',
    'app_tagline': 'Trova il sole, ovunque nel mondo',
    'continue': 'Continua',
    'cancel': 'Annulla',
    'confirm': 'Conferma',
    'save': 'Salva',
    'delete': 'Elimina',
    'search': 'Cerca',
    'retry': 'Riprova',
    'close': 'Chiudi',
    'back': 'Indietro',
    'greeting_morning': 'Buongiorno',
    'greeting_afternoon': 'Buon pomeriggio',
    'greeting_evening': 'Buonasera',
    'home_subtitle': 'Dove vorresti trovare il sole?',
    'favorites_title': 'I miei preferiti',
    'history_title': 'Cronologia',
    'settings_title': 'Impostazioni',
    'theme': 'Tema',
    'language': 'Lingua',
    'sunny_days': 'giorni di sole',
    'score': 'Punteggio',
  };

  // === Getters de raccourci ===
  String get appName => get('app_name');
  String get appTagline => get('app_tagline');
  String get continueLabel => get('continue');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get save => get('save');
  String get delete => get('delete');
  String get search => get('search');
  String get retry => get('retry');
  String get close => get('close');
  String get back => get('back');

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return get('greeting_morning');
    if (hour < 18) return get('greeting_afternoon');
    return get('greeting_evening');
  }
}

/// Delegate pour les localisations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any((lang) => lang.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
