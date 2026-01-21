import 'package:flutter/foundation.dart';
import 'package:mobile_flutter/data/models/zone_model.dart'; // SỬA IMPORT
import 'package:mobile_flutter/data/repositories/zone_repository_impl.dart'; // SỬA IMPORT

class ZoneProvider extends ChangeNotifier {
  final ZoneRepository _repository;

  ZoneProvider({ZoneRepository? repository})
      : _repository = repository ?? ZoneRepositoryImpl();

  // State
  List<ZoneModel> _zones = [];
  List<ZoneModel> _nearbyZones = [];
  ZoneModel? _selectedZone;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ZoneModel> get zones => _zones;
  List<ZoneModel> get nearbyZones => _nearbyZones;
  ZoneModel? get selectedZone => _selectedZone;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ZoneModel> get highRiskZones =>
      _zones.where((zone) => zone.riskLevel == RiskLevel.high).toList();

  List<ZoneModel> get activeZones =>
      _zones.where((zone) => zone.isActive).toList();

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

  // Fetch all zones
  Future<void> fetchZones({int? page, int? limit}) async {
    _setLoading(true);
    _setError(null);

    try {
      _zones = await _repository.getZones(
        page: page,
        limit: limit,
      );
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Fetch nearby zones
  Future<void> fetchNearbyZones(double lat, double lon, {double radius = 5}) async {
    _setLoading(true);
    _setError(null);

    try {
      _nearbyZones = await _repository.getNearbyZones(
        lat,
        lon,
        radius: radius,
      );
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Check if location is in any zone
  Future<bool> checkIfInZone(double lat, double lon) async {
    try {
      final result = await _repository.checkZoneEntry(lat, lon);
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get zone by ID
  Future<void> fetchZoneById(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      _selectedZone = await _repository.getZoneById(id);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Get zone statistics
  Future<Map<String, dynamic>> getZoneStats() async {
    try {
      return await _repository.getZoneStats();
    } catch (e) {
      return {};
    }
  }

  void selectZone(ZoneModel zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  void clearSelectedZone() {
    _selectedZone = null;
    notifyListeners();
  }
}