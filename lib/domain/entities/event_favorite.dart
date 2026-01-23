import 'package:equatable/equatable.dart';
import 'package:iwantsun/domain/entities/event.dart';

/// Représente un événement favori sauvegardé par l'utilisateur
class EventFavorite extends Equatable {
  final String id;
  final String eventId; // ID original de l'événement
  final String eventName;
  final EventType eventType;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime? endDate;
  final String? locationName;
  final String? city;
  final String? country;
  final String? imageUrl;
  final String? websiteUrl;
  final double? price;
  final String? priceCurrency;
  final DateTime savedAt;
  final String? notes; // Notes personnelles de l'utilisateur

  const EventFavorite({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventType,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.startDate,
    this.endDate,
    this.locationName,
    this.city,
    this.country,
    this.imageUrl,
    this.websiteUrl,
    this.price,
    this.priceCurrency,
    required this.savedAt,
    this.notes,
  });

  /// Créer un favori depuis un Event
  factory EventFavorite.fromEvent(Event event, {String? notes}) {
    return EventFavorite(
      id: 'event_${event.id}_${DateTime.now().millisecondsSinceEpoch}',
      eventId: event.id,
      eventName: event.name,
      eventType: event.type,
      description: event.description,
      latitude: event.latitude,
      longitude: event.longitude,
      startDate: event.startDate,
      endDate: event.endDate,
      locationName: event.locationName,
      city: event.city,
      country: event.country,
      imageUrl: event.imageUrl,
      websiteUrl: event.websiteUrl,
      price: event.price,
      priceCurrency: event.priceCurrency,
      savedAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Convertir en Map pour Hive
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'eventType': eventType.name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'locationName': locationName,
      'city': city,
      'country': country,
      'imageUrl': imageUrl,
      'websiteUrl': websiteUrl,
      'price': price,
      'priceCurrency': priceCurrency,
      'savedAt': savedAt.toIso8601String(),
      'notes': notes,
      'type': 'event', // Pour différencier des favoris de destinations
    };
  }

  /// Créer depuis Map (Hive)
  factory EventFavorite.fromJson(Map<String, dynamic> json) {
    return EventFavorite(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => EventType.other,
      ),
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      locationName: json['locationName'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      imageUrl: json['imageUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Créer une copie avec modifications
  EventFavorite copyWith({
    String? id,
    String? eventId,
    String? eventName,
    EventType? eventType,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? startDate,
    DateTime? endDate,
    String? locationName,
    String? city,
    String? country,
    String? imageUrl,
    String? websiteUrl,
    double? price,
    String? priceCurrency,
    DateTime? savedAt,
    String? notes,
  }) {
    return EventFavorite(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      locationName: locationName ?? this.locationName,
      city: city ?? this.city,
      country: country ?? this.country,
      imageUrl: imageUrl ?? this.imageUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      price: price ?? this.price,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Convertir en Event pour réutilisation
  Event toEvent() {
    return Event(
      id: eventId,
      name: eventName,
      description: description,
      type: eventType,
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
      locationName: locationName,
      city: city,
      country: country,
      distanceFromCenter: 0, // Sera recalculé si nécessaire
      imageUrl: imageUrl,
      websiteUrl: websiteUrl,
      price: price,
      priceCurrency: priceCurrency,
    );
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

  /// Vérifie si l'événement est à venir
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  /// Vérifie si l'événement est en cours
  bool get isOngoing {
    final now = DateTime.now();
    if (endDate != null) {
      return now.isAfter(startDate) && now.isBefore(endDate!);
    }
    return now.isAfter(startDate) && now.isBefore(startDate.add(const Duration(days: 1)));
  }

  /// Vérifie si l'événement est passé
  bool get isPast {
    if (endDate != null) {
      return DateTime.now().isAfter(endDate!);
    }
    return DateTime.now().isAfter(startDate.add(const Duration(days: 1)));
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        eventName,
        eventType,
        description,
        latitude,
        longitude,
        startDate,
        endDate,
        locationName,
        city,
        country,
        imageUrl,
        websiteUrl,
        price,
        priceCurrency,
        savedAt,
        notes,
      ];
}
