import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';
import 'package:iwantsun/domain/entities/location.dart';

/// Dialog pour choisir une localisation parmi plusieurs résultats
class LocationPickerDialog extends StatelessWidget {
  final List<Location> locations;
  final String searchQuery;

  const LocationPickerDialog({
    super.key,
    required this.locations,
    required this.searchQuery,
  });

  static Future<Location?> show(
    BuildContext context, {
    required List<Location> locations,
    required String searchQuery,
  }) {
    return showDialog<Location>(
      context: context,
      builder: (context) => LocationPickerDialog(
        locations: locations,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plusieurs résultats pour "$searchQuery"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez choisir la localisation souhaitée:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.darkGray.withOpacity(0.8),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: locations.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final location = locations[index];
            return _LocationTile(
              location: location,
              onTap: () => Navigator.of(context).pop(location),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Annuler',
            style: TextStyle(
              color: AppColors.darkGray,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;

  const _LocationTile({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (location.country != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      location.country!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGray.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray.withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.darkGray,
            ),
          ],
        ),
      ),
    );
  }
}
