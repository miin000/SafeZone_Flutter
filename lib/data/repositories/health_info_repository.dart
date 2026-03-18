import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/data/models/health_info_model.dart';

abstract class HealthInfoRepository {
  Future<HealthInfoResponse> fetchHealthInfo({
    required int page,
    required int limit,
    String? category,
    String? search,
  });

  Future<HealthInfoResponse> fetchFeatured();

  Future<HealthInfoResponse> fetchByCategory(String category);
}

class HealthInfoRepositoryImpl implements HealthInfoRepository {
  HealthInfoRepositoryImpl();

  @override
  Future<HealthInfoResponse> fetchHealthInfo({
    required int page,
    required int limit,
    String? category,
    String? search,
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      };

      final response = await ApiClient.instance.get(
        '/health-info/public',
        queryParameters: params,
      );
      return _parseHealthInfoResponse(response.data);
    } catch (e) {
      throw Exception('Failed to fetch health info: $e');
    }
  }

  @override
  Future<HealthInfoResponse> fetchFeatured() async {
    try {
      final response = await ApiClient.instance.get('/health-info/public/featured');
      return _parseHealthInfoResponse(response.data);
    } catch (e) {
      throw Exception('Failed to fetch featured health info: $e');
    }
  }

  @override
  Future<HealthInfoResponse> fetchByCategory(String category) async {
    try {
      final response = await ApiClient.instance.get('/health-info/public/category/$category');
      return _parseHealthInfoResponse(response.data);
    } catch (e) {
      throw Exception('Failed to fetch health info by category: $e');
    }
  }

  HealthInfoResponse _parseHealthInfoResponse(dynamic payload) {
    if (payload is List) {
      return HealthInfoResponse.fromJson({'data': payload});
    }
    if (payload is Map<String, dynamic>) {
      if (payload['items'] is List) {
        return HealthInfoResponse.fromJson({
          'data': payload['items'],
          'meta': payload['meta'],
        });
      }
      if (payload['data'] is List || payload['data'] == null) {
        return HealthInfoResponse.fromJson(payload);
      }
    }
    throw Exception('Invalid health info response format');
  }
}
