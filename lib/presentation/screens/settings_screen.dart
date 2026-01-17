import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iwantsun/core/services/user_preferences_service.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/presentation/providers/theme_provider.dart';
import 'package:iwantsun/core/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserPreferencesService _prefsService = UserPreferencesService();
  final CacheService _cacheService = CacheService();

  UserPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final prefs = await _prefsService.loadPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(UserPreferences Function(UserPreferences) updater) async {
    await _prefsService.updatePreferences(updater);
    await _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray.withOpacity(0.3),
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  title: 'Recherche par défaut',
                  icon: Icons.search,
                  children: [
                    // _buildTemperatureSettings(), // Supprimé selon demande utilisateur
                    // const SizedBox(height: 12),
                    _buildRadiusSettings(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Apparence',
                  icon: Icons.palette,
                  children: [
                    _buildThemeSelector(),
                    _buildDivider(),
                    _buildLanguageSelector(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Affichage',
                  icon: Icons.display_settings,
                  children: [
                    _buildTemperatureUnitSwitch(),
                    _buildDivider(),
                    _buildTextScaleSlider(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Accessibilité',
                  icon: Icons.accessibility,
                  children: [
                    _buildHighContrastSwitch(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Cache et données',
                  icon: Icons.storage,
                  children: [
                    _buildCacheStats(),
                    const SizedBox(height: 12),
                    _buildClearCacheButton(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'À propos',
                  icon: Icons.info_outline,
                  children: [
                    _buildAboutInfo(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildResetButton(),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
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
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.lightGray.withOpacity(0.5));
  }

  Widget _buildTemperatureSettings() {
    final minTemp = _preferences?.defaultMinTemperature ?? 20.0;
    final maxTemp = _preferences?.defaultMaxTemperature ?? 30.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Températures par défaut',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min: ${minTemp.toInt()}°C',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGray.withOpacity(0.7),
                      ),
                    ),
                    Slider(
                      value: minTemp,
                      min: 0,
                      max: 40,
                      divisions: 40,
                      activeColor: AppColors.primaryOrange,
                      onChanged: (value) {
                        _updatePreference((prefs) => prefs.copyWith(
                              defaultMinTemperature: () => value,
                            ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max: ${maxTemp.toInt()}°C',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGray.withOpacity(0.7),
                      ),
                    ),
                    Slider(
                      value: maxTemp,
                      min: 0,
                      max: 40,
                      divisions: 40,
                      activeColor: AppColors.primaryOrange,
                      onChanged: (value) {
                        _updatePreference((prefs) => prefs.copyWith(
                              defaultMaxTemperature: () => value,
                            ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSettings() {
    final radius = _preferences?.defaultSearchRadius ?? 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rayon de recherche',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${radius.toInt()} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          Slider(
            value: radius,
            min: 25,
            max: 300,
            divisions: 11,
            activeColor: AppColors.primaryOrange,
            onChanged: (value) {
              _updatePreference((prefs) => prefs.copyWith(
                    defaultSearchRadius: () => value,
                  ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureUnitSwitch() {
    final isCelsius =
        _preferences?.temperatureUnit == TemperatureUnit.celsius;

    return SwitchListTile(
      title: const Text(
        'Unité de température',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.darkGray.withOpacity(0.7),
        ),
      ),
      value: isCelsius,
      activeColor: AppColors.primaryOrange,
      onChanged: (value) {
        _updatePreference((prefs) => prefs.copyWith(
              temperatureUnit: value
                  ? TemperatureUnit.celsius
                  : TemperatureUnit.fahrenheit,
            ));
      },
    );
  }

  Widget _buildTextScaleSlider() {
    final scale = _preferences?.textScaleFactor ?? 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Taille du texte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${(scale * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          Slider(
            value: scale,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            activeColor: AppColors.primaryOrange,
            onChanged: (value) {
              _updatePreference((prefs) => prefs.copyWith(
                    textScaleFactor: value,
                  ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHighContrastSwitch() {
    final isEnabled = _preferences?.highContrastMode ?? false;

    return SwitchListTile(
      title: const Text(
        'Contraste élevé',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        'Améliore la lisibilité',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.darkGray.withOpacity(0.7),
        ),
      ),
      value: isEnabled,
      activeColor: AppColors.primaryOrange,
      onChanged: (value) {
        _updatePreference((prefs) => prefs.copyWith(
              highContrastMode: value,
            ));
      },
    );
  }

  Widget _buildCacheStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.value(_cacheService.getStatistics()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data!;
        final hitRate = stats['hitRate'] as double;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques du cache',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGray.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taux de succès',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGray.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${hitRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClearCacheButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vider le cache'),
              content:
                  const Text('Êtes-vous sûr de vouloir vider tout le cache ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Vider',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _cacheService.clearAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache vidé avec succès')),
              );
            }
            setState(() {}); // Refresh stats
          }
        },
        icon: const Icon(Icons.delete_outline),
        label: const Text('Vider le cache'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAboutInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IWantSun',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkGray.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trouvez les meilleures destinations ensoleillées',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thème',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildThemeOption(
                    context: context,
                    icon: Icons.brightness_auto,
                    label: 'Auto',
                    isSelected: themeProvider.themeMode == AppThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.system),
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context: context,
                    icon: Icons.light_mode,
                    label: 'Clair',
                    isSelected: themeProvider.themeMode == AppThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.light),
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context: context,
                    icon: Icons.dark_mode,
                    label: 'Sombre',
                    isSelected: themeProvider.themeMode == AppThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryOrange.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryOrange : AppColors.darkGray,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primaryOrange : AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentLanguage = localeProvider.language;

        return ListTile(
          title: const Text(
            'Langue',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            currentLanguage.name,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkGray.withOpacity(0.7),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.darkGray),
          onTap: () => _showLanguageDialog(context, localeProvider),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    final currentLanguage = localeProvider.language;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choisir la langue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...AppLanguage.values.map((lang) => ListTile(
              leading: Text(
                lang.flag,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(lang.name),
              trailing: currentLanguage == lang
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                localeProvider.setLanguage(lang);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Réinitialiser'),
              content: const Text(
                'Réinitialiser tous les paramètres aux valeurs par défaut ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Réinitialiser',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _prefsService.resetToDefaults();
            await _loadPreferences();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paramètres réinitialisés'),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.restore),
        label: const Text('Réinitialiser aux valeurs par défaut'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGray,
          side: BorderSide(color: AppColors.lightGray),
        ),
      ),
    );
  }
}
