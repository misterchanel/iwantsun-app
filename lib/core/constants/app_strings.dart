/// Constantes de textes pour l'application IWantSun
/// Tous les textes sont centralisés ici pour faciliter la maintenance
/// et préparer l'internationalisation future

class AppStrings {
  AppStrings._();

  // ============================================
  // GÉNÉRAL
  // ============================================
  static const String appName = 'IWantSun';
  static const String appTagline = 'Trouvez le soleil, partout dans le monde';
  static const String appDescription = 'Votre assistant personnel pour dénicher les destinations les plus ensoleillées';

  // Actions générales
  static const String continueAction = 'Continuer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';
  static const String search = 'Rechercher';
  static const String retry = 'Réessayer';
  static const String close = 'Fermer';
  static const String back = 'Retour';
  static const String next = 'Suivant';
  static const String skip = 'Passer';
  static const String done = 'Terminé';
  static const String seeAll = 'Tout voir';
  static const String share = 'Partager';

  // ============================================
  // ONBOARDING
  // ============================================
  static const String onboardingTitle1 = 'Bienvenue sur IWantSun';
  static const String onboardingSubtitle1 = 'Découvrez les destinations où le soleil vous attend';

  static const String onboardingTitle2 = 'Recherche intelligente';
  static const String onboardingSubtitle2 = 'Indiquez vos préférences et laissez-nous trouver votre paradis ensoleillé';

  static const String onboardingTitle3 = 'Prévisions fiables';
  static const String onboardingSubtitle3 = 'Des données météo précises pour planifier sereinement votre escapade';

  static const String onboardingTitle4 = 'Prêt à partir ?';
  static const String onboardingSubtitle4 = 'Commencez votre recherche et trouvez votre prochaine destination de rêve';

  static const String onboardingGetStarted = 'C\'est parti !';

  // ============================================
  // ÉCRAN D'ACCUEIL
  // ============================================
  static const String homeGreetingMorning = 'Bonjour';
  static const String homeGreetingAfternoon = 'Bon après-midi';
  static const String homeGreetingEvening = 'Bonsoir';
  static const String homeSubtitle = 'Où souhaitez-vous trouver le soleil ?';

  static const String homeQuickSearchTitle = 'Recherche rapide';
  static const String homeQuickSearchDescription = 'Trouvez une destination ensoleillée en quelques clics';
  static const String homeAdvancedSearchTitle = 'Recherche avancée';
  static const String homeAdvancedSearchDescription = 'Affinez vos critères pour la destination parfaite';

  static const String homeRecentSearches = 'Vos recherches récentes';
  static const String homeNoRecentSearches = 'Aucune recherche récente';
  static const String homeFavorites = 'Vos destinations favorites';
  static const String homeNoFavorites = 'Aucun favori pour le moment';

  static const String homeStartSearching = 'Lancez votre première recherche';
  static const String homeExploreWorld = 'Le monde ensoleillé vous attend !';

  // ============================================
  // RECHERCHE
  // ============================================
  static const String searchTitle = 'Trouver le soleil';
  static const String searchSimpleMode = 'Recherche simple';
  static const String searchAdvancedMode = 'Recherche avancée';

  static const String searchLocationLabel = 'Point de départ';
  static const String searchLocationHint = 'Où êtes-vous actuellement ?';
  static const String searchLocationPlaceholder = 'Paris, France';

  static const String searchDatesLabel = 'Quand partez-vous ?';
  static const String searchDatesHint = 'Sélectionnez vos dates de voyage';
  static const String searchDatesFlexible = 'Dates flexibles';

  static const String searchTemperatureLabel = 'Température idéale';
  static const String searchTemperatureHint = 'Entre {min}°C et {max}°C';

  static const String searchRadiusLabel = 'Rayon de recherche';
  static const String searchRadiusHint = 'Jusqu\'à {radius} km';

  static const String searchActivitiesLabel = 'Activités souhaitées';
  static const String searchActivitiesHint = 'Sélectionnez vos centres d\'intérêt';

  static const String searchButton = 'Trouver ma destination';
  static const String searchButtonSearching = 'Recherche en cours...';

  // Activités
  static const String activityBeach = 'Plage';
  static const String activityHiking = 'Randonnée';
  static const String activityCulture = 'Culture';
  static const String activityGastronomy = 'Gastronomie';
  static const String activityNightlife = 'Vie nocturne';
  static const String activitySpa = 'Spa & Bien-être';
  static const String activitySports = 'Sports';
  static const String activityNature = 'Nature';

  // ============================================
  // RÉSULTATS
  // ============================================
  static const String resultsTitle = 'Destinations ensoleillées';
  static const String resultsSubtitle = '{count} destination{plural} trouvée{plural}';
  static const String resultsNoResults = 'Aucune destination trouvée';
  static const String resultsNoResultsHint = 'Essayez d\'élargir vos critères de recherche';
  static const String resultsModifySearch = 'Modifier ma recherche';

  static const String resultsFilterButton = 'Filtrer';
  static const String resultsSortButton = 'Trier';
  static const String resultsMapView = 'Voir sur la carte';
  static const String resultsListView = 'Voir en liste';

  // Tri
  static const String sortByScore = 'Meilleur score';
  static const String sortByTemperature = 'Température';
  static const String sortByDistance = 'Distance';
  static const String sortByName = 'Nom';

  // Filtres
  static const String filterMinScore = 'Score minimum';
  static const String filterTemperatureRange = 'Plage de température';
  static const String filterSunnyDays = 'Jours ensoleillés minimum';
  static const String filterResetAll = 'Réinitialiser les filtres';
  static const String filterApply = 'Appliquer';

  // Carte de résultat
  static const String resultCardScore = 'Score soleil';
  static const String resultCardTemperature = 'Température moyenne';
  static const String resultCardSunnyDays = 'jours de soleil';
  static const String resultCardRainDays = 'jours de pluie';
  static const String resultCardViewDetails = 'Voir les détails';
  static const String resultCardAddFavorite = 'Ajouter aux favoris';
  static const String resultCardRemoveFavorite = 'Retirer des favoris';

  // ============================================
  // DÉTAILS DESTINATION
  // ============================================
  static const String detailsOverview = 'Aperçu';
  static const String detailsWeather = 'Météo';
  static const String detailsActivities = 'Activités';
  static const String detailsHotels = 'Hébergements';

  static const String detailsForecast = 'Prévisions météo';
  static const String detailsNearbyActivities = 'Activités à proximité';
  static const String detailsNearbyHotels = 'Hôtels recommandés';

  static const String detailsBookNow = 'Réserver maintenant';
  static const String detailsShowOnMap = 'Voir sur la carte';
  static const String detailsGetDirections = 'Obtenir l\'itinéraire';

  // ============================================
  // FAVORIS
  // ============================================
  static const String favoritesTitle = 'Mes Favoris';
  static const String favoritesSubtitle = '{count} destination{plural} sauvegardée{plural}';
  static const String favoritesEmpty = 'Aucun favori pour le moment';
  static const String favoritesEmptyHint = 'Explorez et ajoutez vos destinations coup de cœur !';
  static const String favoritesStartExploring = 'Explorer les destinations';

  static const String favoritesSort = 'Trier';
  static const String favoritesFilter = 'Filtrer';
  static const String favoritesClearAll = 'Tout supprimer';
  static const String favoritesClearConfirm = 'Supprimer tous vos favoris ?';
  static const String favoritesClearWarning = 'Cette action est irréversible.';

  static const String favoritesNotes = 'Notes personnelles';
  static const String favoritesNotesHint = 'Ajoutez vos notes sur cette destination...';
  static const String favoritesNotesEmpty = 'Aucune note';

  static const String favoritesStats = 'Statistiques';
  static const String favoritesStatsCountries = 'pays différents';
  static const String favoritesStatsAvgScore = 'score moyen';
  static const String favoritesStatsAvgTemp = 'température moyenne';
  static const String favoritesStatsSunnyDays = 'jours ensoleillés au total';

  static const String favoritesTopDestinations = 'Top destinations';
  static const String favoritesRemoved = 'Favori retiré';
  static const String favoritesAdded = 'Ajouté aux favoris !';

  // ============================================
  // HISTORIQUE
  // ============================================
  static const String historyTitle = 'Historique';
  static const String historySubtitle = '{count} recherche{plural}';
  static const String historyEmpty = 'Aucun historique';
  static const String historyEmptyHint = 'Vos recherches apparaîtront ici';
  static const String historyStartSearch = 'Nouvelle recherche';

  static const String historyClear = 'Vider l\'historique';
  static const String historyClearConfirm = 'Vider tout l\'historique ?';
  static const String historyClearWarning = 'Toutes vos recherches seront effacées.';
  static const String historyEntryRemoved = 'Entrée supprimée';

  static const String historyToday = 'Aujourd\'hui';
  static const String historyYesterday = 'Hier';
  static const String historyResults = '{count} résultat{plural}';
  static const String historyReplaySearch = 'Relancer cette recherche';

  // ============================================
  // PARAMÈTRES
  // ============================================
  static const String settingsTitle = 'Paramètres';

  static const String settingsAppearance = 'Apparence';
  static const String settingsTheme = 'Thème';
  static const String settingsThemeLight = 'Clair';
  static const String settingsThemeDark = 'Sombre';
  static const String settingsThemeSystem = 'Système';

  static const String settingsUnits = 'Unités';
  static const String settingsTemperatureUnit = 'Température';
  static const String settingsCelsius = 'Celsius (°C)';
  static const String settingsFahrenheit = 'Fahrenheit (°F)';
  static const String settingsDistanceUnit = 'Distance';
  static const String settingsKilometers = 'Kilomètres (km)';
  static const String settingsMiles = 'Miles (mi)';

  static const String settingsNotifications = 'Notifications';
  static const String settingsNotificationsEnable = 'Activer les notifications';
  static const String settingsNotificationsWeather = 'Alertes météo';
  static const String settingsNotificationsDeals = 'Bons plans et promotions';

  static const String settingsData = 'Données';
  static const String settingsClearCache = 'Vider le cache';
  static const String settingsCacheCleared = 'Cache vidé';
  static const String settingsExportData = 'Exporter mes données';
  static const String settingsDeleteAccount = 'Supprimer mon compte';

  static const String settingsAbout = 'À propos';
  static const String settingsVersion = 'Version';
  static const String settingsPrivacy = 'Politique de confidentialité';
  static const String settingsTerms = 'Conditions d\'utilisation';
  static const String settingsContact = 'Nous contacter';
  static const String settingsRate = 'Noter l\'application';

  // ============================================
  // ERREURS
  // ============================================
  static const String errorGeneric = 'Une erreur est survenue';
  static const String errorGenericHint = 'Veuillez réessayer dans quelques instants';

  static const String errorNetwork = 'Problème de connexion';
  static const String errorNetworkHint = 'Vérifiez votre connexion internet et réessayez';

  static const String errorServer = 'Service indisponible';
  static const String errorServerHint = 'Nos serveurs rencontrent des difficultés. Réessayez bientôt.';

  static const String errorLocation = 'Localisation introuvable';
  static const String errorLocationHint = 'Vérifiez l\'orthographe ou essayez une autre ville';

  static const String errorTimeout = 'Délai dépassé';
  static const String errorTimeoutHint = 'La requête a pris trop de temps. Réessayez.';

  static const String errorNoResults = 'Aucun résultat';
  static const String errorNoResultsHint = 'Essayez d\'élargir vos critères de recherche';

  static const String errorOffline = 'Mode hors-ligne';
  static const String errorOfflineHint = 'Certaines fonctionnalités nécessitent une connexion internet';

  // ============================================
  // CHARGEMENT
  // ============================================
  static const String loadingGeneric = 'Chargement...';
  static const String loadingSearch = 'Recherche des meilleures destinations...';
  static const String loadingWeather = 'Récupération des données météo...';
  static const String loadingActivities = 'Découverte des activités...';
  static const String loadingHotels = 'Recherche des hébergements...';
  static const String loadingMap = 'Chargement de la carte...';
  static const String loadingFavorites = 'Chargement de vos favoris...';
  static const String loadingHistory = 'Chargement de l\'historique...';

  // Messages de chargement engageants
  static const List<String> loadingMessages = [
    'Analyse du ciel en cours...',
    'Consultation des météorologues...',
    'Calcul des rayons de soleil...',
    'Repérage des plus belles plages...',
    'Exploration des destinations...',
    'Vérification de l\'ensoleillement...',
    'Recherche du paradis ensoleillé...',
    'Les destinations se préparent...',
  ];

  // ============================================
  // MESSAGES DE SUCCÈS
  // ============================================
  static const String successSaved = 'Enregistré avec succès';
  static const String successDeleted = 'Supprimé avec succès';
  static const String successCopied = 'Copié dans le presse-papier';
  static const String successShared = 'Partagé avec succès';
  static const String successExported = 'Export réussi';

  // ============================================
  // ACCESSIBILITÉ
  // ============================================
  static const String a11yCloseButton = 'Fermer';
  static const String a11yBackButton = 'Retour';
  static const String a11yMenuButton = 'Menu';
  static const String a11ySearchButton = 'Rechercher';
  static const String a11yFavoriteButton = 'Ajouter aux favoris';
  static const String a11yUnfavoriteButton = 'Retirer des favoris';
  static const String a11yShareButton = 'Partager';
  static const String a11yMapButton = 'Voir sur la carte';
  static const String a11yFilterButton = 'Filtrer les résultats';
  static const String a11ySortButton = 'Trier les résultats';

  static const String a11yScoreLabel = 'Score de {score} sur 100';
  static const String a11yTemperatureLabel = '{temp} degrés Celsius';
  static const String a11ySunnyDaysLabel = '{days} jours ensoleillés';

  // ============================================
  // HELPERS
  // ============================================

  /// Retourne le message de salutation approprié
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return homeGreetingMorning;
    if (hour < 18) return homeGreetingAfternoon;
    return homeGreetingEvening;
  }

  /// Formate un nombre avec pluriel
  static String pluralize(int count, String singular, {String? plural}) {
    return count <= 1 ? singular : (plural ?? '${singular}s');
  }

  /// Retourne un message de chargement aléatoire
  static String getRandomLoadingMessage() {
    return loadingMessages[DateTime.now().millisecond % loadingMessages.length];
  }
}
