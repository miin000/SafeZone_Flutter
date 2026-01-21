// Location Provider
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  LocationPermission? _permissionStatus;
  bool _isLoading = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  LocationPermission? get permissionStatus => _permissionStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermission => _permissionStatus == LocationPermission.always ||
      _permissionStatus == LocationPermission.whileInUse;

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

  Future<void> checkPermission() async {
    _setLoading(true);
    _setError(null);

    try {
      final permission = await Geolocator.checkPermission();
      _permissionStatus = permission;

      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        _permissionStatus = requested;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Lỗi kiểm tra quyền vị trí: $e');
      _setLoading(false);
    }
  }

  Future<Position?> getCurrentLocation() async {
    if (!hasPermission) {
      await checkPermission();
      if (!hasPermission) {
        _setError('Không có quyền truy cập vị trí');
        return null;
      }
    }

    _setLoading(true);
    _setError(null);

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _setLoading(false);
      return _currentPosition;
    } catch (e) {
      _setError('Không thể lấy vị trí: $e');
      _setLoading(false);
      return null;
    }
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 50, // meters
      ),
    );
  }

  double? calculateDistance(
      double startLat,
      double startLon,
      double endLat,
      double endLon,
      ) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      startLat,
      startLon,
      endLat,
      endLon,
    );
  }
}
