import 'package:iwantsun/data/datasources/remote/activity_remote_datasource.dart';
import 'package:iwantsun/domain/entities/activity.dart';
import 'package:iwantsun/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource _remoteDataSource;

  ActivityRepositoryImpl({required ActivityRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Activity>> getActivitiesNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<ActivityType> activityTypes,
  }) async {
    final models = await _remoteDataSource.getActivitiesNearLocation(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      activityTypes: activityTypes,
    );
    return models.map((model) => model.toEntity()).toList();
  }
}
