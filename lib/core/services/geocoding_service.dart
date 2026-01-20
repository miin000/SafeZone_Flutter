// Geocoding Service - Converts coordinates to addresses
import '../network/api_client.dart';

class GeocodingService {
  static GeocodingService? _instance;
  final ApiClient _apiClient;

  GeocodingService._() : _apiClient = ApiClient.instance;

  static GeocodingService get instance {
    _instance ??= GeocodingService._();
    return _instance!;
  }

  /// Reverse geocode coordinates to get address (commune, district, province)
  /// Returns a formatted address string
  Future<ReverseGeocodeResult> reverseGeocode(double lat, double lon) async {
    try {
      final response = await _apiClient.get(
        '/gis/reverse-geocode',
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return ReverseGeocodeResult.fromJson(response.data);
      }
    } catch (e) {
      print('Reverse geocode error: $e');
    }

    // Fallback: return coordinates as address
    return ReverseGeocodeResult(
      address: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
    );
  }
}

class ReverseGeocodeResult {
  final String address;
  final String? commune;
  final String? district;
  final String? province;
  final int? regionId;

  ReverseGeocodeResult({
    required this.address,
    this.commune,
    this.district,
    this.province,
    this.regionId,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      address: json['address'] ?? '',
      commune: json['commune'],
      district: json['district'],
      province: json['province'],
      regionId: json['regionId'],
    );
  }

  /// Get formatted address string (commune, district, province)
  String get formattedAddress {
    final parts = <String>[];
    if (commune != null && commune!.isNotEmpty) parts.add(commune!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    return parts.isNotEmpty ? parts.join(', ') : address;
  }
}
