import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/utils/date_utils.dart' as date_utils;
import 'package:iwantsun/core/services/location_service.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/services/logger_service.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/domain/entities/event.dart';
import 'package:iwantsun/domain/entities/location.dart';
import 'package:iwantsun/data/repositories/location_repository_impl.dart';
import 'package:iwantsun/data/datasources/remote/location_remote_datasource.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/error_message.dart';
import 'package:iwantsun/presentation/widgets/location_picker_dialog.dart';
import 'package:iwantsun/presentation/widgets/search_autocomplete.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/error_message.dart';
import 'package:iwantsun/core/services/firebase_api_service.dart';

/// Écran de recherche d'événements
class SearchEventScreen extends StatefulWidget {
  final EventSearchParams? prefillParams;
  
  const SearchEventScreen({super.key, this.prefillParams});

  @override
  State<SearchEventScreen> createState() => _SearchEventScreenState();
}

class _SearchEventScreenState extends State<SearchEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _locationFocusNode = FocusNode();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  double _searchRadius = 100.0;
  List<EventType> _selectedEventTypes = [];
  double? _minPrice;
  double? _maxPrice;
  bool _sortByPopularity = false;

  bool _isSearchingLocation = false;
  double? _centerLatitude;
  double? _centerLongitude;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.prefillParams != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillFromParams(widget.prefillParams!);
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _prefillFromParams(EventSearchParams params) {
    setState(() {
      _searchRadius = params.searchRadius;
      _startDate = params.startDate;
      _endDate = params.endDate;
      _centerLatitude = params.centerLatitude;
      _centerLongitude = params.centerLongitude;
      _selectedEventTypes = List.from(params.eventTypes);
      _minPrice = params.minPrice;
      _maxPrice = params.maxPrice;
      _sortByPopularity = params.sortByPopularity ?? false;
      _minPriceController.text = _minPrice?.toStringAsFixed(0) ?? '';
      _maxPriceController.text = _maxPrice?.toStringAsFixed(0) ?? '';
      if (_centerLatitude != null && _centerLongitude != null) {
        _reverseGeocode();
      }
    });
  }

  Future<void> _reverseGeocode() async {
    if (_centerLatitude == null || _centerLongitude == null) return;
    try {
      final locationRepo = LocationRepositoryImpl(
        remoteDataSource: LocationRemoteDataSourceImpl(),
      );
      final location = await locationRepo.geocodeLocation(
        _centerLatitude!,
        _centerLongitude!,
      );
      if (location != null && mounted) {
        setState(() {
          _locationController.text = location.name;
        });
      }
    } catch (e) {
      AppLogger().warning('Reverse geocoding failed: $e');
    }
  }

  void _onHistorySelected(SearchHistoryEntry entry) {
    if (entry.params is EventSearchParams) {
      _prefillFromParams(entry.params as EventSearchParams);
    }
  }

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
      } else {
        setState(() {
          _locationError = 'Impossible de géocoder votre position';
          _isSearchingLocation = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Erreur: ${e.toString()}';
        _isSearchingLocation = false;
      });
    }
  }

  Future<void> _searchLocation() async {
    final locationText = _locationController.text.trim();
    if (locationText.isEmpty) {
      setState(() {
        _locationError = 'Veuillez saisir une localisation';
      });
      return;
    }

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
          _locationError = 'Aucune localisation trouvée';
          _isSearchingLocation = false;
        });
        return;
      }

      Location? selectedLocation;

      if (locations.length > 1) {
        selectedLocation = await showDialog<Location>(
          context: context,
          builder: (context) => LocationPickerDialog(
            locations: locations,
            searchQuery: locationText,
          ),
        );
        if (selectedLocation == null) {
          setState(() {
            _isSearchingLocation = false;
          });
          return;
        }
      } else {
        selectedLocation = locations.first;
      }

      setState(() {
        _centerLatitude = selectedLocation?.latitude;
        _centerLongitude = selectedLocation?.longitude;
        _isSearchingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Localisation trouvée: ${selectedLocation.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Erreur lors de la recherche: ${e.toString()}';
        _isSearchingLocation = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textDark,
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
    }
  }

  void _toggleEventType(EventType type) {
    setState(() {
      if (_selectedEventTypes.contains(type)) {
        if (_selectedEventTypes.length > 1) {
          _selectedEventTypes.remove(type);
        }
      } else {
        _selectedEventTypes.add(type);
      }
    });
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ErrorSnackBar.show(context, 'Veuillez sélectionner une période');
      return;
    }

    if (_selectedEventTypes.isEmpty) {
      ErrorSnackBar.show(context, 'Veuillez sélectionner au moins un type d\'événement');
      return;
    }

    if (_searchRadius <= 0) {
      ErrorSnackBar.show(context, 'Le rayon de recherche doit être supérieur à 0 km');
      return;
    }

    if (_centerLatitude == null || _centerLongitude == null) {
      await _searchLocation();
      if (_centerLatitude == null || _centerLongitude == null) {
        ErrorSnackBar.show(context, 'Impossible de trouver la localisation');
        return;
      }
    }

    final searchParams = EventSearchParams(
      centerLatitude: _centerLatitude!,
      centerLongitude: _centerLongitude!,
      searchRadius: _searchRadius,
      startDate: _startDate!,
      endDate: _endDate!,
      eventTypes: _selectedEventTypes,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sortByPopularity: _sortByPopularity,
    );

    // Note: Les recherches d'événements ne sont pas sauvegardées dans l'historique
    // car EventSearchParams n'hérite pas de SearchParams

    // Rechercher les événements
    try {
      final firebaseApi = FirebaseApiService();
      final events = await firebaseApi.searchEvents(searchParams);

      if (!mounted) return;

      // Naviguer vers les résultats
      context.push('/search/event-results', extra: {'params': searchParams, 'events': events});
    } catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, 'Erreur lors de la recherche: ${e.toString()}');
    }
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
            const Text('Recherche d\'Événements'),
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
                  // Section Localisation
                  _buildSection(
                    title: 'Centre de la zone de recherche',
                    icon: Icons.location_on,
                    child: Column(
                      children: [
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

                  // Section Types d'événements
                  _buildSection(
                    title: 'Types d\'événements',
                    icon: Icons.event,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sélectionnez un ou plusieurs types d\'événements',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGray.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: EventType.values
                              .where((type) => type != EventType.other)
                              .map((type) => _buildEventTypeChip(type))
                              .toList(),
                        ),
                        if (_selectedEventTypes.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Veuillez sélectionner au moins un type d\'événement',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.errorRed,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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
                            ),
                          ),
                        ),
                        Slider(
                          value: _searchRadius,
                          min: 1,
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

                  // Section Filtres avancés
                  _buildSection(
                    title: 'Filtres avancés',
                    icon: Icons.tune,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtre par prix
                        Text(
                          'Prix (optionnel)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGray.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                decoration: InputDecoration(
                                  labelText: 'Prix min (€)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.euro),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _minPrice = value.isEmpty ? null : double.tryParse(value);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                decoration: InputDecoration(
                                  labelText: 'Prix max (€)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.euro),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _maxPrice = value.isEmpty ? null : double.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Tri par popularité
                        Row(
                          children: [
                            Checkbox(
                              value: _sortByPopularity,
                              onChanged: (value) {
                                setState(() {
                                  _sortByPopularity = value ?? false;
                                });
                              },
                              activeColor: AppColors.primaryOrange,
                            ),
                            Expanded(
                              child: Text(
                                'Trier par popularité (événements payants en premier)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton de recherche
                  SizedBox(
                    width: double.infinity,
                    child: LoadingButton(
                      label: 'Rechercher des événements',
                      icon: Icons.search,
                      onPressed: _search,
                      isLoading: false,
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

  Widget _buildEventTypeChip(EventType type) {
    final isSelected = _selectedEventTypes.contains(type);
    
    return FilterChip(
      selected: isSelected,
      label: Text(type.displayName),
      avatar: Icon(type.icon, size: 18),
      onSelected: (_) => _toggleEventType(type),
      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
      checkmarkColor: AppColors.primaryOrange,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryOrange : AppColors.darkGray,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
