// Report Repository Implementation
import '../datasources/remote/report_remote_datasource.dart';
import '../models/report_model.dart';

abstract class ReportRepository {
  Future<ReportModel> createReport(CreateReportRequest request);
  Future<List<ReportModel>> getReports({int? page, int? limit, String? status});
  Future<List<ReportModel>> getMyReports();
  Future<ReportModel> getReportById(String id);
  Future<List<ReportModel>> getNearbyReports(double lat, double lon, {double radius = 5});
  Future<ReportModel> updateReport(String id, Map<String, dynamic> data);
  Future<void> deleteReport(String id);
  Future<Map<String, dynamic>> getReportStats();
}

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDatasource _remoteDatasource;

  ReportRepositoryImpl({ReportRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? ReportRemoteDatasourceImpl();

  @override
  Future<ReportModel> createReport(CreateReportRequest request) {
    return _remoteDatasource.createReport(request);
  }

  @override
  Future<List<ReportModel>> getReports({
    int? page,
    int? limit,
    String? status,
  }) {
    return _remoteDatasource.getReports(
      page: page,
      limit: limit,
      status: status,
    );
  }

  @override
  Future<List<ReportModel>> getMyReports() {
    return _remoteDatasource.getMyReports();
  }

  @override
  Future<ReportModel> getReportById(String id) {
    return _remoteDatasource.getReportById(id);
  }

  @override
  Future<List<ReportModel>> getNearbyReports(
    double lat,
    double lon, {
    double radius = 5,
  }) {
    return _remoteDatasource.getNearbyReports(lat, lon, radius: radius);
  }

  @override
  Future<ReportModel> updateReport(String id, Map<String, dynamic> data) {
    return _remoteDatasource.updateReport(id, data);
  }

  @override
  Future<void> deleteReport(String id) {
    return _remoteDatasource.deleteReport(id);
  }

  @override
  Future<Map<String, dynamic>> getReportStats() {
    return _remoteDatasource.getReportStats();
  }
}
