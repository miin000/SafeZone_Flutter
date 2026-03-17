import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
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
  StatisticsRepositoryImpl();

  @override
  Future<DiseaseStats> fetchStatistics() async {
    try {
      final response = await ApiClient.instance.get(ApiConstants.gisStats);
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        if (payload['data'] is Map<String, dynamic>) {
          return DiseaseStats.fromJson(payload['data'] as Map<String, dynamic>);
        }
        return DiseaseStats.fromJson(payload);
      }
      throw Exception('Invalid statistics response format');
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  @override
  Future<TimelineData> fetchTimeline({
    String? diseaseType,
    required int days,
    String? regionCode,
  }) async {
    try {
      final params = {
        'days': days,
        if (diseaseType != null) 'diseaseType': diseaseType,
        if (regionCode != null) 'regionCode': regionCode,
      };

      final response = await ApiClient.instance.get(
        ApiConstants.gisStats,
        queryParameters: params,
      );
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        if (payload['data'] is Map<String, dynamic>) {
          return TimelineData.fromJson(payload['data'] as Map<String, dynamic>);
        }
        return TimelineData.fromJson(payload);
      }
      throw Exception('Invalid timeline response format');
    } catch (e) {
      throw Exception('Failed to fetch timeline: $e');
    }
  }
}
