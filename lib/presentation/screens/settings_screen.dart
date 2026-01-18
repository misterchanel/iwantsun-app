import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iwantsun/core/services/user_preferences_service.dart';
import 'package:iwantsun/core/services/cache_service.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
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

  // État local pour les sliders (feedback immédiat)
  double _localTextScale = 1.0;

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
      // Initialiser l'état local depuis les préférences
      _localTextScale = prefs.textScaleFactor;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(UserPreferences Function(UserPreferences) updater) async {
    if (_preferences == null) return;
    final newPrefs = updater(_preferences!);
    setState(() {
      _preferences = newPrefs;
    });
    await _prefsService.savePreferences(newPrefs);
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
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              children: [
                _buildSection(
                  title: 'Apparence',
                  icon: Icons.palette,
                  children: [
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
                '${(_localTextScale * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          Slider(
            value: _localTextScale,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            activeColor: AppColors.primaryOrange,
            onChanged: (value) {
              setState(() {
                _localTextScale = value;
              });
            },
            onChangeEnd: (value) {
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
            // Réinitialiser l'état local
            setState(() {
              _localTextScale = 1.0;
            });
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
