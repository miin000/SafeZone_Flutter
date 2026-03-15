// Zone Alert Service - Checks if user is in danger zone
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/remote/zone_remote_datasource.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class ZoneAlertService {
  static final ZoneAlertService _instance = ZoneAlertService._internal();
  factory ZoneAlertService() => _instance;
  ZoneAlertService._internal();

  final ApiClient _apiClient = ApiClient.instance;
  
  Timer? _locationCheckTimer;
  Position? _lastPosition;
  bool _isMonitoring = false;
  
  // Callbacks
  Function(List<dynamic> zones)? onEnterZone;
  Function()? onExitZone;

  bool get isMonitoring => _isMonitoring;

  /// Start monitoring user location for zone entry
  Future<void> startMonitoring({Duration interval = const Duration(minutes: 1)}) async {
    if (_isMonitoring) return;

    // Check location permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permission denied, cannot monitor zones');
      return;
    }

    _isMonitoring = true;
    debugPrint('🔍 Started zone monitoring (interval: ${interval.inSeconds}s)');

    // Initial check
    await _checkCurrentLocation();

    // Periodic check
    _locationCheckTimer = Timer.periodic(interval, (_) => _checkCurrentLocation());
  }

  /// Stop monitoring
  void stopMonitoring() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;
    _isMonitoring = false;
    debugPrint('⏹️ Stopped zone monitoring');
  }

  /// Check current location against danger zones
  Future<void> _checkCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if position changed significantly (more than 50 meters)
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        if (distance < 50) {
          debugPrint('📍 Position unchanged, skipping zone check');
          return;
        }
      }

      _lastPosition = position;
      await checkLocationAndAlert(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Failed to get location: $e');
    }
  }

  /// Check location against zones and send alert if in danger zone
  Future<Map<String, dynamic>> checkLocationAndAlert(double lat, double lon) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.zonesCheckLocation,
        data: {'lat': lat, 'lon': lon},
      );

      final data = response.data;
      final bool inZone = data['inZone'] ?? false;
      final zones = data['zones'] as List? ?? [];

      if (inZone && zones.isNotEmpty) {
        debugPrint('⚠️ User entered danger zone: ${zones.first['name']}');
        onEnterZone?.call(zones);
      }

      return data;
    } catch (e) {
      debugPrint('❌ Failed to check zone: $e');
      return {'inZone': false, 'zones': []};
    }
  }

  /// Check location without auth (public endpoint)
  Future<Map<String, dynamic>> checkLocation(double lat, double lon) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.zonesCheck}?lat=$lat&lon=$lon',
      );

      return response.data;
    } catch (e) {
      debugPrint('❌ Failed to check zone: $e');
      return {'inZone': false, 'zones': []};
    }
  }
}
