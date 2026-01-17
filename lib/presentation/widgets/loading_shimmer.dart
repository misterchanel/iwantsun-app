import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// Widget shimmer pour effet de chargement
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGray.withOpacity(0.3),
      highlightColor: AppColors.white.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Shimmer pour une carte d'hôtel
class HotelCardShimmer extends StatelessWidget {
  const HotelCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LoadingShimmer(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LoadingShimmer(width: double.infinity, height: 20),
                      const SizedBox(height: 8),
                      LoadingShimmer(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 14,
                      ),
                      const SizedBox(height: 8),
                      const LoadingShimmer(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer pour une carte météo
class WeatherCardShimmer extends StatelessWidget {
  const WeatherCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoadingShimmer(width: 150, height: 24),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoadingShimmer(width: 80, height: 40),
                    const SizedBox(height: 8),
                    LoadingShimmer(
                      width: 100,
                      height: 16,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                LoadingShimmer(
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(30),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShimmerInfo(),
                _buildShimmerInfo(),
                _buildShimmerInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerInfo() {
    return const Column(
      children: [
        LoadingShimmer(width: 40, height: 14),
        SizedBox(height: 4),
        LoadingShimmer(width: 50, height: 12),
      ],
    );
  }
}

/// Shimmer pour la liste de résultats
class ResultsListShimmer extends StatelessWidget {
  final int itemCount;
  final Widget shimmerItem;

  const ResultsListShimmer({
    super.key,
    this.itemCount = 5,
    required this.shimmerItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: shimmerItem,
        );
      },
    );
  }
}

/// Shimmer pour une carte de destination
class DestinationCardShimmer extends StatelessWidget {
  const DestinationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingShimmer(width: 200, height: 24),
                const SizedBox(height: 8),
                const LoadingShimmer(width: 150, height: 16),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoShimmer(),
                    _buildInfoShimmer(),
                    _buildInfoShimmer(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoShimmer() {
    return const Column(
      children: [
        LoadingShimmer(width: 60, height: 14),
        SizedBox(height: 4),
        LoadingShimmer(width: 40, height: 12),
      ],
    );
  }
}

/// Shimmer personnalisé pour texte
class TextShimmer extends StatelessWidget {
  final double width;
  final double height;

  const TextShimmer({
    super.key,
    required this.width,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
