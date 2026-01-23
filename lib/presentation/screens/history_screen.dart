import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/core/animations/list_animations.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/domain/entities/search_params.dart';
import 'package:iwantsun/presentation/providers/favorites_provider.dart';
import 'package:iwantsun/presentation/providers/search_provider.dart';
import 'package:iwantsun/presentation/widgets/empty_state.dart';
import 'package:iwantsun/presentation/widgets/loading_indicator.dart';
import 'package:iwantsun/presentation/widgets/animated_card.dart';

/// Écran d'historique des recherches
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.lightBeige],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Consumer<FavoritesProvider>(
                  builder: (context, provider, _) => Text(
                    '${provider.historyCount} recherche${provider.historyCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<FavoritesProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: _showClearConfirmation,
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                tooltip: 'Vider l\'historique',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory) {
          return const Center(
            child: LoadingIndicator(
              message: 'Chargement de l\'historique...',
            ),
          );
        }

        if (provider.history.isEmpty) {
          return EmptyState(
            icon: Icons.history,
            title: 'Aucun historique',
            message: 'Vos recherches récentes apparaîtront ici.',
            actionLabel: 'Nouvelle recherche',
            onAction: () => context.go('/search/destination'),
          );
        }

        // Grouper par date
        final groupedHistory = _groupByDate(provider.history);

        return RefreshIndicator(
          onRefresh: provider.loadHistory,
          color: AppColors.primaryBlue,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedHistory.length,
            itemBuilder: (context, index) {
              final group = groupedHistory[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            group.dateLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Entrées du groupe
                  ...group.entries.asMap().entries.map((e) {
                    return AnimatedListItem(
                      index: e.key,
                      child: _HistoryEntryCard(
                        entry: e.value,
                        onTap: () => _replaySearch(e.value),
                        onViewResults: e.value.results != null && e.value.results!.isNotEmpty
                            ? () => _viewResults(e.value)
                            : null,
                        onDelete: () => _deleteEntry(e.value),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<_HistoryGroup> _groupByDate(List<SearchHistoryEntry> entries) {
    final groups = <String, List<SearchHistoryEntry>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in entries) {
      final entryDate = DateTime(
        entry.searchedAt.year,
        entry.searchedAt.month,
        entry.searchedAt.day,
      );

      String label;
      if (entryDate == today) {
        label = "Aujourd'hui";
      } else if (entryDate == yesterday) {
        label = 'Hier';
      } else if (entryDate.isAfter(today.subtract(const Duration(days: 7)))) {
        label = DateFormat('EEEE', 'fr_FR').format(entryDate);
        // Capitalize first letter
        label = label[0].toUpperCase() + label.substring(1);
      } else {
        label = DateFormat('d MMMM yyyy', 'fr_FR').format(entryDate);
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(entry);
    }

    return groups.entries
        .map((e) => _HistoryGroup(dateLabel: e.key, entries: e.value))
        .toList();
  }

  void _replaySearch(SearchHistoryEntry entry) {
    // Si des résultats sont disponibles, naviguer vers les résultats (Point 12)
    if (entry.results != null && entry.results!.isNotEmpty) {
      // Stocker les résultats dans le provider
      final searchProvider = context.read<SearchProvider>();
      searchProvider.setResults(entry.results!);
      context.push('/search/results');
    } else {
      // Sinon, pré-remplir le formulaire
      if (entry.params is AdvancedSearchParams) {
        context.push('/search/activity', extra: entry.params);
      } else {
        context.push('/search/destination', extra: entry.params);
      }
    }
  }

  /// Affiche les résultats sauvegardés (Point 12)
  void _viewResults(SearchHistoryEntry entry) {
    if (entry.results != null && entry.results!.isNotEmpty) {
      final searchProvider = context.read<SearchProvider>();
      searchProvider.setResults(entry.results!);
      context.push('/search/results');
    }
  }

  Future<void> _deleteEntry(SearchHistoryEntry entry) async {
    await context.read<FavoritesProvider>().removeHistoryEntry(entry.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrée supprimée de l\'historique')),
      );
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider l\'historique ?'),
        content: const Text(
          'Toutes vos recherches seront effacées. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<FavoritesProvider>().clearHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historique vidé')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}

/// Groupe d'entrées par date
class _HistoryGroup {
  final String dateLabel;
  final List<SearchHistoryEntry> entries;

  _HistoryGroup({required this.dateLabel, required this.entries});
}

/// Carte d'entrée d'historique
class _HistoryEntryCard extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onViewResults; // Point 12

  const _HistoryEntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    this.onViewResults,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Supprimer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedCard(
        margin: const EdgeInsets.only(bottom: 12),
        onTap: onTap,
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.locationName ?? 'Recherche',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.thermostat, size: 14, color: AppColors.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        _getTemperatureRange(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today, size: 14, color: AppColors.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        _getDateRange(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Résultats et heure
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onViewResults != null && entry.resultsCount > 0) ...[
                  // Bouton pour voir les résultats (Point 12)
                  OutlinedButton.icon(
                    onPressed: onViewResults,
                    icon: const Icon(Icons.visibility, size: 14),
                    label: Text('Voir ${entry.resultsCount} résultat${entry.resultsCount > 1 ? 's' : ''}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                  const SizedBox(height: 4),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.resultsCount > 0
                          ? AppColors.successGreen.withOpacity(0.1)
                          : AppColors.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.resultsCount} résultat${entry.resultsCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: entry.resultsCount > 0
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  timeFormat.format(entry.searchedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.mediumGray),
          ],
        ),
      ),
    );
  }

  String _getTemperatureRange() {
    final minTemp = entry.params.desiredMinTemperature?.toInt() ?? 20;
    final maxTemp = entry.params.desiredMaxTemperature?.toInt() ?? 30;
    return '$minTemp-$maxTemp°C';
  }

  String _getDateRange() {
    final start = DateFormat('dd/MM').format(entry.params.startDate);
    final end = DateFormat('dd/MM').format(entry.params.endDate);
    return '$start - $end';
  }
}

/// Widget pour afficher les recherches récentes sur l'écran d'accueil
class RecentSearchesWidget extends StatelessWidget {
  final int limit;
  final VoidCallback? onSeeAll;

  const RecentSearchesWidget({
    super.key,
    this.limit = 3,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        final recentSearches = provider.getRecentSearches(limit: limit);

        if (recentSearches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppColors.primaryBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Recherches récentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  if (onSeeAll != null)
                    TextButton(
                      onPressed: onSeeAll,
                      child: const Text('Tout voir'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  final entry = recentSearches[index];
                  return _RecentSearchChip(
                    entry: entry,
                    onTap: () => context.go('/search/destination', extra: entry.params),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentSearchChip extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onTap;

  const _RecentSearchChip({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.locationName ?? 'Recherche',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.thermostat, size: 12, color: AppColors.mediumGray),
                const SizedBox(width: 4),
                Text(
                  '${entry.params.desiredMinTemperature?.toInt() ?? 20}-${entry.params.desiredMaxTemperature?.toInt() ?? 30}°C',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.resultsCount} résultat${entry.resultsCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: entry.resultsCount > 0
                    ? AppColors.successGreen
                    : AppColors.mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
