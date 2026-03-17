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
  @override
  Future<HealthInfoResponse> fetchHealthInfo({
    required int page,
    required int limit,
    String? category,
    String? search,
  }) {
    // TODO: implement fetchHealthInfo by calling API via Dio
    throw UnimplementedError();
  }

  @override
  Future<HealthInfoResponse> fetchFeatured() {
    // TODO: implement fetchFeatured by calling API via Dio
    throw UnimplementedError();
  }

  @override
  Future<HealthInfoResponse> fetchByCategory(String category) {
    // TODO: implement fetchByCategory by calling API via Dio
    throw UnimplementedError();
  }
}
