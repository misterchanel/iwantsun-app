/// Configuration pour les liens d'affiliation
class AffiliateConfig {
  /// ID d'affilié Booking.com
  ///
  /// Pour obtenir un ID d'affilié:
  /// 1. Inscrivez-vous sur https://www.booking.com/affiliate-program/
  /// 2. Une fois approuvé, vous recevrez votre ID d'affilié (aid)
  /// 3. Remplacez 'VOTRE_ID_AFFILIE' ci-dessous par votre ID
  ///
  /// Exemple: Si votre ID est '12345', remplacez par:
  /// static const String bookingAffiliateId = '12345';
  static const String bookingAffiliateId = 'VOTRE_ID_AFFILIE';

  /// Vérifie si l'ID d'affilié est configuré
  static bool get isConfigured => bookingAffiliateId != 'VOTRE_ID_AFFILIE';

  /// Génère une URL Booking.com avec affiliation
  static String generateBookingUrl({
    required String hotelName,
    String? city,
    required DateTime checkIn,
    required DateTime checkOut,
    double? latitude,
    double? longitude,
  }) {
    final checkInStr = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
    final checkOutStr = '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}';

    // Construire la recherche
    final searchQuery = city != null ? '$hotelName, $city' : hotelName;

    // Base URL
    var url = 'https://www.booking.com/searchresults.html'
        '?ss=${Uri.encodeComponent(searchQuery)}'
        '&checkin=$checkInStr'
        '&checkout=$checkOutStr';

    // Ajouter les coordonnées GPS si disponibles (améliore la précision)
    if (latitude != null && longitude != null) {
      url += '&latitude=$latitude&longitude=$longitude';
    }

    // Ajouter l'ID d'affilié si configuré
    if (isConfigured) {
      url += '&aid=$bookingAffiliateId';
    }

    return url;
  }
}
