import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/preferences_service.dart';
import 'package:iwantsun/core/services/location_service.dart';

/// Écran d'onboarding interactif multi-étapes
/// Présente l'application aux nouveaux utilisateurs
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PreferencesService _prefsService = PreferencesService();
  final LocationService _locationService = LocationService();

  int _currentPage = 0;
  bool _isInitialized = false;

  // Préférences temporaires (avant sauvegarde)
  String _temperatureUnit = 'celsius';
  String _distanceUnit = 'km';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _prefsService.init();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Sauvegarder les préférences
    await _prefsService.setTemperatureUnit(_temperatureUnit);
    await _prefsService.setDistanceUnit(_distanceUnit);
    await _prefsService.setOnboardingCompleted(true);

    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _skipOnboarding() async {
    await _prefsService.setOnboardingCompleted(true);
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      await _locationService.getCurrentPosition();
      await _prefsService.setLocationPermissionAsked(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission de localisation accordée'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'accéder à la localisation: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Page view avec les 4 étapes
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildWelcomePage(),
              _buildModesExplanationPage(),
              _buildPermissionsPage(),
              _buildPreferencesPage(),
            ],
          ),

          // Indicateurs de page
          Builder(
            builder: (context) {
              final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
              return Positioned(
                bottom: 100 + bottomPadding,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              );
            },
          ),

          // Boutons de navigation
          Builder(
            builder: (context) {
              final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
              return Positioned(
                bottom: 20 + bottomPadding,
                left: 20,
                right: 20,
                child: _buildNavigationButtons(),
              );
            },
          ),

          // Bouton Skip
          if (_currentPage < 3)
            Builder(
              builder: (context) {
                final topPadding = MediaQuery.of(context).viewPadding.top;
                return Positioned(
                  top: 16 + topPadding,
                  right: 20,
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryOrange
            : AppColors.mediumGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Bouton Retour
        if (_currentPage > 0)
          OutlinedButton(
            onPressed: _previousPage,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: AppColors.primaryOrange),
            ),
            child: const Text('Retour'),
          )
        else
          const SizedBox(width: 100),

        // Bouton Suivant/Terminer
        ElevatedButton(
          onPressed: _currentPage == 3 ? _completeOnboarding : _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(
            _currentPage == 3 ? 'Commencer' : 'Suivant',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== PAGE 1: BIENVENUE ====================

  Widget _buildWelcomePage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/vache.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wb_sunny,
                  size: 100,
                  color: AppColors.goldenYellow,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Bienvenue sur I Want Sun',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trouvez votre destination idéale selon la météo que vous recherchez',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildFeatureItem(
                  Icons.search,
                  'Recherche intelligente',
                  'Trouvez des destinations selon vos critères météo',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.hotel,
                  'Hébergements inclus',
                  'Découvrez les meilleurs hôtels à chaque destination',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.hiking,
                  'Activités outdoor',
                  'Explorez les activités disponibles sur place',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== PAGE 2: EXPLICATION DES MODES ====================

  Widget _buildModesExplanationPage() {
    return Container(
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
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Deux modes de recherche',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Mode Destination
                _buildModeCard(
                  icon: Icons.search,
                  title: 'Recherche de Destination',
                  description: 'Trouvez rapidement votre destination idéale en quelques clics',
                  features: [
                    'Sélection de la météo souhaitée',
                    'Choix de la température',
                    'Rayon de recherche personnalisable',
                    'Dates de voyage flexibles',
                  ],
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
                  ),
                ),

                const SizedBox(height: 24),

                // Mode Activité
                _buildModeCard(
                  icon: Icons.tune,
                  title: 'Recherche d\'Activité',
                  description: 'Trouvez des destinations ensoleillées pour vos activités (même fonctionnalités que la recherche de destination)',
                  features: [
                    'Sélection de la météo souhaitée',
                    'Choix de la température',
                    'Rayon de recherche personnalisable',
                    'Dates de voyage flexibles',
                  ],
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryCoral, AppColors.warmPeach],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ==================== PAGE 3: PERMISSIONS ====================

  Widget _buildPermissionsPage() {
    return Container(
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
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 80,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pour vous proposer des destinations proches, nous avons besoin d\'accéder à votre position',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                _buildPermissionItem(
                  Icons.explore,
                  'Recherche autour de vous',
                  'Trouvez des destinations près de votre position actuelle',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.map,
                  'Calcul des distances',
                  'Affichez la distance exacte jusqu\'à chaque destination',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.my_location,
                  'Météo locale',
                  'Comparez la météo de votre région avec vos destinations',
                ),

                const SizedBox(height: 48),

                ElevatedButton.icon(
                  onPressed: _requestLocationPermission,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Activer la localisation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _nextPage,
                  child: const Text(
                    'Plus tard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldenYellow, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PAGE 4: PRÉFÉRENCES ====================

  Widget _buildPreferencesPage() {
    return Container(
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
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Icon(
                    Icons.settings,
                    size: 64,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Personnalisez votre expérience',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),

                // Unité de température
                const Text(
                  'Unité de température',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildUnitSelector(
                  value: _temperatureUnit,
                  options: const [
                    {'value': 'celsius', 'label': 'Celsius (°C)'},
                    {'value': 'fahrenheit', 'label': 'Fahrenheit (°F)'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      _temperatureUnit = value;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Unité de distance
                const Text(
                  'Unité de distance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildUnitSelector(
                  value: _distanceUnit,
                  options: const [
                    {'value': 'km', 'label': 'Kilomètres (km)'},
                    {'value': 'miles', 'label': 'Miles (mi)'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      _distanceUnit = value;
                    });
                  },
                ),

                const SizedBox(height: 48),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.goldenYellow,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous pourrez modifier ces paramètres à tout moment dans les réglages de l\'application',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector({
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      children: options.map((option) {
        final optionValue = option['value']!;
        final isSelected = value == optionValue;

        return GestureDetector(
          onTap: () => onChanged(optionValue),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryOrange
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryOrange
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option['label']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
