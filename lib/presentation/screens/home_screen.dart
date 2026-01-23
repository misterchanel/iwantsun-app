import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/presentation/widgets/recent_searches_chips.dart';

/// Écran d'accueil avec sélection du mode de recherche
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32.0, 48.0, 32.0, 32.0),
                child: Column(
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
                          size: 64,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'I Want Sun',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Trouvez votre destination idéale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white.withOpacity(0.95),
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Recherches récentes
                        RecentSearchesChips(
                          maxChips: 3,
                          onSearchSelected: (entry) {
                            // Pré-remplir et naviguer vers le formulaire approprié (Point 5/22)
                            if (entry.params is EventSearchParams) {
                              // Recherche d'événements
                              context.push('/search/event', extra: entry.params);
                            } else if (entry.params is AdvancedSearchParams) {
                              // Recherche d'activité
                              context.push('/search/activity', extra: entry.params);
                            } else {
                              // Recherche de destination
                              context.push('/search/destination', extra: entry.params);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        // Mode recherche de destination
                        _SearchModeCard(
                          title: 'Recherche de Destination',
                          description:
                              'Recherchez par météo, localisation et période',
                          icon: Icons.search,
                          color: AppColors.primaryOrange,
                          onTap: () {
                            context.push('/search/destination');
                          },
                        ),
                        const SizedBox(height: 24),
                        // Mode recherche d'activité
                        _SearchModeCard(
                          title: 'Recherche d\'Activité',
                          description:
                              'Recherchez des destinations pour vos activités',
                          icon: Icons.sports_soccer,
                          color: AppColors.orangeSun,
                          onTap: () {
                            context.push('/search/activity');
                          },
                        ),
                        const SizedBox(height: 24),
                        // Mode recherche d'événements
                        _SearchModeCard(
                          title: 'Recherche d\'Événements',
                          description:
                              'Recherchez des événements près de chez vous',
                          icon: Icons.event,
                          color: AppColors.warmPeach,
                          onTap: () {
                            context.push('/search/event');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
      // Bouton favoris en haut à droite
      Positioned(
        top: 16,
        right: 16,
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => context.push('/favorites'),
              tooltip: 'Mes favoris',
            ),
          ),
        ),
      ),
      // Bouton paramètres en haut à gauche
      Positioned(
        top: 16,
        left: 16,
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => context.push('/settings'),
              tooltip: 'Paramètres',
            ),
          ),
        ),
      ),
    ],
    ),
    );
  }
}

/// Carte pour sélectionner un mode de recherche
class _SearchModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SearchModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.darkGray.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
