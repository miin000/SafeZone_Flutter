import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus { initial, loading, loaded, denied, error }

class LocationProvider extends ChangeNotifier {
  LocationStatus _status = LocationStatus.initial;
  Position? _currentPosition;
  String? _errorMessage;
  bool _isTracking = false;

  // Getters
  LocationStatus get status => _status;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;
  bool get isTracking => _isTracking;

  // Get LatLng for flutter_map
  LatLng? get currentLatLng {
    if (_currentPosition == null) return null;
    return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  }

  // Default location (Hanoi, Vietnam)
  static const LatLng defaultLocation = LatLng(21.0285, 105.8542);

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _status = LocationStatus.error;
      _errorMessage = 'Dịch vụ định vị đang tắt. Vui lòng bật GPS.';
      notifyListeners();
      return false;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _status = LocationStatus.denied;
        _errorMessage = 'Quyền truy cập vị trí bị từ chối';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _status = LocationStatus.denied;
      _errorMessage = 'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt.';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    _status = LocationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _status = LocationStatus.loaded;
      debugPrint('Location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } catch (e) {
      _status = LocationStatus.error;
      _errorMessage = 'Không thể lấy vị trí: $e';
      debugPrint('Error getting location: $e');
    }

    notifyListeners();
  }

  /// Start tracking location
  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    notifyListeners();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _currentPosition = position;
        _status = LocationStatus.loaded;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location tracking error: $error');
        _errorMessage = 'Lỗi theo dõi vị trí: $error';
        notifyListeners();
      },
    );
  }

  /// Stop tracking location
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  /// Calculate distance between current location and a point
  double? distanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  /// Check if current location is within a radius of a point
  bool isWithinRadius(double latitude, double longitude, double radiusMeters) {
    final distance = distanceTo(latitude, longitude);
    if (distance == null) return false;
    return distance <= radiusMeters;
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Clear location data
  void clear() {
    _currentPosition = null;
    _status = LocationStatus.initial;
    _errorMessage = null;
    _isTracking = false;
    notifyListeners();
  }
}
