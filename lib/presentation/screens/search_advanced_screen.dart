import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/utils/date_utils.dart' as date_utils;
import 'package:iwantsun/core/services/location_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/data/repositories/location_repository_impl.dart';
import 'package:iwantsun/data/datasources/remote/location_remote_datasource.dart';
import 'package:iwantsun/data/repositories/weather_repository_impl.dart';
import 'package:iwantsun/data/datasources/remote/weather_remote_datasource.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/error_message.dart';
import 'package:iwantsun/presentation/widgets/search_autocomplete.dart';

/// Écran de recherche avancée (avec activités)
class SearchAdvancedScreen extends StatefulWidget {
  const SearchAdvancedScreen({super.key});

  @override
  State<SearchAdvancedScreen> createState() => _SearchAdvancedScreenState();
}

class _SearchAdvancedScreenState extends State<SearchAdvancedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _locationFocusNode = FocusNode();

  DateTime? _startDate;
  DateTime? _endDate;
  double _minTemperature = 20.0;
  double _maxTemperature = 30.0;
  double _searchRadius = 100.0;
  List<String> _selectedConditions = ['clear', 'partly_cloudy'];
  List<ActivityType> _selectedActivities = [];
  
  bool _isSearchingLocation = false;
  double? _centerLatitude;
  double? _centerLongitude;
  String? _locationError;
  bool _isLocationFromIp = false;
  
  final List<Map<String, dynamic>> _availableConditions = [
    {'value': 'clear', 'label': 'Ensoleillé', 'icon': Icons.wb_sunny},
    {'value': 'partly_cloudy', 'label': 'Partiellement nuageux', 'icon': Icons.wb_cloudy},
    {'value': 'cloudy', 'label': 'Nuageux', 'icon': Icons.cloud},
    {'value': 'rain', 'label': 'Pluvieux', 'icon': Icons.grain},
  ];

  final Map<ActivityType, Map<String, dynamic>> _activities = {
    ActivityType.beach: {
      'icon': Icons.beach_access,
      'color': AppColors.orangeSun,
    },
    ActivityType.hiking: {
      'icon': Icons.hiking,
      'color': AppColors.successGreen,
    },
    ActivityType.skiing: {
      'icon': Icons.downhill_skiing,
      'color': AppColors.primaryOrange,
    },
    ActivityType.surfing: {
      'icon': Icons.surfing,
      'color': AppColors.rainyBlue,
    },
    ActivityType.cycling: {
      'icon': Icons.directions_bike,
      'color': AppColors.warningYellow,
    },
    ActivityType.golf: {
      'icon': Icons.golf_course,
      'color': AppColors.successGreen,
    },
    ActivityType.camping: {
      'icon': Icons.family_restroom,
      'color': Colors.brown,
    },
  };

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  /// Callback appelé quand l'utilisateur sélectionne une entrée d'historique
  void _onHistorySelected(SearchHistoryEntry entry) {
    setState(() {
      _locationController.text = entry.locationName ?? '';
      _centerLatitude = entry.params.centerLatitude;
      _centerLongitude = entry.params.centerLongitude;
      _minTemperature = entry.params.desiredMinTemperature ?? 20.0;
      _maxTemperature = entry.params.desiredMaxTemperature ?? 30.0;
      _searchRadius = entry.params.searchRadius;
      _selectedConditions = List.from(entry.params.desiredConditions);
      _isLocationFromIp = false;

      // Récupérer les dates si disponibles
      if (entry.params.startDate != null && entry.params.endDate != null) {
        _startDate = entry.params.startDate;
        _endDate = entry.params.endDate;
      }

      // Récupérer les activités si c'est une recherche avancée
      if (entry.params is AdvancedSearchParams) {
        final advParams = entry.params as AdvancedSearchParams;
        _selectedActivities = List.from(advParams.desiredActivities);
      }
    });

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

  void _toggleActivity(ActivityType activity) {
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
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
          _isLocationFromIp = locationResult.source == LocationSource.ip;
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
          _isLocationFromIp = locationResult.source == LocationSource.ip;
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

  /// Pré-remplit la température basée sur la météo du lieu et de la période
  Future<void> _prefillTemperature() async {
    if (_centerLatitude == null || _centerLongitude == null ||
        _startDate == null || _endDate == null) {
      return;
    }

    try {
      final weatherRepo = WeatherRepositoryImpl(
        remoteDataSource: WeatherRemoteDataSourceImpl(),
      );

      final forecast = await weatherRepo.getWeatherForecast(
        latitude: _centerLatitude!,
        longitude: _centerLongitude!,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted) return;

      final avgTemp = forecast.averageTemperature;

      setState(() {
        _minTemperature = (avgTemp - 10).clamp(0.0, 40.0);
        _maxTemperature = (avgTemp + 10).clamp(0.0, 40.0);
      });

      AppLogger().info('Température pré-remplie: min=${_minTemperature.toStringAsFixed(1)}, max=${_maxTemperature.toStringAsFixed(1)}');
    } catch (e) {
      AppLogger().warning('Impossible de pré-remplir la température', e);
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

      // Prendre la première localisation trouvée
      final location = locations.first;
      setState(() {
        _centerLatitude = location.latitude;
        _centerLongitude = location.longitude;
        _isSearchingLocation = false;
        _isLocationFromIp = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localisation trouvée: ${location.name}'),
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

    // Créer les paramètres de recherche avancée
    final searchParams = AdvancedSearchParams(
      centerLatitude: _centerLatitude!,
      centerLongitude: _centerLongitude!,
      searchRadius: _searchRadius,
      startDate: _startDate!,
      endDate: _endDate!,
      desiredMinTemperature: _minTemperature,
      desiredMaxTemperature: _maxTemperature,
      desiredConditions: _selectedConditions,
      desiredActivities: _selectedActivities,
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
            const Text('Recherche avec Activités'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/rando.png'),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Section Localisation
              _buildSection(
                title: 'Localisation',
                icon: Icons.location_on,
                child: Column(
                  children: [
                    SearchAutocomplete(
                      controller: _locationController,
                      focusNode: _locationFocusNode,
                      hintText: 'Rechercher une ville...',
                      onHistorySelected: _onHistorySelected,
                      onChanged: (_) {
                        // Réinitialiser les coordonnées si le texte change
                        if (_centerLatitude != null) {
                          setState(() {
                            _centerLatitude = null;
                            _centerLongitude = null;
                          });
                        }
                      },
                      isLoading: _isSearchingLocation,
                    ),
                    if (_locationError != null) ...[
                      const SizedBox(height: 8),
                      InlineError(message: _locationError!),
                    ],
                    if (_centerLatitude != null && _centerLongitude != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isLocationFromIp ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isLocationFromIp ? Colors.orange.shade300 : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _isLocationFromIp ? Colors.orange.shade700 : Colors.green.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _isLocationFromIp ? 'Position approximative' : 'Localisation trouvée',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            if (_isLocationFromIp)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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

              // Section Rayon de recherche
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
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Section Activités
              _buildSection(
                title: 'Activités extérieures',
                icon: Icons.sports_soccer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sélectionnez les activités qui vous intéressent',
                      style: TextStyle(color: AppColors.darkGray),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _activities.entries.map((entry) {
                        final activity = entry.key;
                        final data = entry.value;
                        final isSelected = _selectedActivities.contains(activity);
                        final activityEntity = Activity(type: activity, name: activity.name);
                        
                        return FilterChip(
                          selected: isSelected,
                          avatar: Icon(
                            data['icon'],
                            color: isSelected ? AppColors.white : data['color'],
                            size: 20,
                          ),
                          label: Text(activityEntity.displayName),
                          onSelected: (_) => _toggleActivity(activity),
                          selectedColor: data['color'] as Color,
                          checkmarkColor: AppColors.white,
                        );
                      }).toList(),
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
