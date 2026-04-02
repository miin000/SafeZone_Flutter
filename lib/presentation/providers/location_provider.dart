import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

enum LocationStatus { initial, loading, loaded, denied, error }

class LocationProvider extends ChangeNotifier {
  LocationStatus _status = LocationStatus.initial;
  Position? _currentPosition;
  String? _errorMessage;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _retryTimer;

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

  bool _isPositionFreshEnough(Position position, {int maxAgeMinutes = 3}) {
    final age = DateTime.now().difference(position.timestamp);
    return age.inMinutes <= maxAgeMinutes;
  }

  bool _isPositionAccurateEnough(Position position, {double maxMeters = 60}) {
    return position.accuracy <= maxMeters;
  }

  Future<Position?> _waitForBetterPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    );

    try {
      return await stream
          .firstWhere((p) => _isPositionAccurateEnough(p, maxMeters: 50))
          .timeout(timeout);
    } catch (_) {
      return null;
    }
  }

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
      _errorMessage =
          'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt.';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    // Keep previously known location while refreshing in background.
    if (_currentPosition == null) {
      _status = LocationStatus.loading;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final current = _currentPosition;
      if (current != null &&
          (!_isPositionFreshEnough(current) ||
              !_isPositionAccurateEnough(current))) {
        final better = await _waitForBetterPosition();
        if (better != null) {
          _currentPosition = better;
        }
      }

      _status = LocationStatus.loaded;
      debugPrint(
        'Location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
      );
    } catch (e) {
      _status = LocationStatus.error;
      _errorMessage = 'Không thể lấy vị trí: $e';
      debugPrint('Error getting location: $e');
    }

    notifyListeners();
  }

  /// Start tracking location
  Future<void> startTracking() async {
    if (_isTracking && _positionSubscription != null) return;

    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    await _positionSubscription?.cancel();
    _isTracking = true;
    notifyListeners();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Update every 20 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _currentPosition = position;
            _status = LocationStatus.loaded;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Location tracking error: $error');
            _errorMessage = 'Lỗi theo dõi vị trí: $error';
            _status = _currentPosition != null
                ? LocationStatus.loaded
                : LocationStatus.error;
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 3), () {
              if (_isTracking) {
                startTracking();
              }
            });
            notifyListeners();
          },
        );
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
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
    _retryTimer?.cancel();
    _retryTimer = null;
    _currentPosition = null;
    _status = LocationStatus.initial;
    _errorMessage = null;
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
