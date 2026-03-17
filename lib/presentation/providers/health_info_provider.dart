import 'package:flutter/foundation.dart';
import 'package:mobile_flutter/data/models/health_info_model.dart';
import 'package:mobile_flutter/data/repositories/health_info_repository.dart';

class HealthInfoProvider extends ChangeNotifier {
  final HealthInfoRepository _repository;

  List<HealthInfo> _healthInfoList = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  List<HealthInfo> get healthInfoList => _healthInfoList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  HealthInfoProvider({HealthInfoRepository? repository})
      : _repository = repository ?? HealthInfoRepositoryImpl();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchHealthInfo({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _repository.fetchHealthInfo(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );

      if (page == 1) {
        _healthInfoList = response.data;
      } else {
        _healthInfoList.addAll(response.data);
      }

      if (response.meta != null) {
        _currentPage = response.meta!.page;
        _totalPages = response.meta!.totalPages;
      }

      _setError(null);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFeatured() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _repository.fetchFeatured();
      _healthInfoList = response.data;
      _setError(null);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchByCategory(String category) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _repository.fetchByCategory(category);
      _healthInfoList = response.data;
      _setError(null);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMore() async {
    if (_currentPage < _totalPages && !_isLoading) {
      await fetchHealthInfo(page: _currentPage + 1);
    }
  }
}
