import 'package:flutter/material.dart';

/// Types d'événements disponibles
enum EventType {
  concert,
  festival,
  sport,
  culture,
  gastronomy,
  market,
  exhibition,
  conference,
  theater,
  cinema,
  other,
}

/// Extension pour les propriétés des types d'événements
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.concert:
        return 'Concert';
      case EventType.festival:
        return 'Festival';
      case EventType.sport:
        return 'Événement sportif';
      case EventType.culture:
        return 'Événement culturel';
      case EventType.gastronomy:
        return 'Gastronomie';
      case EventType.market:
        return 'Marché';
      case EventType.exhibition:
        return 'Exposition';
      case EventType.conference:
        return 'Conférence';
      case EventType.theater:
        return 'Théâtre';
      case EventType.cinema:
        return 'Cinéma';
      case EventType.other:
        return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.concert:
        return Icons.music_note;
      case EventType.festival:
        return Icons.festival;
      case EventType.sport:
        return Icons.sports_soccer;
      case EventType.culture:
        return Icons.museum;
      case EventType.gastronomy:
        return Icons.restaurant;
      case EventType.market:
        return Icons.store;
      case EventType.exhibition:
        return Icons.art_track;
      case EventType.conference:
        return Icons.business_center;
      case EventType.theater:
        return Icons.theater_comedy;
      case EventType.cinema:
        return Icons.movie;
      case EventType.other:
        return Icons.event;
    }
  }
}

/// Entité représentant un événement
class Event {
  final String id;
  final String name;
  final String? description;
  final EventType type;
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime? endDate;
  final String? locationName;
  final String? city;
  final String? country;
  final double? distanceFromCenter; // Distance depuis le centre de recherche (en km)
  final String? imageUrl;
  final String? websiteUrl;
  final double? price;
  final String? priceCurrency;

  const Event({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.startDate,
    this.endDate,
    this.locationName,
    this.city,
    this.country,
    this.distanceFromCenter,
    this.imageUrl,
    this.websiteUrl,
    this.price,
    this.priceCurrency,
  });

  /// Vérifie si l'événement est en cours
  bool get isOngoing {
    final now = DateTime.now();
    if (endDate != null) {
      return now.isAfter(startDate) && now.isBefore(endDate!);
    }
    return now.isAfter(startDate) && now.isBefore(startDate.add(const Duration(days: 1)));
  }

  /// Vérifie si l'événement est à venir
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  /// Vérifie si l'événement est passé
  bool get isPast {
    if (endDate != null) {
      return DateTime.now().isAfter(endDate!);
    }
    return DateTime.now().isAfter(startDate.add(const Duration(days: 1)));
  }

  /// Format de la date pour affichage
  String get dateDisplay {
    if (endDate != null) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate!)}';
    }
    return _formatDate(startDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
