import 'package:equatable/equatable.dart';

/// Risk level of an epidemic zone
enum ZoneRiskLevel {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case ZoneRiskLevel.low:
        return 'Thấp';
      case ZoneRiskLevel.medium:
        return 'Trung bình';
      case ZoneRiskLevel.high:
        return 'Cao';
      case ZoneRiskLevel.critical:
        return 'Nguy hiểm';
    }
  }
}

/// Disease type for the zone
enum DiseaseType {
  covid19,
  dengue,
  influenza,
  handFootMouth,
  cholera,
  other;

  String get displayName {
    switch (this) {
      case DiseaseType.covid19:
        return 'COVID-19';
      case DiseaseType.dengue:
        return 'Sốt xuất huyết';
      case DiseaseType.influenza:
        return 'Cúm';
      case DiseaseType.handFootMouth:
        return 'Tay chân miệng';
      case DiseaseType.cholera:
        return 'Tả';
      case DiseaseType.other:
        return 'Khác';
    }
  }
}

/// Represents an epidemic/disease outbreak zone
class EpidemicZone extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String diseaseName;
  final DiseaseType diseaseType;
  final ZoneRiskLevel riskLevel;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int confirmedCases;
  final int activeCases;
  final int recoveredCases;
  final int deaths;
  final DateTime reportedAt;
  final DateTime? updatedAt;
  final bool isActive;

  EpidemicZone({
    required this.id,
    required this.name,
    this.description,
    String? diseaseName,
    required this.diseaseType,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.confirmedCases = 0,
    this.activeCases = 0,
    this.recoveredCases = 0,
    this.deaths = 0,
    required this.reportedAt,
    this.updatedAt,
    this.isActive = true,
  }) : diseaseName = diseaseName ?? diseaseType.displayName;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        diseaseName,
        diseaseType,
        riskLevel,
        latitude,
        longitude,
        radiusMeters,
        confirmedCases,
        activeCases,
        recoveredCases,
        deaths,
        reportedAt,
        updatedAt,
        isActive,
      ];

  EpidemicZone copyWith({
    String? id,
    String? name,
    String? description,
    String? diseaseName,
    DiseaseType? diseaseType,
    ZoneRiskLevel? riskLevel,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    int? confirmedCases,
    int? activeCases,
    int? recoveredCases,
    int? deaths,
    DateTime? reportedAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return EpidemicZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      diseaseName: diseaseName ?? this.diseaseName,
      diseaseType: diseaseType ?? this.diseaseType,
      riskLevel: riskLevel ?? this.riskLevel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      confirmedCases: confirmedCases ?? this.confirmedCases,
      activeCases: activeCases ?? this.activeCases,
      recoveredCases: recoveredCases ?? this.recoveredCases,
      deaths: deaths ?? this.deaths,
      reportedAt: reportedAt ?? this.reportedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
