import 'package:mobile_flutter/data/models/statistics_model.dart';

abstract class StatisticsRepository {
  Future<DiseaseStats> fetchStatistics();
  Future<TimelineData> fetchTimeline({
    String? diseaseType,
    required int days,
    String? regionCode,
  });
}

class StatisticsRepositoryImpl implements StatisticsRepository {
  @override
  Future<DiseaseStats> fetchStatistics() {
    // TODO: implement fetchStatistics by calling API via Dio
    throw UnimplementedError();
  }

  @override
  Future<TimelineData> fetchTimeline({
    String? diseaseType,
    required int days,
    String? regionCode,
  }) {
    // TODO: implement fetchTimeline by calling API via Dio
    throw UnimplementedError();
  }
}
