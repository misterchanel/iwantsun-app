import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/services/gamification_service.dart';

/// Écran des badges et succès
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Succès'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: Consumer<GamificationService>(
        builder: (context, gamification, _) {
          if (!gamification.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = gamification.stats;
          final allBadges = gamification.allBadges;
          final unlockedCount = gamification.unlockedBadges.length;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header avec niveau et XP
                _buildLevelHeader(context, stats, unlockedCount, allBadges.length),

                // Statistiques
                _buildStatsSection(context, stats),

                // Badges par catégorie
                _buildBadgesSection(
                  context,
                  'Exploration',
                  Icons.explore,
                  allBadges.where((b) => b.type == BadgeType.explorer).toList(),
                ),
                _buildBadgesSection(
                  context,
                  'Collection',
                  Icons.favorite,
                  allBadges.where((b) => b.type == BadgeType.collector).toList(),
                ),
                _buildBadgesSection(
                  context,
                  'Voyages',
                  Icons.flight,
                  allBadges.where((b) => b.type == BadgeType.traveler).toList(),
                ),
                _buildBadgesSection(
                  context,
                  'Partage',
                  Icons.share,
                  allBadges.where((b) => b.type == BadgeType.social).toList(),
                ),
                _buildBadgesSection(
                  context,
                  'Fidélité',
                  Icons.calendar_today,
                  allBadges.where((b) => b.type == BadgeType.veteran).toList(),
                ),
                _buildBadgesSection(
                  context,
                  'Spéciaux',
                  Icons.star,
                  allBadges.where((b) => b.type == BadgeType.special).toList(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelHeader(BuildContext context, UserStats stats, int unlocked, int total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrange.withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar avec niveau
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${stats.level}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stats.levelTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barre de progression XP
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.totalXP} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (stats.level < 10)
                    Text(
                      'Niveau ${stats.level + 1}: ${stats.xpForNextLevel} XP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.levelProgress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Compteur de badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$unlocked / $total badges débloqués',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, UserStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem(Icons.search, '${stats.totalSearches}', 'Recherches')),
              Expanded(child: _buildStatItem(Icons.favorite, '${stats.totalFavorites}', 'Favoris')),
              Expanded(child: _buildStatItem(Icons.public, '${stats.totalCountriesExplored}', 'Pays')),
              Expanded(child: _buildStatItem(Icons.share, '${stats.totalShares}', 'Partages')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                '${stats.consecutiveDays} jours consécutifs',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context, String title, IconData icon, List<Badge> badges) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${badges.where((b) => b.isUnlocked).length}/${badges.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: badges.map((badge) => _buildBadgeCard(context, badge)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, Badge badge) {
    final isUnlocked = badge.isUnlocked;

    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUnlocked
              ? badge.rarityColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? badge.rarityColor : Colors.grey[300]!,
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: badge.rarityColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji ou icône verrouillée
            Text(
              isUnlocked ? badge.iconEmoji : '🔒',
              style: TextStyle(
                fontSize: 28,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            // Nom du badge
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? badge.rarityColor : Colors.grey[600],
              ),
            ),
            // Barre de progression si non débloqué
            if (!isUnlocked) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.progressPercentage,
                  minHeight: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(badge.rarityColor),
                ),
              ),
              Text(
                '${badge.currentProgress}/${badge.requiredProgress}',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, Badge badge) {
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
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Badge icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.isUnlocked
                    ? badge.rarityColor.withOpacity(0.2)
                    : Colors.grey[200],
                border: Border.all(
                  color: badge.isUnlocked ? badge.rarityColor : Colors.grey[400]!,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  badge.isUnlocked ? badge.iconEmoji : '🔒',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nom
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Rareté
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badge.rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.rarityName,
                style: TextStyle(
                  color: badge.rarityColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Progression
            if (!badge.isUnlocked) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Progression: ${badge.currentProgress}/${badge.requiredProgress}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: badge.progressPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(badge.rarityColor),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Débloqué le ${_formatDate(badge.unlockedAt!)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
