import 'package:flutter/material.dart';
import 'package:iwantsun/core/services/search_history_service.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// Widget affichant les recherches récentes sous forme de chips cliquables
class RecentSearchesChips extends StatelessWidget {
  final Function(SearchHistoryEntry) onSearchSelected;
  final int maxChips;

  const RecentSearchesChips({
    super.key,
    required this.onSearchSelected,
    this.maxChips = 5,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SearchHistoryEntry>>(
      future: SearchHistoryService().getRecentSearches(limit: maxChips),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final searches = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history,
                  size: 18,
                  color: AppColors.darkGray,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: searches.map((entry) => _buildChip(context, entry)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChip(BuildContext context, SearchHistoryEntry entry) {
    return InkWell(
      onTap: () => onSearchSelected(entry),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryOrange.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(width: 6),
            Text(
              entry.locationName ?? 'Localisation',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '•',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkGray.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _formatTemperature(entry),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkGray.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTemperature(SearchHistoryEntry entry) {
    final minTemp = entry.params.desiredMinTemperature?.toInt() ?? 20;
    final maxTemp = entry.params.desiredMaxTemperature?.toInt() ?? 30;
    return '$minTemp-$maxTemp°C';
  }
}
