import 'package:iwantsun/domain/entities/activity.dart';

/// Repository interface pour les activités
abstract class ActivityRepository {
  Future<List<Activity>> getActivitiesNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<ActivityType> activityTypes,
  });
}
