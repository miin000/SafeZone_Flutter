// Report Model
import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum ReportStatus { pending, verified, rejected, resolved }

class ReportModel extends Equatable {
  final String id;
  final String diseaseType;
  final String description;
  final double lat;
  final double lon;
  final String? address;
  final List<String> symptoms;
  final int affectedCount;
  final List<String> imageUrls;
  final ReportStatus status;
  final String? adminNote;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final UserModel? user;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportModel({
    required this.id,
    required this.diseaseType,
    required this.description,
    required this.lat,
    required this.lon,
    this.address,
    this.symptoms = const [],
    this.affectedCount = 1,
    this.imageUrls = const [],
    this.status = ReportStatus.pending,
    this.adminNote,
    this.verifiedAt,
    this.verifiedBy,
    this.user,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Parse location from GeoJSON Point format
    double lat = 0;
    double lon = 0;
    
    if (json['location'] != null) {
      final location = json['location'];
      if (location['coordinates'] != null) {
        // GeoJSON format: [longitude, latitude]
        lon = (location['coordinates'][0] as num).toDouble();
        lat = (location['coordinates'][1] as num).toDouble();
      }
    } else {
      lat = (json['lat'] as num?)?.toDouble() ?? 0;
      lon = (json['lon'] as num?)?.toDouble() ?? 0;
    }

    return ReportModel(
      id: json['id'] ?? '',
      diseaseType: json['diseaseType'] ?? '',
      description: json['description'] ?? '',
      lat: lat,
      lon: lon,
      address: json['address'],
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'])
          : [],
      affectedCount: json['affectedCount'] ?? 1,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      status: _parseStatus(json['status']),
      adminNote: json['adminNote'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      verifiedBy: json['verifiedBy'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diseaseType': diseaseType,
      'description': description,
      'lat': lat,
      'lon': lon,
      'address': address,
      'symptoms': symptoms,
      'affectedCount': affectedCount,
      'imageUrls': imageUrls,
      'status': status.name,
      'adminNote': adminNote,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return ReportStatus.verified;
      case 'rejected':
        return ReportStatus.rejected;
      case 'resolved':
        return ReportStatus.resolved;
      default:
        return ReportStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case ReportStatus.pending:
        return 'Chờ xác minh';
      case ReportStatus.verified:
        return 'Đã xác minh';
      case ReportStatus.rejected:
        return 'Bị từ chối';
      case ReportStatus.resolved:
        return 'Đã giải quyết';
    }
  }

  ReportModel copyWith({
    String? id,
    String? diseaseType,
    String? description,
    double? lat,
    double? lon,
    String? address,
    List<String>? symptoms,
    int? affectedCount,
    List<String>? imageUrls,
    ReportStatus? status,
    String? adminNote,
    DateTime? verifiedAt,
    String? verifiedBy,
    UserModel? user,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      diseaseType: diseaseType ?? this.diseaseType,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      address: address ?? this.address,
      symptoms: symptoms ?? this.symptoms,
      affectedCount: affectedCount ?? this.affectedCount,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        diseaseType,
        description,
        lat,
        lon,
        address,
        symptoms,
        affectedCount,
        imageUrls,
        status,
        adminNote,
        verifiedAt,
        verifiedBy,
        userId,
        createdAt,
        updatedAt,
      ];
}

// Create Report Request
class CreateReportRequest {
  final String diseaseType;
  final String description;
  final double lat;
  final double lon;
  final String? address;
  final List<String>? symptoms;
  final int? affectedCount;

  const CreateReportRequest({
    required this.diseaseType,
    required this.description,
    required this.lat,
    required this.lon,
    this.address,
    this.symptoms,
    this.affectedCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'diseaseType': diseaseType,
      'description': description,
      'lat': lat,
      'lon': lon,
      if (address != null) 'address': address,
      if (symptoms != null && symptoms!.isNotEmpty) 'symptoms': symptoms,
      if (affectedCount != null) 'affectedCount': affectedCount,
    };
  }
}
