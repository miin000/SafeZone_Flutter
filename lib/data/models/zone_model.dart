import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';

/// Data model for EpidemicZone with JSON serialization
class ZoneModel extends EpidemicZone {
  ZoneModel({
    required super.id,
    required super.name,
    super.description,
    super.diseaseName,
    required super.diseaseType,
    required super.riskLevel,
    required super.latitude,
    required super.longitude,
    required super.radiusMeters,
    super.confirmedCases,
    super.activeCases,
    super.recoveredCases,
    super.deaths,
    required super.reportedAt,
    super.updatedAt,
    super.isActive,
  });

  /// Create from JSON map (API response format)
  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    // Parse coordinates from GeoJSON center point
    // API returns: center: { type: 'Point', coordinates: [lon, lat] }
    double lat = 0;
    double lon = 0;
    
    if (json['center'] != null && json['center']['coordinates'] != null) {
      final coords = json['center']['coordinates'] as List;
      lon = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      // Fallback to direct lat/lon fields
      lat = (json['latitude'] ?? json['lat'] ?? 0).toDouble();
      lon = (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0).toDouble();
    }
    
    // radiusKm from API needs to be converted to meters
    final radiusKm = (json['radiusKm'] ?? json['radius_km'] ?? json['radius'] ?? 1).toDouble();
    final radiusMeters = radiusKm * 1000;

    return ZoneModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      diseaseName: (json['diseaseType'] ?? json['disease_type'] ?? '').toString(),
      diseaseType: _parseDiseaseType(json['diseaseType'] ?? json['disease_type']),
      riskLevel: _parseRiskLevel(json['riskLevel'] ?? json['risk_level']),
      latitude: lat,
      longitude: lon,
      radiusMeters: radiusMeters,
      confirmedCases: json['caseCount'] ?? json['confirmedCases'] ?? json['confirmed_cases'] ?? 0,
      activeCases: json['activeCases'] ?? json['active_cases'] ?? 0,
      recoveredCases: json['recoveredCases'] ?? json['recovered_cases'] ?? 0,
      deaths: json['deaths'] ?? 0,
      reportedAt: _parseDateTime(json['startDate'] ?? json['reportedAt'] ?? json['createdAt']),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? _parseDateTime(json['updatedAt'] ?? json['updated_at'])
          : null,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'diseaseName': diseaseName,
      'diseaseType': diseaseType.name,
      'riskLevel': riskLevel.name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'confirmedCases': confirmedCases,
      'activeCases': activeCases,
      'recoveredCases': recoveredCases,
      'deaths': deaths,
      'reportedAt': reportedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Convert entity to model
  factory ZoneModel.fromEntity(EpidemicZone zone) {
    return ZoneModel(
      id: zone.id,
      name: zone.name,
      description: zone.description,
      diseaseName: zone.diseaseName,
      diseaseType: zone.diseaseType,
      riskLevel: zone.riskLevel,
      latitude: zone.latitude,
      longitude: zone.longitude,
      radiusMeters: zone.radiusMeters,
      confirmedCases: zone.confirmedCases,
      activeCases: zone.activeCases,
      recoveredCases: zone.recoveredCases,
      deaths: zone.deaths,
      reportedAt: zone.reportedAt,
      updatedAt: zone.updatedAt,
      isActive: zone.isActive,
    );
  }

  static DiseaseType _parseDiseaseType(dynamic value) {
    if (value == null) return DiseaseType.other;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'covid19':
      case 'covid-19':
      case 'covid':
        return DiseaseType.covid19;
      case 'dengue':
      case 'sxh':
        return DiseaseType.dengue;
      case 'influenza':
      case 'flu':
      case 'cum':
        return DiseaseType.influenza;
      case 'handfootmouth':
      case 'hand_foot_mouth':
      case 'hfmd':
      case 'tcm':
        return DiseaseType.handFootMouth;
      case 'cholera':
      case 'ta':
        return DiseaseType.cholera;
      default:
        return DiseaseType.other;
    }
  }

  static ZoneRiskLevel _parseRiskLevel(dynamic value) {
    if (value == null) return ZoneRiskLevel.low;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'low':
      case 'thap':
        return ZoneRiskLevel.low;
      case 'medium':
      case 'trungbinh':
        return ZoneRiskLevel.medium;
      case 'high':
      case 'cao':
        return ZoneRiskLevel.high;
      case 'critical':
      case 'nguyhiem':
        return ZoneRiskLevel.critical;
      default:
        return ZoneRiskLevel.low;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}
