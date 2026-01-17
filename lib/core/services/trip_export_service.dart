import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/favorite.dart';

/// Formats d'export disponibles
enum ExportFormat {
  ics,      // iCalendar
  json,     // JSON
  csv,      // CSV
  text,     // Texte lisible
}

/// Modèle pour un voyage planifié
class PlannedTrip {
  final String id;
  final String destination;
  final String? country;
  final DateTime startDate;
  final DateTime endDate;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final double? expectedTemperature;
  final int? expectedSunnyDays;

  const PlannedTrip({
    required this.id,
    required this.destination,
    this.country,
    required this.startDate,
    required this.endDate,
    this.latitude,
    this.longitude,
    this.notes,
    this.expectedTemperature,
    this.expectedSunnyDays,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'destination': destination,
    'country': country,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'expectedTemperature': expectedTemperature,
    'expectedSunnyDays': expectedSunnyDays,
  };

  factory PlannedTrip.fromJson(Map<String, dynamic> json) {
    return PlannedTrip(
      id: json['id'] as String,
      destination: json['destination'] as String,
      country: json['country'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      expectedTemperature: (json['expectedTemperature'] as num?)?.toDouble(),
      expectedSunnyDays: json['expectedSunnyDays'] as int?,
    );
  }

  factory PlannedTrip.fromFavorite(Favorite fav, DateTime start, DateTime end) {
    return PlannedTrip(
      id: '${fav.id}_${start.millisecondsSinceEpoch}',
      destination: fav.locationName,
      country: fav.country,
      startDate: start,
      endDate: end,
      latitude: fav.latitude,
      longitude: fav.longitude,
      notes: fav.notes,
      expectedTemperature: fav.averageTemperature,
      expectedSunnyDays: fav.sunnyDays,
    );
  }
}

/// Service d'export de voyages
class TripExportService {
  static final TripExportService _instance = TripExportService._internal();
  factory TripExportService() => _instance;
  TripExportService._internal();

  final AppLogger _logger = AppLogger();

  /// Exporter un voyage au format iCalendar (.ics)
  String exportToICS(PlannedTrip trip) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//IWantSun//Trip Export//FR');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${trip.id}@iwantsun.app');
    buffer.writeln('DTSTAMP:${_formatICSDate(DateTime.now())}');
    buffer.writeln('DTSTART;VALUE=DATE:${_formatICSDateOnly(trip.startDate)}');
    buffer.writeln('DTEND;VALUE=DATE:${_formatICSDateOnly(trip.endDate.add(const Duration(days: 1)))}');
    buffer.writeln('SUMMARY:Voyage à ${trip.destination}');

    final description = _buildDescription(trip);
    buffer.writeln('DESCRIPTION:${_escapeICS(description)}');

    if (trip.country != null) {
      buffer.writeln('LOCATION:${trip.destination}, ${trip.country}');
    } else {
      buffer.writeln('LOCATION:${trip.destination}');
    }

    if (trip.latitude != null && trip.longitude != null) {
      buffer.writeln('GEO:${trip.latitude};${trip.longitude}');
    }

    buffer.writeln('CATEGORIES:Voyage,IWantSun');
    buffer.writeln('STATUS:CONFIRMED');
    buffer.writeln('END:VEVENT');
    buffer.writeln('END:VCALENDAR');

    _logger.info('Exported trip to ICS: ${trip.destination}');
    return buffer.toString();
  }

  /// Exporter plusieurs voyages au format iCalendar
  String exportMultipleToICS(List<PlannedTrip> trips) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//IWantSun//Trip Export//FR');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:Mes voyages IWantSun');

    for (final trip in trips) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${trip.id}@iwantsun.app');
      buffer.writeln('DTSTAMP:${_formatICSDate(DateTime.now())}');
      buffer.writeln('DTSTART;VALUE=DATE:${_formatICSDateOnly(trip.startDate)}');
      buffer.writeln('DTEND;VALUE=DATE:${_formatICSDateOnly(trip.endDate.add(const Duration(days: 1)))}');
      buffer.writeln('SUMMARY:Voyage à ${trip.destination}');
      buffer.writeln('DESCRIPTION:${_escapeICS(_buildDescription(trip))}');
      buffer.writeln('LOCATION:${trip.destination}${trip.country != null ? ', ${trip.country}' : ''}');
      buffer.writeln('CATEGORIES:Voyage,IWantSun');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Exporter au format JSON
  String exportToJSON(List<PlannedTrip> trips) {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'source': 'IWantSun',
      'trips': trips.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exporter au format CSV
  String exportToCSV(List<PlannedTrip> trips) {
    final buffer = StringBuffer();

    // En-tête
    buffer.writeln('Destination,Pays,Date début,Date fin,Durée (jours),Température prévue,Jours ensoleillés,Notes');

    // Données
    for (final trip in trips) {
      buffer.writeln([
        _escapeCSV(trip.destination),
        _escapeCSV(trip.country ?? ''),
        _formatDate(trip.startDate),
        _formatDate(trip.endDate),
        trip.durationDays,
        trip.expectedTemperature?.toStringAsFixed(1) ?? '',
        trip.expectedSunnyDays ?? '',
        _escapeCSV(trip.notes ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Exporter au format texte lisible
  String exportToText(List<PlannedTrip> trips) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('   MES VOYAGES IWANTSUN');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();

    for (int i = 0; i < trips.length; i++) {
      final trip = trips[i];
      buffer.writeln('${i + 1}. ${trip.destination}');
      if (trip.country != null) buffer.writeln('   Pays: ${trip.country}');
      buffer.writeln('   Dates: ${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}');
      buffer.writeln('   Durée: ${trip.durationDays} jour(s)');
      if (trip.expectedTemperature != null) {
        buffer.writeln('   Température prévue: ${trip.expectedTemperature!.toStringAsFixed(1)}°C');
      }
      if (trip.expectedSunnyDays != null) {
        buffer.writeln('   Jours ensoleillés: ${trip.expectedSunnyDays}');
      }
      if (trip.notes != null && trip.notes!.isNotEmpty) {
        buffer.writeln('   Notes: ${trip.notes}');
      }
      buffer.writeln();
    }

    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('Exporté depuis IWantSun');
    buffer.writeln('Date: ${_formatDate(DateTime.now())}');

    return buffer.toString();
  }

  /// Partager un voyage
  Future<void> shareTrip(PlannedTrip trip, {ExportFormat format = ExportFormat.text}) async {
    String content;
    String subject;

    switch (format) {
      case ExportFormat.ics:
        content = exportToICS(trip);
        subject = 'Voyage à ${trip.destination}.ics';
        break;
      case ExportFormat.json:
        content = exportToJSON([trip]);
        subject = 'Voyage à ${trip.destination}.json';
        break;
      case ExportFormat.csv:
        content = exportToCSV([trip]);
        subject = 'Voyage à ${trip.destination}.csv';
        break;
      case ExportFormat.text:
        content = exportToText([trip]);
        subject = 'Mon voyage à ${trip.destination}';
        break;
    }

    await Share.share(content, subject: subject);
    _logger.info('Shared trip: ${trip.destination} as $format');
  }

  /// Partager plusieurs voyages
  Future<void> shareTrips(List<PlannedTrip> trips, {ExportFormat format = ExportFormat.text}) async {
    String content;
    String subject = 'Mes voyages IWantSun';

    switch (format) {
      case ExportFormat.ics:
        content = exportMultipleToICS(trips);
        subject = 'Mes voyages.ics';
        break;
      case ExportFormat.json:
        content = exportToJSON(trips);
        subject = 'Mes voyages.json';
        break;
      case ExportFormat.csv:
        content = exportToCSV(trips);
        subject = 'Mes voyages.csv';
        break;
      case ExportFormat.text:
        content = exportToText(trips);
        break;
    }

    await Share.share(content, subject: subject);
    _logger.info('Shared ${trips.length} trips as $format');
  }

  // Helpers
  String _formatICSDate(DateTime date) {
    return '${date.year}${_pad(date.month)}${_pad(date.day)}'
           'T${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}Z';
  }

  String _formatICSDateOnly(DateTime date) {
    return '${date.year}${_pad(date.month)}${_pad(date.day)}';
  }

  String _formatDate(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _escapeICS(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
  }

  String _escapeCSV(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  String _buildDescription(PlannedTrip trip) {
    final parts = <String>[];

    parts.add('Voyage planifié avec IWantSun');
    parts.add('');
    parts.add('Destination: ${trip.destination}');
    if (trip.country != null) parts.add('Pays: ${trip.country}');
    parts.add('Durée: ${trip.durationDays} jour(s)');

    if (trip.expectedTemperature != null) {
      parts.add('Température prévue: ${trip.expectedTemperature!.toStringAsFixed(1)}°C');
    }
    if (trip.expectedSunnyDays != null) {
      parts.add('Jours ensoleillés: ${trip.expectedSunnyDays}');
    }
    if (trip.notes != null && trip.notes!.isNotEmpty) {
      parts.add('');
      parts.add('Notes: ${trip.notes}');
    }

    return parts.join('\n');
  }
}
