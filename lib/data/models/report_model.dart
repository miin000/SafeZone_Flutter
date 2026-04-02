// Report Model
import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum ReportStatus {
  submitted,
  autoVerified,
  underReview,
  fieldVerification,
  confirmed,
  rejected,
  closed,
  // Backward compat
  pending,
  verified,
  resolved,
}

enum ReportType { caseReport, outbreakAlert }

enum SeverityLevel { low, medium, high, critical }

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
  // Enhanced fields
  final ReportType reportType;
  final SeverityLevel severityLevel;
  final bool isDetailedReport;
  final bool isSelfReport;
  final String? reporterName;
  final String? reporterPhone;
  final PatientInfo? patientInfo;
  // Epidemiological info
  final bool? hasContactWithPatient;
  final bool? hasVisitedEpidemicArea;
  final bool? hasSimilarCasesNearby;
  final int? estimatedNearbyCount;
  // Medical info
  final bool? hasVisitedDoctor;
  final bool? hasTestResult;
  final String? testResultDescription;
  final List<String>? testResultImageUrls;
  final List<String>? medicalCertImageUrls;
  // Outbreak fields
  final String? locationDescription;
  final String? locationType;
  final String? suspectedDisease;
  final String? outbreakDescription;
  final DateTime? discoveryTime;
  // Multi-step verification tracking
  final DateTime? autoVerifiedAt;
  final String? preliminaryReviewBy;
  final DateTime? preliminaryReviewAt;
  final String? preliminaryReviewResult;
  final String? preliminaryReviewNote;
  final String? fieldVerifierId;
  final DateTime? fieldVerifiedAt;
  final String? fieldVerificationResult;
  final String? fieldVerificationNote;
  final String? officialConfirmBy;
  final DateTime? officialConfirmAt;
  final String? officialClassification;
  final String? officialConfirmNote;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closureAction;
  final String? closureNote;
  final bool reporterConsent;

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
    this.status = ReportStatus.submitted,
    this.adminNote,
    this.verifiedAt,
    this.verifiedBy,
    this.user,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.reportType = ReportType.caseReport,
    this.severityLevel = SeverityLevel.medium,
    this.isDetailedReport = false,
    this.isSelfReport = true,
    this.reporterName,
    this.reporterPhone,
    this.patientInfo,
    this.hasContactWithPatient,
    this.hasVisitedEpidemicArea,
    this.hasSimilarCasesNearby,
    this.estimatedNearbyCount,
    this.hasVisitedDoctor,
    this.hasTestResult,
    this.testResultDescription,
    this.testResultImageUrls,
    this.medicalCertImageUrls,
    this.locationDescription,
    this.locationType,
    this.suspectedDisease,
    this.outbreakDescription,
    this.discoveryTime,
    this.autoVerifiedAt,
    this.preliminaryReviewBy,
    this.preliminaryReviewAt,
    this.preliminaryReviewResult,
    this.preliminaryReviewNote,
    this.fieldVerifierId,
    this.fieldVerifiedAt,
    this.fieldVerificationResult,
    this.fieldVerificationNote,
    this.officialConfirmBy,
    this.officialConfirmAt,
    this.officialClassification,
    this.officialConfirmNote,
    this.closedAt,
    this.closedBy,
    this.closureAction,
    this.closureNote,
    this.reporterConsent = false,
  });

  static DateTime _parseServerDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final value = raw.toString().trim();
    if (value.isEmpty) return DateTime.now();

    final normalizedForParse = value.contains(' ')
        ? value.replaceFirst(' ', 'T')
        : value;

    final hasTimezone =
        normalizedForParse.endsWith('Z') ||
        RegExp(r'([+-]\d{2}:?\d{2})$').hasMatch(normalizedForParse);
    try {
      if (hasTimezone) {
        return DateTime.parse(normalizedForParse).toLocal();
      }

      // Some endpoints return timezone-less UTC strings while others return
      // timezone-less local strings. Pick the interpretation closer to "now"
      // to avoid fixed offsets such as 7 hours.
      final localCandidate = DateTime.parse(normalizedForParse);
      final utcCandidate = DateTime.parse('${normalizedForParse}Z').toLocal();
      final now = DateTime.now();
      final localDelta = now.difference(localCandidate).abs();
      final utcDelta = now.difference(utcCandidate).abs();

      return utcDelta <= localDelta ? utcCandidate : localCandidate;
    } catch (_) {
      return DateTime.now();
    }
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Parse location from GeoJSON Point format
    double lat = 0;
    double lon = 0;

    if (json['location'] != null) {
      final location = json['location'];
      if (location['coordinates'] != null) {
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
          ? _parseServerDate(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? _parseServerDate(json['updatedAt'])
          : DateTime.now(),
      reportType: _parseReportType(json['reportType']),
      severityLevel: _parseSeverity(json['severityLevel']),
      isDetailedReport: json['isDetailedReport'] ?? false,
      isSelfReport: json['isSelfReport'] ?? true,
      reporterName: json['reporterName'],
      reporterPhone: json['reporterPhone'],
      patientInfo: json['patientInfo'] != null
          ? PatientInfo.fromJson(json['patientInfo'])
          : null,
      hasContactWithPatient: json['hasContactWithPatient'],
      hasVisitedEpidemicArea: json['hasVisitedEpidemicArea'],
      hasSimilarCasesNearby: json['hasSimilarCasesNearby'],
      estimatedNearbyCount: json['estimatedNearbyCount'],
      hasVisitedDoctor: json['hasVisitedDoctor'],
      hasTestResult: json['hasTestResult'],
      testResultDescription: json['testResultDescription'],
      testResultImageUrls: json['testResultImageUrls'] != null
          ? List<String>.from(json['testResultImageUrls'])
          : null,
      medicalCertImageUrls: json['medicalCertImageUrls'] != null
          ? List<String>.from(json['medicalCertImageUrls'])
          : null,
      locationDescription: json['locationDescription'],
      locationType: json['locationType'],
      suspectedDisease: json['suspectedDisease'],
      outbreakDescription: json['outbreakDescription'],
      discoveryTime: json['discoveryTime'] != null
          ? DateTime.tryParse(json['discoveryTime'])
          : null,
      autoVerifiedAt: json['autoVerifiedAt'] != null
          ? DateTime.tryParse(json['autoVerifiedAt'])
          : null,
      preliminaryReviewBy: json['preliminaryReviewBy'],
      preliminaryReviewAt: json['preliminaryReviewAt'] != null
          ? DateTime.tryParse(json['preliminaryReviewAt'])
          : null,
      preliminaryReviewResult: json['preliminaryReviewResult'],
      preliminaryReviewNote: json['preliminaryReviewNote'],
      fieldVerifierId: json['fieldVerifierId'],
      fieldVerifiedAt: json['fieldVerifiedAt'] != null
          ? DateTime.tryParse(json['fieldVerifiedAt'])
          : null,
      fieldVerificationResult: json['fieldVerificationResult'],
      fieldVerificationNote: json['fieldVerificationNote'],
      officialConfirmBy: json['officialConfirmBy'],
      officialConfirmAt: json['officialConfirmAt'] != null
          ? DateTime.tryParse(json['officialConfirmAt'])
          : null,
      officialClassification: json['officialClassification'],
      officialConfirmNote: json['officialConfirmNote'],
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'])
          : null,
      closedBy: json['closedBy'],
      closureAction: json['closureAction'],
      closureNote: json['closureNote'],
      reporterConsent: json['reporterConsent'] ?? false,
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
      'reportType': reportType == ReportType.outbreakAlert
          ? 'outbreak_alert'
          : 'case_report',
      'severityLevel': severityLevel.name,
      'isDetailedReport': isDetailedReport,
      'isSelfReport': isSelfReport,
      'reporterConsent': reporterConsent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'auto_verified':
        return ReportStatus.autoVerified;
      case 'under_review':
        return ReportStatus.underReview;
      case 'field_verification':
        return ReportStatus.fieldVerification;
      case 'confirmed':
        return ReportStatus.confirmed;
      case 'rejected':
        return ReportStatus.rejected;
      case 'closed':
        return ReportStatus.closed;
      case 'verified':
        return ReportStatus.verified;
      case 'resolved':
        return ReportStatus.resolved;
      case 'pending':
      default:
        return ReportStatus.pending;
    }
  }

  static ReportType _parseReportType(String? type) {
    switch (type) {
      case 'outbreak_alert':
        return ReportType.outbreakAlert;
      case 'case_report':
      default:
        return ReportType.caseReport;
    }
  }

  static SeverityLevel _parseSeverity(String? level) {
    switch (level) {
      case 'low':
        return SeverityLevel.low;
      case 'high':
        return SeverityLevel.high;
      case 'critical':
        return SeverityLevel.critical;
      case 'medium':
      default:
        return SeverityLevel.medium;
    }
  }

  String get statusText {
    switch (status) {
      case ReportStatus.submitted:
        return 'Đã gửi';
      case ReportStatus.autoVerified:
        return 'Đã xác nhận tự động';
      case ReportStatus.underReview:
        return 'Đang xem xét';
      case ReportStatus.fieldVerification:
        return 'Kiểm tra thực địa';
      case ReportStatus.confirmed:
        return 'Đã xác nhận';
      case ReportStatus.rejected:
        return 'Bị từ chối';
      case ReportStatus.closed:
        return 'Đã đóng';
      case ReportStatus.pending:
        return 'Chờ xác minh';
      case ReportStatus.verified:
        return 'Đã xác minh';
      case ReportStatus.resolved:
        return 'Đã giải quyết';
    }
  }

  String get reportTypeText {
    switch (reportType) {
      case ReportType.caseReport:
        return 'Báo cáo ca bệnh';
      case ReportType.outbreakAlert:
        return 'Cảnh báo ổ dịch';
    }
  }

  String get severityText {
    switch (severityLevel) {
      case SeverityLevel.low:
        return 'Thấp';
      case SeverityLevel.medium:
        return 'Trung bình';
      case SeverityLevel.high:
        return 'Cao';
      case SeverityLevel.critical:
        return 'Nghiêm trọng';
    }
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
    reportType,
    severityLevel,
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
  final double? reporterLat;
  final double? reporterLon;
  final String? address;
  final List<String>? symptoms;
  final int? affectedCount;
  final bool isDetailedReport;
  final PatientInfo? patientInfo;
  // New fields
  final String reportType; // 'case_report' or 'outbreak_alert'
  final String severityLevel; // 'low', 'medium', 'high', 'critical'
  final bool isSelfReport;
  final String? reporterName;
  final String? reporterPhone;
  final bool reporterConsent;
  final String? deviceId;
  // Epidemiological info
  final bool? hasContactWithPatient;
  final bool? hasVisitedEpidemicArea;
  final bool? hasSimilarCasesNearby;
  final int? estimatedNearbyCount;
  // Medical info
  final bool? hasVisitedDoctor;
  final bool? hasTestResult;
  final String? testResultDescription;
  final List<String>? testResultImageUrls;
  final List<String>? medicalCertImageUrls;
  // Outbreak fields
  final String? locationDescription;
  final String? locationType;
  final String? suspectedDisease;
  final String? outbreakDescription;
  final String? discoveryTime;

  const CreateReportRequest({
    required this.diseaseType,
    required this.description,
    required this.lat,
    required this.lon,
    this.reporterLat,
    this.reporterLon,
    this.address,
    this.symptoms,
    this.affectedCount,
    this.isDetailedReport = false,
    this.patientInfo,
    this.reportType = 'case_report',
    this.severityLevel = 'medium',
    this.isSelfReport = true,
    this.reporterName,
    this.reporterPhone,
    this.reporterConsent = false,
    this.deviceId,
    this.hasContactWithPatient,
    this.hasVisitedEpidemicArea,
    this.hasSimilarCasesNearby,
    this.estimatedNearbyCount,
    this.hasVisitedDoctor,
    this.hasTestResult,
    this.testResultDescription,
    this.testResultImageUrls,
    this.medicalCertImageUrls,
    this.locationDescription,
    this.locationType,
    this.suspectedDisease,
    this.outbreakDescription,
    this.discoveryTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'diseaseType': diseaseType,
      'description': description,
      'lat': lat,
      'lon': lon,
      if (reporterLat != null) 'reporterLat': reporterLat,
      if (reporterLon != null) 'reporterLon': reporterLon,
      if (address != null) 'address': address,
      if (symptoms != null && symptoms!.isNotEmpty) 'symptoms': symptoms,
      if (affectedCount != null) 'affectedCount': affectedCount,
      'isDetailedReport': isDetailedReport,
      if (patientInfo != null) 'patientInfo': patientInfo!.toJson(),
      'reportType': reportType,
      'severityLevel': severityLevel,
      'isSelfReport': isSelfReport,
      if (reporterName != null) 'reporterName': reporterName,
      if (reporterPhone != null) 'reporterPhone': reporterPhone,
      'reporterConsent': reporterConsent,
      if (deviceId != null) 'deviceId': deviceId,
      if (hasContactWithPatient != null)
        'hasContactWithPatient': hasContactWithPatient,
      if (hasVisitedEpidemicArea != null)
        'hasVisitedEpidemicArea': hasVisitedEpidemicArea,
      if (hasSimilarCasesNearby != null)
        'hasSimilarCasesNearby': hasSimilarCasesNearby,
      if (estimatedNearbyCount != null)
        'estimatedNearbyCount': estimatedNearbyCount,
      if (hasVisitedDoctor != null) 'hasVisitedDoctor': hasVisitedDoctor,
      if (hasTestResult != null) 'hasTestResult': hasTestResult,
      if (testResultDescription != null)
        'testResultDescription': testResultDescription,
      if (testResultImageUrls != null && testResultImageUrls!.isNotEmpty)
        'testResultImageUrls': testResultImageUrls,
      if (medicalCertImageUrls != null && medicalCertImageUrls!.isNotEmpty)
        'medicalCertImageUrls': medicalCertImageUrls,
      if (locationDescription != null)
        'locationDescription': locationDescription,
      if (locationType != null) 'locationType': locationType,
      if (suspectedDisease != null) 'suspectedDisease': suspectedDisease,
      if (outbreakDescription != null)
        'outbreakDescription': outbreakDescription,
      if (discoveryTime != null) 'discoveryTime': discoveryTime,
    };
  }
}

/// Detailed patient information for case reports
class PatientInfo {
  final String? fullName;
  final int? age;
  final int? yearOfBirth;
  final String? gender; // 'male', 'female', 'other'
  final String? idNumber;
  final String? phone;
  final String? address;
  final String? occupation;
  final String? workplace;
  final DateTime? symptomOnsetDate;
  final String? healthFacility;
  final bool isHospitalized;
  final String? travelHistory;
  final String? contactHistory;
  final List<String>? underlyingConditions;

  const PatientInfo({
    this.fullName,
    this.age,
    this.yearOfBirth,
    this.gender,
    this.idNumber,
    this.phone,
    this.address,
    this.occupation,
    this.workplace,
    this.symptomOnsetDate,
    this.healthFacility,
    this.isHospitalized = false,
    this.travelHistory,
    this.contactHistory,
    this.underlyingConditions,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null && fullName!.isNotEmpty) 'fullName': fullName,
      if (age != null) 'age': age,
      if (yearOfBirth != null) 'yearOfBirth': yearOfBirth,
      if (gender != null) 'gender': gender,
      if (idNumber != null && idNumber!.isNotEmpty) 'idNumber': idNumber,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (occupation != null && occupation!.isNotEmpty)
        'occupation': occupation,
      if (workplace != null && workplace!.isNotEmpty) 'workplace': workplace,
      if (symptomOnsetDate != null)
        'symptomOnsetDate': symptomOnsetDate!.toIso8601String(),
      if (healthFacility != null && healthFacility!.isNotEmpty)
        'healthFacility': healthFacility,
      'isHospitalized': isHospitalized,
      if (travelHistory != null && travelHistory!.isNotEmpty)
        'travelHistory': travelHistory,
      if (contactHistory != null && contactHistory!.isNotEmpty)
        'contactHistory': contactHistory,
      if (underlyingConditions != null && underlyingConditions!.isNotEmpty)
        'underlyingConditions': underlyingConditions,
    };
  }

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      fullName: json['fullName'],
      age: json['age'],
      yearOfBirth: json['yearOfBirth'],
      gender: json['gender'],
      idNumber: json['idNumber'],
      phone: json['phone'],
      address: json['address'],
      occupation: json['occupation'],
      workplace: json['workplace'],
      symptomOnsetDate: json['symptomOnsetDate'] != null
          ? DateTime.tryParse(json['symptomOnsetDate'])
          : null,
      healthFacility: json['healthFacility'],
      isHospitalized: json['isHospitalized'] ?? false,
      travelHistory: json['travelHistory'],
      contactHistory: json['contactHistory'],
      underlyingConditions: json['underlyingConditions'] != null
          ? List<String>.from(json['underlyingConditions'])
          : null,
    );
  }
}
