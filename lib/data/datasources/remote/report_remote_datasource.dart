// Report Remote Datasource
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/report_model.dart';

abstract class ReportRemoteDatasource {
  Future<ReportModel> createReport(CreateReportRequest request);
  Future<List<ReportModel>> getReports({int? page, int? limit, String? status});
  Future<List<ReportModel>> getMyReports();
  Future<ReportModel> getReportById(String id);
  Future<List<ReportModel>> getNearbyReports(double lat, double lon, {double radius = 5});
  Future<ReportModel> updateReport(String id, Map<String, dynamic> data);
  Future<void> deleteReport(String id);
  Future<Map<String, dynamic>> getReportStats();
}

class ReportRemoteDatasourceImpl implements ReportRemoteDatasource {
  final ApiClient _apiClient;

  ReportRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<ReportModel> createReport(CreateReportRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.reports,
        data: request.toJson(),
      );
      return ReportModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ReportModel>> getReports({
    int? page,
    int? limit,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        ApiConstants.reports,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data is List 
          ? response.data 
          : response.data['items'] ?? [];
      
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ReportModel>> getMyReports() async {
    try {
      final response = await _apiClient.get(ApiConstants.myReports);
      
      final List<dynamic> data = response.data is List 
          ? response.data 
          : response.data['items'] ?? [];
      
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ReportModel> getReportById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.reports}/$id');
      return ReportModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ReportModel>> getNearbyReports(
    double lat,
    double lon, {
    double radius = 5,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.reportsNearby,
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'radius': radius,
        },
      );

      final List<dynamic> data = response.data is List 
          ? response.data 
          : response.data['items'] ?? [];
      
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ReportModel> updateReport(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.reports}/$id',
        data: data,
      );
      return ReportModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteReport(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.reports}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final response = await _apiClient.get(ApiConstants.reportsStats);
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
      } else {
        switch (e.response!.statusCode) {
          case 400:
            message = 'Dữ liệu không hợp lệ';
            break;
          case 401:
            message = 'Phiên đăng nhập hết hạn';
            break;
          case 403:
            message = 'Bạn không có quyền thực hiện thao tác này';
            break;
          case 404:
            message = 'Không tìm thấy báo cáo';
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
    }
    
    return Exception(message);
  }
}
