import 'package:dio/dio.dart';
import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/data/datasources/remote/zone_remote_datasource.dart';
import 'package:mobile_flutter/data/models/zone_model.dart';

abstract class ZoneRepository {
  Future<List<ZoneModel>> getZones({int? page, int? limit});
  Future<List<ZoneModel>> getNearbyZones(double lat, double lon, {double radius = 5});
  Future<List<ZoneModel>> checkZoneEntry(double lat, double lon);
  Future<ZoneModel> getZoneById(String id);
  Future<Map<String, dynamic>> getZoneStats();
}

class ZoneRepositoryImpl implements ZoneRepository {
  final ApiClient _apiClient;

  ZoneRepositoryImpl({ApiClient? apiClient})
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
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
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
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
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
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<ZoneModel> getZoneById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.zones}/$id');
      return ZoneModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getZoneStats() async {
    try {
      final response = await _apiClient.get(ApiConstants.zonesStats);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  Exception _handleError(DioException e) {
    String message = 'Đã xảy ra lỗi';

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else {
        switch (e.response!.statusCode) {
          case 400:
            message = 'Dữ liệu không hợp lệ';
            break;
          case 401:
            message = 'Phiên đăng nhập hết hạn';
            break;
          case 403:
            message = 'Bạn không có quyền truy cập';
            break;
          case 404:
            message = 'Không tìm thấy dữ liệu';
            break;
          case 500:
            message = 'Lỗi máy chủ';
            break;
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Kết nối quá thời gian, vui lòng thử lại';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Không thể kết nối đến máy chủ';
    } else if (e.type == DioExceptionType.badResponse) {
      message = 'Phản hồi không hợp lệ từ máy chủ';
    }

    return Exception(message);
  }
}