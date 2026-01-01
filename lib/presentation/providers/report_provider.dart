// Report Provider
import 'package:flutter/foundation.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository_impl.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider({ReportRepository? repository})
      : _repository = repository ?? ReportRepositoryImpl();

  // State
  List<ReportModel> _reports = [];
  List<ReportModel> _myReports = [];
  ReportModel? _selectedReport;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ReportModel> get reports => _reports;
  List<ReportModel> get myReports => _myReports;
  ReportModel? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Create a new report
  Future<bool> createReport(CreateReportRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      final report = await _repository.createReport(request);
      _myReports.insert(0, report);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Get all reports
  Future<void> fetchReports({int? page, int? limit, String? status}) async {
    _setLoading(true);
    _setError(null);

    try {
      _reports = await _repository.getReports(
        page: page,
        limit: limit,
        status: status,
      );
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Get my reports
  Future<void> fetchMyReports() async {
    _setLoading(true);
    _setError(null);

    try {
      _myReports = await _repository.getMyReports();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Get report by ID
  Future<void> fetchReportById(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      _selectedReport = await _repository.getReportById(id);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Get nearby reports
  Future<void> fetchNearbyReports(
    double lat,
    double lon, {
    double radius = 5,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _reports = await _repository.getNearbyReports(lat, lon, radius: radius);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Update report
  Future<bool> updateReport(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedReport = await _repository.updateReport(id, data);
      
      // Update in lists
      final index = _reports.indexWhere((r) => r.id == id);
      if (index != -1) {
        _reports[index] = updatedReport;
      }
      
      final myIndex = _myReports.indexWhere((r) => r.id == id);
      if (myIndex != -1) {
        _myReports[myIndex] = updatedReport;
      }
      
      if (_selectedReport?.id == id) {
        _selectedReport = updatedReport;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Delete report
  Future<bool> deleteReport(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.deleteReport(id);
      
      _reports.removeWhere((r) => r.id == id);
      _myReports.removeWhere((r) => r.id == id);
      
      if (_selectedReport?.id == id) {
        _selectedReport = null;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  void selectReport(ReportModel report) {
    _selectedReport = report;
    notifyListeners();
  }

  void clearSelectedReport() {
    _selectedReport = null;
    notifyListeners();
  }
}
