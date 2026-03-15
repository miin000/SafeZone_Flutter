import 'package:dio/dio.dart';
import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/data/models/zone_model.dart';

abstract class ZoneRemoteDatasource {
  Future<List<ZoneModel>> getZones({int? page, int? limit});
  Future<List<ZoneModel>> getNearbyZones(double lat, double lon, {double radius = 5});
  Future<List<ZoneModel>> checkZoneEntry(double lat, double lon);
  Future<ZoneModel> getZoneById(String id);
  Future<Map<String, dynamic>> getZoneStats();
}

class ZoneRemoteDatasourceImpl implements ZoneRemoteDatasource {
  final ApiClient _apiClient;

  ZoneRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<List<ZoneModel>> getZones({int? page, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(
        ApiConstants.zones,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['items'] ?? [];

      return data.map((json) => ZoneModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ZoneModel>> getNearbyZones(double lat, double lon, {double radius = 5}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.zonesNearby,
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'radius': radius,
        },
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['items'] ?? [];

      return data.map((json) => ZoneModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ZoneModel>> checkZoneEntry(double lat, double lon) async {
    try {
      final response = await _apiClient.get(
        '/zones/check',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );

      final data = response.data;
      if (data['zones'] != null) {
        return (data['zones'] as List)
            .map((json) => ZoneModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ZoneModel> getZoneById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.zones}/$id');
      return ZoneModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getZoneStats() async {
    try {
      final response = await _apiClient.get(ApiConstants.zonesStats);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String message = 'Đã xảy ra lỗi';

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
    }

    return Exception(message);
  }
}