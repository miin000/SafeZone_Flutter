import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum RiskLevel {
  high,    // Đỏ: >100 ca
  medium,  // Cam: 50-100 ca
  low,     // Vàng: 20-50 ca
  safe,    // Xanh: <20 ca
}

class ZoneModel extends Equatable {
  final String id;
  final String name;
  final String diseaseType;
  final RiskLevel riskLevel;
  final int caseCount;
  final double lat;
  final double lon;
  final double radius; // in meters
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.diseaseType,
    required this.riskLevel,
    required this.caseCount,
    required this.lat,
    required this.lon,
    required this.radius,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    // Parse location
    double lat = (json['lat'] as num?)?.toDouble() ?? 0;
    double lon = (json['lon'] as num?)?.toDouble() ?? 0;
    double radius = (json['radius'] as num?)?.toDouble() ?? 0;

    return ZoneModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      diseaseType: json['diseaseType'] ?? '',
      riskLevel: _parseRiskLevel(json['riskLevel']),
      caseCount: json['caseCount'] ?? 0,
      lat: lat,
      lon: lon,
      radius: radius,
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'diseaseType': diseaseType,
      'riskLevel': riskLevel.name,
      'caseCount': caseCount,
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static RiskLevel _parseRiskLevel(String? level) {
    switch (level) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      case 'low':
        return RiskLevel.low;
      default:
        return RiskLevel.safe;
    }
  }

  Color get color {
    switch (riskLevel) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.low:
        return Colors.yellow;
      case RiskLevel.safe:
        return Colors.green;
    }
  }

  String get riskText {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'Nguy hiểm cao';
      case RiskLevel.medium:
        return 'Nguy hiểm';
      case RiskLevel.low:
        return 'Cảnh báo';
      case RiskLevel.safe:
        return 'An toàn';
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    diseaseType,
    riskLevel,
    caseCount,
    lat,
    lon,
    radius,
    isActive,
    createdAt,
  ];
}