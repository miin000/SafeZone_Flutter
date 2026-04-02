import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/data/models/zone_model.dart';
import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';

enum ZoneStatus { initial, loading, loaded, error }

class ZoneProvider extends ChangeNotifier {
  ZoneStatus _status = ZoneStatus.initial;
  List<EpidemicZone> _zones = [];
  EpidemicZone? _selectedZone;
  String? _errorMessage;

  // Getters
  ZoneStatus get status => _status;
  List<EpidemicZone> get zones => _zones;
  EpidemicZone? get selectedZone => _selectedZone;
  String? get errorMessage => _errorMessage;

  // Filter zones by risk level
  List<EpidemicZone> get criticalZones =>
      _zones.where((z) => z.riskLevel == ZoneRiskLevel.critical).toList();
  List<EpidemicZone> get highRiskZones =>
      _zones.where((z) => z.riskLevel == ZoneRiskLevel.high).toList();
  List<EpidemicZone> get mediumRiskZones =>
      _zones.where((z) => z.riskLevel == ZoneRiskLevel.medium).toList();
  List<EpidemicZone> get lowRiskZones =>
      _zones.where((z) => z.riskLevel == ZoneRiskLevel.low).toList();

  // Filter zones by disease type
  List<EpidemicZone> getZonesByDisease(DiseaseType type) =>
      _zones.where((z) => z.diseaseType == type).toList();

  // Active zones only
  List<EpidemicZone> get activeZones =>
      _zones.where((z) => z.isActive && z.confirmedCases > 0).toList();

  /// Fetch all zones from API
  Future<void> fetchZones() async {
    _status = ZoneStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.get(ApiConstants.zones);

      if (response.statusCode == 200) {
        // API returns array directly or wrapped in 'data'
        final dynamic responseData = response.data;
        List<dynamic> data;

        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData['data'] != null) {
          data = responseData['data'] as List;
        } else {
          data = [];
        }

        _zones = data
            .map((json) => ZoneModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _status = ZoneStatus.loaded;
        debugPrint('Loaded ${_zones.length} zones from API');
      } else {
        _status = ZoneStatus.error;
        _errorMessage = 'Không thể tải dữ liệu vùng dịch';
      }
    } on DioException catch (e) {
      _status = ZoneStatus.error;
      _errorMessage = e.message ?? 'Lỗi kết nối máy chủ';
      debugPrint('Error fetching zones: $e');
    } catch (e) {
      _status = ZoneStatus.error;
      _errorMessage = 'Đã xảy ra lỗi: $e';
      debugPrint('Error fetching zones: $e');
    }

    notifyListeners();
  }

  /// Fetch zones nearby a location
  Future<void> fetchZonesNearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
  }) async {
    _status = ZoneStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = {
        'lat': latitude,
        'lon': longitude,
        if (radiusKm != null) 'radius': radiusKm,
      };

      final response = await ApiClient.instance.get(
        ApiConstants.zonesNearby,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> data;

        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData['data'] != null) {
          data = responseData['data'] as List;
        } else {
          data = [];
        }

        _zones = data
            .map((json) => ZoneModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _status = ZoneStatus.loaded;
        debugPrint('Loaded ${_zones.length} nearby zones from API');
      } else {
        _status = ZoneStatus.error;
        _errorMessage = 'Không thể tải dữ liệu vùng dịch gần đây';
      }
    } on DioException catch (e) {
      _status = ZoneStatus.error;
      _errorMessage = e.message ?? 'Lỗi kết nối máy chủ';
      debugPrint('Error fetching nearby zones: $e');
    } catch (e) {
      _status = ZoneStatus.error;
      _errorMessage = 'Đã xảy ra lỗi: $e';
      debugPrint('Error fetching nearby zones: $e');
    }

    notifyListeners();
  }

  /// Select a zone to show details
  void selectZone(EpidemicZone? zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedZone = null;
    notifyListeners();
  }

  /// Load mock data for testing
  void loadMockData() {
    _status = ZoneStatus.loading;
    notifyListeners();

    // Sample epidemic zones in Vietnam (Hanoi area)
    _zones = [
      EpidemicZone(
        id: '1',
        name: 'Quận Hoàn Kiếm',
        description: 'Phát hiện ổ dịch COVID-19 tại khu vực phố cổ',
        diseaseType: DiseaseType.covid19,
        riskLevel: ZoneRiskLevel.high,
        latitude: 21.0285,
        longitude: 105.8542,
        radiusMeters: 1500,
        confirmedCases: 45,
        activeCases: 12,
        recoveredCases: 32,
        deaths: 1,
        reportedAt: DateTime.now().subtract(const Duration(days: 3)),
        isActive: true,
      ),
      EpidemicZone(
        id: '2',
        name: 'Quận Đống Đa',
        description: 'Khu vực có ca sốt xuất huyết',
        diseaseType: DiseaseType.dengue,
        riskLevel: ZoneRiskLevel.medium,
        latitude: 21.0167,
        longitude: 105.8333,
        radiusMeters: 2000,
        confirmedCases: 23,
        activeCases: 8,
        recoveredCases: 15,
        deaths: 0,
        reportedAt: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      EpidemicZone(
        id: '3',
        name: 'Quận Cầu Giấy',
        description: 'Ổ dịch tay chân miệng tại trường mầm non',
        diseaseType: DiseaseType.handFootMouth,
        riskLevel: ZoneRiskLevel.critical,
        latitude: 21.0333,
        longitude: 105.7833,
        radiusMeters: 800,
        confirmedCases: 67,
        activeCases: 34,
        recoveredCases: 33,
        deaths: 0,
        reportedAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      ),
      EpidemicZone(
        id: '4',
        name: 'Quận Ba Đình',
        description: 'Ca cúm mùa gia tăng',
        diseaseType: DiseaseType.influenza,
        riskLevel: ZoneRiskLevel.low,
        latitude: 21.0395,
        longitude: 105.8170,
        radiusMeters: 1200,
        confirmedCases: 15,
        activeCases: 5,
        recoveredCases: 10,
        deaths: 0,
        reportedAt: DateTime.now().subtract(const Duration(days: 7)),
        isActive: true,
      ),
      EpidemicZone(
        id: '5',
        name: 'Quận Thanh Xuân',
        description: 'Vùng dịch sốt xuất huyết đang được kiểm soát',
        diseaseType: DiseaseType.dengue,
        riskLevel: ZoneRiskLevel.high,
        latitude: 20.9933,
        longitude: 105.8117,
        radiusMeters: 1800,
        confirmedCases: 38,
        activeCases: 15,
        recoveredCases: 22,
        deaths: 1,
        reportedAt: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
      ),
    ];

    _status = ZoneStatus.loaded;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _zones = [];
    _selectedZone = null;
    _status = ZoneStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
