import 'package:flutter/foundation.dart';
import 'package:mobile_flutter/data/models/statistics_model.dart';
import 'package:mobile_flutter/data/repositories/statistics_repository.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsRepository _repository;

  DiseaseStats? _stats;
  TimelineData? _timeline;
  bool _isLoading = false;
  String? _error;

  DiseaseStats? get stats => _stats;
  TimelineData? get timeline => _timeline;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StatisticsProvider({StatisticsRepository? repository})
      : _repository = repository ?? StatisticsRepositoryImpl();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchStatistics() async {
    _setLoading(true);
    _setError(null);

    try {
      _stats = await _repository.fetchStatistics();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _stats = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTimeline({
    String? diseaseType,
    int days = 30,
    String? regionCode,
  }) async {
    _setError(null);
    try {
      _timeline = await _repository.fetchTimeline(
        diseaseType: diseaseType,
        days: days,
        regionCode: regionCode,
      );
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _timeline = null;
    } finally {
      notifyListeners();
    }
  }
}
