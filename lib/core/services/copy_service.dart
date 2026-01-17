import 'dart:math';

/// Service de copywriting pour générer des textes engageants et contextuels
class CopyService {
  static final CopyService _instance = CopyService._internal();
  factory CopyService() => _instance;
  CopyService._internal();

  final _random = Random();

  // ============================================
  // MESSAGES D'ENCOURAGEMENT
  // ============================================

  /// Message d'encouragement pour une recherche
  String getSearchEncouragement() {
    final messages = [
      'Prêt à trouver votre coin de paradis ? ☀️',
      'Le soleil vous attend quelque part...',
      'Votre prochaine aventure ensoleillée commence ici',
      'Où le soleil brillera-t-il pour vous ?',
      'Laissez-nous vous guider vers la lumière',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Message après une recherche réussie
  String getSearchSuccessMessage(int resultCount) {
    if (resultCount == 0) {
      return 'Aucune destination ne correspond à vos critères. Élargissez votre recherche !';
    }
    if (resultCount == 1) {
      return 'Nous avons trouvé LA destination parfaite pour vous !';
    }
    if (resultCount <= 5) {
      return 'Voici $resultCount destinations ensoleillées rien que pour vous !';
    }
    return '$resultCount destinations vous tendent les bras !';
  }

  /// Message quand aucun résultat
  String getNoResultsMessage() {
    final messages = [
      'Le soleil se cache pour l\'instant...',
      'Aucune destination ne correspond, mais ne perdez pas espoir !',
      'Essayez d\'autres critères pour débloquer de nouvelles destinations',
      'Le paradis est peut-être un peu plus loin, élargissez la recherche !',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  // ============================================
  // DESCRIPTIONS MÉTÉO
  // ============================================

  /// Description engageante de la température
  String getTemperatureDescription(double temp) {
    if (temp >= 35) return 'Chaleur intense - Prévoyez la crème solaire ! 🔥';
    if (temp >= 30) return 'Parfait pour la plage et les cocktails 🏖️';
    if (temp >= 25) return 'Idéal pour explorer en toute légèreté 🌴';
    if (temp >= 20) return 'Doux et agréable - Le bonheur ! ☀️';
    if (temp >= 15) return 'Frais mais ensoleillé - Prenez une petite laine 🧥';
    if (temp >= 10) return 'Un peu frais, mais le soleil réchauffe 🌤️';
    return 'Frisquet - Mais le ciel est bleu ! ❄️☀️';
  }

  /// Description du score soleil
  String getScoreDescription(double score) {
    if (score >= 90) return 'Destination exceptionnelle ! Soleil garanti';
    if (score >= 80) return 'Excellent choix, le beau temps vous attend';
    if (score >= 70) return 'Très bonne destination ensoleillée';
    if (score >= 60) return 'Bonne destination avec un ensoleillement correct';
    if (score >= 50) return 'Destination correcte, quelques nuages possibles';
    return 'Météo variable, mais des moments ensoleillés';
  }

  /// Description des jours ensoleillés
  String getSunnyDaysDescription(int days, int totalDays) {
    final ratio = days / totalDays;
    if (ratio >= 0.9) return 'Soleil quasi permanent !';
    if (ratio >= 0.7) return 'Majoritairement ensoleillé';
    if (ratio >= 0.5) return 'Mix soleil et nuages';
    if (ratio >= 0.3) return 'Quelques éclaircies';
    return 'Météo capricieuse';
  }

  // ============================================
  // MOTIVATIONS POUR LES FAVORIS
  // ============================================

  /// Message après ajout en favori
  String getFavoriteAddedMessage(String locationName) {
    final messages = [
      '$locationName rejoint votre liste de rêves !',
      'Excellente destination sauvegardée !',
      '$locationName vous attend dans vos favoris',
      'Un pas de plus vers votre prochain voyage !',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Message pour encourager à ajouter des favoris
  String getEmptyFavoritesMessage() {
    final messages = [
      'Votre liste de rêves est vide pour l\'instant...',
      'Explorez et sauvegardez vos coups de cœur !',
      'Commencez à construire votre collection de destinations',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  // ============================================
  // TIPS ET CONSEILS
  // ============================================

  /// Conseil contextuel pour la recherche
  String getSearchTip() {
    final tips = [
      '💡 Astuce : Élargissez le rayon de recherche pour plus de résultats',
      '💡 Conseil : Les dates flexibles augmentent vos chances de trouver du soleil',
      '💡 Le saviez-vous ? La température idéale pour la plage est entre 25°C et 30°C',
      '💡 Pro tip : Combinez plusieurs activités pour affiner votre recherche',
    ];
    return tips[_random.nextInt(tips.length)];
  }

  /// Conseil pour les favoris
  String getFavoritesTip() {
    final tips = [
      '💡 Ajoutez des notes à vos favoris pour vous souvenir pourquoi vous les aimez',
      '💡 Comparez vos favoris pour choisir votre prochaine destination',
      '💡 Partagez vos favoris avec vos proches pour planifier ensemble',
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // ============================================
  // FORMATAGE CONTEXTUEL
  // ============================================

  /// Formatage de la distance
  String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  /// Formatage de la durée de voyage estimée
  String formatTravelTime(double km) {
    // Estimation : 100 km/h en moyenne
    final hours = km / 100;
    if (hours < 1) return '< 1h en voiture';
    if (hours < 3) return '~${hours.round()}h en voiture';
    if (hours < 8) return '${hours.round()}h en voiture ou quelques heures en avion';
    return 'Destination lointaine - Avion recommandé';
  }

  /// Description de la période
  String describePeriod(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    if (days == 1) return 'pour une journée';
    if (days <= 3) return 'pour un week-end prolongé';
    if (days <= 7) return 'pour une semaine';
    if (days <= 14) return 'pour deux semaines';
    return 'pour $days jours';
  }

  // ============================================
  // CALL TO ACTION
  // ============================================

  /// CTA pour lancer une recherche
  String getSearchCTA() {
    final ctas = [
      'Trouver ma destination',
      'Découvrir le soleil',
      'Lancer la recherche',
      'Partir à l\'aventure',
    ];
    return ctas[_random.nextInt(ctas.length)];
  }

  /// CTA pour les résultats
  String getResultsCTA(int count) {
    if (count == 0) return 'Modifier ma recherche';
    if (count == 1) return 'Découvrir cette destination';
    return 'Explorer les $count destinations';
  }

  /// CTA pour les favoris vides
  String getEmptyFavoritesCTA() {
    return 'Commencer à explorer';
  }

  // ============================================
  // NOTIFICATIONS / FEEDBACK
  // ============================================

  /// Message de bienvenue de retour
  String getWelcomeBackMessage(String? lastDestination) {
    if (lastDestination != null) {
      return 'Bon retour ! Toujours intéressé par $lastDestination ?';
    }
    return 'Bon retour ! Prêt pour de nouvelles aventures ensoleillées ?';
  }

  /// Message saisonnier
  String getSeasonalMessage() {
    final month = DateTime.now().month;
    if (month >= 6 && month <= 8) {
      return 'C\'est la saison idéale pour les plages du sud !';
    }
    if (month >= 12 || month <= 2) {
      return 'Envie d\'échapper à l\'hiver ? Cap sur le soleil !';
    }
    if (month >= 3 && month <= 5) {
      return 'Le printemps arrive, et les destinations se réveillent !';
    }
    return 'L\'automne est parfait pour les destinations méditerranéennes';
  }

  // ============================================
  // MICROCOPY CONTEXTUEL
  // ============================================

  /// Placeholder contextuel pour la recherche
  String getLocationPlaceholder() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'D\'où partez-vous ce matin ?';
    }
    return 'Indiquez votre point de départ';
  }

  /// Label dynamique pour le bouton de recherche
  String getSearchButtonLabel(bool isSearching) {
    if (isSearching) {
      return 'Recherche du soleil...';
    }
    return getSearchCTA();
  }

  /// Message d'état de la liste vide
  String getEmptyStateMessage(String context) {
    switch (context) {
      case 'results':
        return 'Le soleil se cache aujourd\'hui dans ces critères...';
      case 'favorites':
        return 'Votre collection de rêves attend ses premières destinations';
      case 'history':
        return 'Votre journal de voyages est encore vierge';
      default:
        return 'Rien à afficher pour le moment';
    }
  }

  /// Message de confirmation de suppression
  String getDeleteConfirmation(String itemType) {
    switch (itemType) {
      case 'favorite':
        return 'Retirer cette destination de vos rêves ?';
      case 'history':
        return 'Effacer cette recherche de votre mémoire ?';
      case 'all_favorites':
        return 'Vider votre collection de destinations rêvées ?';
      case 'all_history':
        return 'Effacer toutes vos recherches passées ?';
      default:
        return 'Supprimer cet élément ?';
    }
  }
}
