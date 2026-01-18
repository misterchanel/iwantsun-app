import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/utils/date_utils.dart' as date_utils;
import 'package:iwantsun/core/services/location_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/data/repositories/location_repository_impl.dart';
import 'package:iwantsun/data/datasources/remote/location_remote_datasource.dart';
import 'package:iwantsun/data/repositories/weather_repository_impl.dart';
import 'package:iwantsun/data/datasources/remote/weather_remote_datasource.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/error_message.dart';
import 'package:iwantsun/presentation/widgets/location_picker_dialog.dart';
import 'package:iwantsun/presentation/widgets/search_autocomplete.dart';

/// Écran de recherche simple
class SearchSimpleScreen extends StatefulWidget {
  const SearchSimpleScreen({super.key});

  @override
  State<SearchSimpleScreen> createState() => _SearchSimpleScreenState();
}

class _SearchSimpleScreenState extends State<SearchSimpleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _locationFocusNode = FocusNode();

  DateTime? _startDate;
  DateTime? _endDate;
  double _minTemperature = 20.0;
  double _maxTemperature = 30.0;
  double _searchRadius = 100.0;
  List<String> _selectedConditions = ['clear', 'partly_cloudy'];
  List<TimeSlot> _selectedTimeSlots = List.from(defaultTimeSlots); // Matin, après-midi, soirée par défaut

  bool _isSearchingLocation = false;
  double? _centerLatitude;
  double? _centerLongitude;
  String? _locationError;

  final List<Map<String, dynamic>> _availableConditions = [
    {'value': 'clear', 'label': 'Ensoleillé', 'icon': Icons.wb_sunny},
    {'value': 'partly_cloudy', 'label': 'Partiellement nuageux', 'icon': Icons.wb_cloudy},
    {'value': 'cloudy', 'label': 'Nuageux', 'icon': Icons.cloud},
    {'value': 'rain', 'label': 'Pluvieux', 'icon': Icons.grain},
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  /// Callback quand une entrée historique est sélectionnée
  void _onHistorySelected(SearchHistoryEntry entry) {
    setState(() {
      _locationController.text = entry.locationName ?? '';
      _minTemperature = entry.params.desiredMinTemperature ?? 20.0;
      _maxTemperature = entry.params.desiredMaxTemperature ?? 30.0;
      _searchRadius = entry.params.searchRadius;
      _startDate = entry.params.startDate;
      _endDate = entry.params.endDate;
      _centerLatitude = entry.params.centerLatitude;
      _centerLongitude = entry.params.centerLongitude;
      if (entry.params.desiredConditions.isNotEmpty) {
        _selectedConditions = entry.params.desiredConditions;
      }
      if (entry.params.timeSlots.isNotEmpty) {
        _selectedTimeSlots = List.from(entry.params.timeSlots);
      }
    });
    // Unfocus pour fermer l'overlay
    _locationFocusNode.unfocus();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryOrange,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Pré-remplir la température si la localisation est déjà définie
      if (_centerLatitude != null && _centerLongitude != null) {
        _prefillTemperature();
      }
    }
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  void _toggleTimeSlot(TimeSlot slot) {
    setState(() {
      if (_selectedTimeSlots.contains(slot)) {
        // Empêcher de tout désélectionner
        if (_selectedTimeSlots.length > 1) {
          _selectedTimeSlots.remove(slot);
        }
      } else {
        _selectedTimeSlots.add(slot);
      }
    });
  }

  /// Utilise la position GPS de l'utilisateur
  Future<void> _useMyLocation() async {
    setState(() {
      _isSearchingLocation = true;
      _locationError = null;
    });

    try {
      final locationService = LocationService();
      final locationResult = await locationService.getLocationWithFallback();

      if (!mounted) return;

      if (locationResult == null) {
        setState(() {
          _locationError = 'Impossible d\'obtenir votre position. Vérifiez les permissions et votre connexion Internet.';
          _isSearchingLocation = false;
        });
        return;
      }

      // Afficher un message si position via IP (approximative)
      if (locationResult.source == LocationSource.ip && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Position approximative (via IP): ${locationResult.displayName ?? "Inconnue"}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Utiliser le repository pour géocoder la position
      final locationRepo = LocationRepositoryImpl(
        remoteDataSource: LocationRemoteDataSourceImpl(),
      );

      final location = await locationRepo.geocodeLocation(
        locationResult.latitude,
        locationResult.longitude,
      );

      if (!mounted) return;

      if (location != null) {
        setState(() {
          _centerLatitude = location.latitude;
          _centerLongitude = location.longitude;
          _locationController.text = location.name;
          _isSearchingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Position trouvée: ${location.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Pré-remplir la température si les dates sont déjà définies
        if (_startDate != null && _endDate != null) {
          _prefillTemperature();
        }
      } else {
        setState(() {
          _centerLatitude = locationResult.latitude;
          _centerLongitude = locationResult.longitude;
          _locationController.text = '${locationResult.latitude.toStringAsFixed(4)}, ${locationResult.longitude.toStringAsFixed(4)}';
          _isSearchingLocation = false;
        });

        // Pré-remplir la température si les dates sont déjà définies
        if (_startDate != null && _endDate != null) {
          _prefillTemperature();
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationError = 'Erreur lors de la récupération de la position: ${e.toString()}';
        _isSearchingLocation = false;
      });
    }
  }

  /// Recherche les coordonnées d'une localisation
  Future<void> _searchLocation() async {
    final locationText = _locationController.text.trim();
    if (locationText.isEmpty) return;

    setState(() {
      _isSearchingLocation = true;
      _locationError = null;
    });

    try {
      final locationRepo = LocationRepositoryImpl(
        remoteDataSource: LocationRemoteDataSourceImpl(),
      );

      final locations = await locationRepo.searchLocations(locationText);

      if (!mounted) return;

      if (locations.isEmpty) {
        setState(() {
          _locationError = 'Aucun résultat trouvé pour "$locationText"';
          _isSearchingLocation = false;
        });
        return;
      }

      setState(() {
        _isSearchingLocation = false;
      });

      // Si plusieurs résultats, demander à l'utilisateur de choisir
      Location selectedLocation;
      if (locations.length > 1) {
        final location = await LocationPickerDialog.show(
          context,
          locations: locations,
          searchQuery: locationText,
        );

        // Si l'utilisateur annule, ne rien faire
        if (location == null) return;
        selectedLocation = location;
      } else {
        // Un seul résultat, le sélectionner automatiquement
        selectedLocation = locations.first;
      }

      setState(() {
        _centerLatitude = selectedLocation.latitude;
        _centerLongitude = selectedLocation.longitude;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localisation trouvée: ${selectedLocation.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Pré-remplir la température si les dates sont déjà définies
      if (_startDate != null && _endDate != null) {
        _prefillTemperature();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationError = 'Erreur lors de la recherche: ${e.toString()}';
        _isSearchingLocation = false;
      });
    }
  }

  /// Pré-remplit la température basée sur la météo des villes dans le rayon et la période
  Future<void> _prefillTemperature() async {
    // Vérifier que toutes les données nécessaires sont disponibles
    if (_centerLatitude == null || _centerLongitude == null ||
        _startDate == null || _endDate == null) {
      return;
    }

    try {
      final locationRepo = LocationRepositoryImpl(
        remoteDataSource: LocationRemoteDataSourceImpl(),
      );
      final weatherRepo = WeatherRepositoryImpl(
        remoteDataSource: WeatherRemoteDataSourceImpl(),
      );

      // Récupérer les villes dans le rayon de recherche
      List<Location> locationsToCheck = [];
      try {
        final nearbyCities = await locationRepo.getNearbyCities(
          latitude: _centerLatitude!,
          longitude: _centerLongitude!,
          radiusKm: _searchRadius,
        );
        // Limiter à 10 villes pour les performances
        locationsToCheck = nearbyCities.take(10).toList();
      } catch (e) {
        // Si échec, utiliser uniquement le point central
        AppLogger().warning('Impossible de récupérer les villes proches, utilisation du point central', e);
      }

      // Si aucune ville trouvée, utiliser le point central
      if (locationsToCheck.isEmpty) {
        locationsToCheck = [
          Location(
            id: 'center',
            name: 'Centre',
            latitude: _centerLatitude!,
            longitude: _centerLongitude!,
          ),
        ];
      }

      // Récupérer les prévisions météo pour chaque ville
      double globalMinTemp = double.infinity;
      double globalMaxTemp = double.negativeInfinity;
      int successCount = 0;

      for (final location in locationsToCheck) {
        try {
          final forecast = await weatherRepo.getWeatherForecast(
            latitude: location.latitude,
            longitude: location.longitude,
            startDate: _startDate!,
            endDate: _endDate!,
          );

          // Récupérer les min/max de toutes les prévisions
          for (final weather in forecast.forecasts) {
            if (weather.minTemperature < globalMinTemp) {
              globalMinTemp = weather.minTemperature;
            }
            if (weather.maxTemperature > globalMaxTemp) {
              globalMaxTemp = weather.maxTemperature;
            }
          }
          successCount++;
        } catch (e) {
          // Ignorer les erreurs pour une ville individuelle
          continue;
        }
      }

      if (!mounted) return;

      // Si on a réussi à obtenir au moins une prévision
      if (successCount > 0 && globalMinTemp != double.infinity && globalMaxTemp != double.negativeInfinity) {
        // Arrondir et ajouter une marge de 2 degrés
        setState(() {
          _minTemperature = (globalMinTemp - 2).clamp(0.0, 40.0);
          _maxTemperature = (globalMaxTemp + 2).clamp(0.0, 40.0);
        });

        AppLogger().info('Température pré-remplie (${successCount} villes): min=${_minTemperature.toStringAsFixed(1)}, max=${_maxTemperature.toStringAsFixed(1)}');
      }
    } catch (e) {
      // En cas d'erreur, ne rien faire (garder les valeurs par défaut)
      AppLogger().warning('Impossible de pré-remplir la température', e);
    }
  }

  /// Valide le formulaire et lance la recherche
  Future<void> _search() async {
    // Validation de base
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation des dates
    if (_startDate == null || _endDate == null) {
      ErrorSnackBar.show(
        context,
        'Veuillez sélectionner une période de voyage',
      );
      return;
    }

    // Validation de la température
    if (_minTemperature >= _maxTemperature) {
      ErrorSnackBar.show(
        context,
        'La température minimale doit être inférieure à la température maximale',
      );
      return;
    }

    // Validation des conditions météo
    if (_selectedConditions.isEmpty) {
      ErrorSnackBar.show(
        context,
        'Veuillez sélectionner au moins une condition météo',
      );
      return;
    }

    // Rechercher la localisation si pas encore fait
    if (_centerLatitude == null || _centerLongitude == null) {
      await _searchLocation();

      if (_centerLatitude == null || _centerLongitude == null) {
        ErrorSnackBar.show(
          context,
          'Impossible de trouver la localisation. Vérifiez votre saisie.',
        );
        return;
      }
    }

    // Créer les paramètres de recherche
    final searchParams = SearchParams(
      centerLatitude: _centerLatitude!,
      centerLongitude: _centerLongitude!,
      searchRadius: _searchRadius,
      startDate: _startDate!,
      endDate: _endDate!,
      desiredMinTemperature: _minTemperature,
      desiredMaxTemperature: _maxTemperature,
      desiredConditions: _selectedConditions,
      timeSlots: _selectedTimeSlots,
    );

    // Lancer la recherche via le provider
    final searchProvider = context.read<SearchProvider>();
    await searchProvider.search(searchParams);

    if (!mounted) return;

    // Naviguer vers les résultats
    context.push('/search/results');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  size: 24,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Recherche Simple'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/terrasse.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cream.withOpacity(0.85),
                AppColors.cream.withOpacity(0.90),
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20.0,
                20.0,
                20.0,
                20.0 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Section Localisation (Centre de la zone de recherche)
              _buildSection(
                title: 'Centre de la zone de recherche',
                icon: Icons.location_on,
                child: Column(
                  children: [
                    // Champ avec autocomplétion historique
                    SearchAutocomplete(
                      controller: _locationController,
                      focusNode: _locationFocusNode,
                      hintText: 'Ex: Paris, France',
                      onHistorySelected: _onHistorySelected,
                      onFieldSubmitted: _searchLocation,
                      isLoading: _isSearchingLocation,
                    ),
                    if (_locationError != null) ...[
                      const SizedBox(height: 8),
                      InlineError(message: _locationError!),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _useMyLocation,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('Utiliser ma position'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: BorderSide(color: AppColors.mediumGray, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Section Rayon de recherche (déplacé ici, juste après localisation)
              _buildSection(
                title: 'Rayon de recherche',
                icon: Icons.radio_button_checked,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '${_searchRadius.toInt()} km',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryOrange.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Slider(
                      value: _searchRadius,
                      min: 0,
                      max: 200,
                      divisions: 40,
                      activeColor: AppColors.primaryOrange,
                      inactiveColor: AppColors.mediumGray.withOpacity(0.3),
                      label: '${_searchRadius.toInt()} km',
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = value;
                        });
                      },
                      onChangeEnd: (value) {
                        // Recalculer les températures si localisation et dates sont définies
                        if (_centerLatitude != null && _centerLongitude != null &&
                            _startDate != null && _endDate != null) {
                          _prefillTemperature();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Section Période
              _buildSection(
                title: 'Période',
                icon: Icons.calendar_today,
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.lightBeige,
                      border: Border.all(
                        color: _startDate != null && _endDate != null
                            ? AppColors.primaryOrange
                            : AppColors.mediumGray.withOpacity(0.3),
                        width: _startDate != null && _endDate != null ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _startDate != null && _endDate != null
                                ? AppColors.primaryOrange.withOpacity(0.1)
                                : AppColors.mediumGray.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.date_range,
                            color: _startDate != null && _endDate != null
                                ? AppColors.primaryOrange
                                : AppColors.mediumGray,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _startDate != null && _endDate != null
                                ? date_utils.DateUtils.formatDateRange(_startDate!, _endDate!)
                                : 'Sélectionner une période',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _startDate != null && _endDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _startDate != null && _endDate != null
                                  ? AppColors.textDark
                                  : AppColors.mediumGray,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: _startDate != null && _endDate != null
                              ? AppColors.primaryOrange
                              : AppColors.mediumGray,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Section Température
              _buildSection(
                title: 'Température souhaitée',
                icon: Icons.thermostat,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warmPeach.withOpacity(0.3),
                            AppColors.goldenYellow.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Minimum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkGray.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_minTemperature.toInt()}°C',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.swap_horiz,
                            color: AppColors.primaryOrange.withOpacity(0.5),
                            size: 32,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Maximum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkGray.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_maxTemperature.toInt()}°C',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RangeSlider(
                      values: RangeValues(_minTemperature, _maxTemperature),
                      min: -10,
                      max: 45,
                      divisions: 55,
                      activeColor: AppColors.primaryOrange,
                      inactiveColor: AppColors.mediumGray.withOpacity(0.3),
                      labels: RangeLabels(
                        '${_minTemperature.toInt()}°C',
                        '${_maxTemperature.toInt()}°C',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _minTemperature = values.start;
                          _maxTemperature = values.end;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Section Conditions météo
              _buildSection(
                title: 'Conditions météo',
                icon: Icons.wb_cloudy,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableConditions.map((condition) {
                    final isSelected = _selectedConditions.contains(condition['value']);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(condition['icon'], size: 18),
                          const SizedBox(width: 4),
                          Text(condition['label']),
                        ],
                      ),
                      onSelected: (_) => _toggleCondition(condition['value']),
                      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                      checkmarkColor: AppColors.primaryOrange,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Section Créneaux horaires
              _buildSection(
                title: 'Créneaux horaires',
                icon: Icons.schedule,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heures à considérer pour l\'analyse météo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGray.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TimeSlot.values.map((slot) {
                        final isSelected = _selectedTimeSlots.contains(slot);
                        return FilterChip(
                          selected: isSelected,
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slot.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                slot.timeRange,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.darkGray.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          onSelected: (_) => _toggleTimeSlot(slot),
                          selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                    if (_selectedTimeSlots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Sélectionnez au moins un créneau',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton de recherche
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: Consumer<SearchProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        label: 'Rechercher des destinations',
                        icon: Icons.search,
                        onPressed: _search,
                        isLoading: provider.isLoading,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
