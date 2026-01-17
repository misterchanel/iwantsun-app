import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/user_profile_service.dart';
import 'package:iwantsun/core/services/gamification_service.dart';
import 'package:iwantsun/presentation/providers/favorites_provider.dart';

/// Écran de profil utilisateur
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _profileService = UserProfileService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    await _profileService.init();
    if (mounted) {
      setState(() {
        _nameController.text = _profileService.profile.name ?? '';
        _emailController.text = _profileService.profile.email ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _profileService,
        builder: (context, _) {
          if (_profileService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = _profileService.profile;

          return SingleChildScrollView(
            child: Column(
              children: [
                // En-tête du profil
                _buildProfileHeader(profile),

                // Statistiques
                _buildStatisticsSection(),

                // Informations personnelles
                _buildPersonalInfoSection(profile),

                // Préférences de température
                _buildTemperatureSection(profile),

                // Activités préférées
                _buildActivitiesSection(profile),

                // Paramètres de localisation
                _buildLocationSection(profile),

                // Notifications
                _buildNotificationsSection(profile),

                const SizedBox(height: 24),

                // Bouton réinitialiser
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réinitialiser le profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryOrange, AppColors.sunsetOrange],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.white,
                child: profile.name != null && profile.name!.isNotEmpty
                    ? Text(
                        profile.name![0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primaryOrange,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nom
          Text(
            profile.name ?? 'Voyageur',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),

          if (profile.email != null)
            Text(
              profile.email!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),

          const SizedBox(height: 16),

          // Barre de progression du profil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profil complété',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${profile.completionPercentage}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: profile.completionPercentage / 100,
                    backgroundColor: AppColors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(AppColors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Consumer2<FavoritesProvider, GamificationService>(
      builder: (context, favoritesProvider, gamificationService, _) {
        final stats = gamificationService.stats;
        final unlockedBadges = gamificationService.unlockedBadges;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.favorite,
                value: '${favoritesProvider.favoritesCount}',
                label: 'Favoris',
                color: AppColors.errorRed,
              ),
              _buildStatItem(
                icon: Icons.search,
                value: '${stats.totalSearches}',
                label: 'Recherches',
                color: AppColors.primaryBlue,
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                value: '${unlockedBadges.length}',
                label: 'Badges',
                color: AppColors.goldenYellow,
                onTap: () => context.push('/badges'),
              ),
              _buildStatItem(
                icon: Icons.star,
                value: 'Niv. ${stats.level}',
                label: '${stats.totalXP} XP',
                color: AppColors.successGreen,
                onTap: () => context.push('/badges'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkGray.withOpacity(0.7),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _buildPersonalInfoSection(UserProfile profile) {
    return _buildSection(
      title: 'Informations personnelles',
      icon: Icons.person,
      children: [
        // Nom
        ListTile(
          leading: const Icon(Icons.badge, color: AppColors.primaryOrange),
          title: const Text('Nom'),
          subtitle: Text(profile.name ?? 'Non défini'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => _editName(),
        ),
        const Divider(height: 1),
        // Email
        ListTile(
          leading: const Icon(Icons.email, color: AppColors.primaryOrange),
          title: const Text('Email'),
          subtitle: Text(profile.email ?? 'Non défini'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => _editEmail(),
        ),
      ],
    );
  }

  Widget _buildTemperatureSection(UserProfile profile) {
    final tempPrefs = [
      TemperaturePreference.hot,
      TemperaturePreference.warm,
      TemperaturePreference.mild,
      TemperaturePreference.cool,
    ];

    return _buildSection(
      title: 'Préférence de température',
      icon: Icons.thermostat,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tempPrefs.map((pref) {
              final isSelected = profile.temperaturePreference?.label == pref.label;
              return ChoiceChip(
                label: Text('${pref.label} (${pref.minTemp.toInt()}-${pref.maxTemp.toInt()}°C)'),
                selected: isSelected,
                onSelected: (_) {
                  _profileService.updateTemperaturePreference(pref);
                },
                selectedColor: AppColors.primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesSection(UserProfile profile) {
    return _buildSection(
      title: 'Activités préférées',
      icon: Icons.local_activity,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AvailableActivities.all.map((activity) {
              final isSelected = profile.preferredActivities.contains(activity.id);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activity.icon,
                      size: 16,
                      color: isSelected ? AppColors.white : AppColors.darkGray,
                    ),
                    const SizedBox(width: 4),
                    Text(activity.name),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _profileService.addPreferredActivity(activity.id);
                  } else {
                    _profileService.removePreferredActivity(activity.id);
                  }
                },
                selectedColor: AppColors.primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(UserProfile profile) {
    return _buildSection(
      title: 'Localisation',
      icon: Icons.location_on,
      children: [
        SwitchListTile(
          title: const Text('Utiliser ma position actuelle'),
          subtitle: const Text('Pour des recherches plus précises'),
          value: profile.useCurrentLocation,
          onChanged: (value) {
            _profileService.updateLocationSettings(useCurrentLocation: value);
          },
          activeColor: AppColors.primaryOrange,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.home, color: AppColors.primaryOrange),
          title: const Text('Lieu de résidence'),
          subtitle: Text(profile.homeLocation ?? 'Non défini'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => _editHomeLocation(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.radar, color: AppColors.primaryOrange),
          title: const Text('Rayon de recherche par défaut'),
          subtitle: Text('${profile.defaultSearchRadius} km'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => _editSearchRadius(),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(UserProfile profile) {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text('Notifications'),
          subtitle: const Text('Recevoir des notifications'),
          value: profile.notificationsEnabled,
          onChanged: (value) {
            _profileService.updateNotificationSettings(notificationsEnabled: value);
          },
          activeColor: AppColors.primaryOrange,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('Alertes météo'),
          subtitle: const Text('Être alerté des changements météo'),
          value: profile.weatherAlertsEnabled,
          onChanged: profile.notificationsEnabled
              ? (value) {
                  _profileService.updateNotificationSettings(weatherAlertsEnabled: value);
                }
              : null,
          activeColor: AppColors.primaryOrange,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('Bons plans'),
          subtitle: const Text('Recevoir des offres de voyage'),
          value: profile.dealsEnabled,
          onChanged: profile.notificationsEnabled
              ? (value) {
                  _profileService.updateNotificationSettings(dealsEnabled: value);
                }
              : null,
          activeColor: AppColors.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primaryOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
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

  void _editName() {
    _nameController.text = _profileService.profile.name ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _profileService.updateName(_nameController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editEmail() {
    _emailController.text = _profileService.profile.email ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'email'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _profileService.updateEmail(_emailController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editHomeLocation() {
    final controller = TextEditingController(
      text: _profileService.profile.homeLocation ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lieu de résidence'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ville, Pays',
            border: OutlineInputBorder(),
            hintText: 'Ex: Paris, France',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _profileService.updateLocationSettings(
                homeLocation: controller.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editSearchRadius() {
    double currentRadius = _profileService.profile.defaultSearchRadius.toDouble();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rayon de recherche'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentRadius.toInt()} km',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentRadius,
                min: 50,
                max: 1000,
                divisions: 19,
                activeColor: AppColors.primaryOrange,
                label: '${currentRadius.toInt()} km',
                onChanged: (value) {
                  setDialogState(() {
                    currentRadius = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _profileService.updateDefaultSearchRadius(currentRadius.toInt());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le profil'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser votre profil ? '
          'Toutes vos préférences seront effacées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _profileService.resetProfile();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil réinitialisé'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
