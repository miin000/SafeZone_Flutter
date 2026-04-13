import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/zone_alert_audio_service.dart';
import '../../data/models/report_model.dart';
import '../providers/zone_provider.dart';
import '../providers/location_provider.dart';
import '../../domain/entities/epidemic_zone.dart';
import '../screens/map/zone_list_screen.dart';

/// A persistent warning banner displayed when user is inside an epidemic zone
class ZoneWarningBanner extends StatefulWidget {
  const ZoneWarningBanner({super.key});

  @override
  State<ZoneWarningBanner> createState() => _ZoneWarningBannerState();
}

class _ZoneWarningBannerState extends State<ZoneWarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;
  bool _isCheckingNearbyCases = false;
  DateTime? _lastNearbyCaseCheckAt;
  String? _lastNearbyLocationKey;
  List<ReportModel> _nearbyCaseReports = const [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    ZoneAlertAudioService.instance.stop();
    super.dispose();
  }

  /// Check if user's current location is within any epidemic zone
  List<EpidemicZone> _getZonesContainingUser(
    LatLng? userLocation,
    List<EpidemicZone> zones,
  ) {
    if (userLocation == null) return [];

    final Distance distance = const Distance();
    final List<EpidemicZone> containingZones = [];

    for (final zone in zones) {
      if (!zone.isActive) continue;

      final zoneCenter = LatLng(zone.latitude, zone.longitude);
      final distanceToZone = distance.as(
        LengthUnit.Meter,
        userLocation,
        zoneCenter,
      );

      if (distanceToZone <= zone.radiusMeters) {
        containingZones.add(zone);
      }
    }

    // Sort by risk level (critical first)
    containingZones.sort((a, b) {
      const order = {
        ZoneRiskLevel.critical: 0,
        ZoneRiskLevel.high: 1,
        ZoneRiskLevel.medium: 2,
        ZoneRiskLevel.low: 3,
      };
      return (order[a.riskLevel] ?? 4).compareTo(order[b.riskLevel] ?? 4);
    });

    return containingZones;
  }

  Color _getBannerColor(ZoneRiskLevel riskLevel) {
    switch (riskLevel) {
      case ZoneRiskLevel.critical:
        return Colors.red.shade700;
      case ZoneRiskLevel.high:
        return Colors.orange.shade700;
      case ZoneRiskLevel.medium:
        return Colors.amber.shade700;
      case ZoneRiskLevel.low:
        return Colors.yellow.shade700;
    }
  }

  IconData _getRiskIcon(ZoneRiskLevel riskLevel) {
    switch (riskLevel) {
      case ZoneRiskLevel.critical:
        return Icons.warning_rounded;
      case ZoneRiskLevel.high:
        return Icons.error_outline;
      case ZoneRiskLevel.medium:
        return Icons.info_outline;
      case ZoneRiskLevel.low:
        return Icons.notification_important_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationProvider, ZoneProvider>(
      builder: (context, locationProvider, zoneProvider, child) {
        final userLocation = locationProvider.currentLatLng;
        final zones = zoneProvider.activeZones;

        final containingZones = _getZonesContainingUser(userLocation, zones);

        if (userLocation != null) {
          _scheduleNearbyCaseCheck(userLocation);
        }

        if (containingZones.isEmpty && _nearbyCaseReports.isEmpty) {
          return const SizedBox.shrink();
        }

        if (containingZones.isEmpty && _nearbyCaseReports.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ZoneAlertAudioService.instance.announceHighestRisk(
              highestRisk: ZoneRiskLevel.medium,
              zoneCount: _nearbyCaseReports.length,
            );
          });

          final nearestDistanceKm = _nearestCaseDistanceKm(userLocation, _nearbyCaseReports);
          final caseCount = _nearbyCaseReports.length;
          return Material(
            elevation: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Có $caseCount ca bệnh trong bán kính 5km${nearestDistanceKm == null ? '' : ' (gần nhất ${nearestDistanceKm.toStringAsFixed(1)}km)'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final highestRiskZone = containingZones.first;
        final bannerColor = _getBannerColor(highestRiskZone.riskLevel);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ZoneAlertAudioService.instance.announceHighestRisk(
            highestRisk: highestRiskZone.riskLevel,
            zoneCount: containingZones.length,
          );
        });

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: highestRiskZone.riskLevel == ZoneRiskLevel.critical
                  ? _pulseAnimation.value
                  : 1.0,
              child: child,
            );
          },
          child: Material(
            elevation: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    bannerColor,
                    bannerColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getRiskIcon(highestRiskZone.riskLevel),
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getWarningTitle(highestRiskZone.riskLevel),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bạn đang ở trong ${containingZones.length} vùng dịch',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                          ],
                        ),

                        // Expanded details
                        if (_isExpanded) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          ...containingZones
                              .take(3)
                              .map((zone) => _buildZoneInfo(zone)),
                          if (containingZones.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${containingZones.length - 3} vùng dịch khác',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          _buildSafetyTips(highestRiskZone),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ZoneListScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Xem chi tiết vùng dịch'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _scheduleNearbyCaseCheck(LatLng userLocation) async {
    if (_isCheckingNearbyCases) return;

    final locationKey =
        '${userLocation.latitude.toStringAsFixed(3)}_${userLocation.longitude.toStringAsFixed(3)}';
    final now = DateTime.now();
    final recentlyChecked = _lastNearbyCaseCheckAt != null &&
        now.difference(_lastNearbyCaseCheckAt!).inSeconds < 30;
    if (recentlyChecked && locationKey == _lastNearbyLocationKey) return;

    _isCheckingNearbyCases = true;
    _lastNearbyLocationKey = locationKey;
    _lastNearbyCaseCheckAt = now;
    try {
      final response = await ApiClient.instance.get(
        ApiConstants.reportsNearby,
        queryParameters: {
          'lat': userLocation.latitude,
          'lon': userLocation.longitude,
          'radius': 5,
        },
      );
      final raw = response.data;
      final list = raw is List
          ? raw
          : raw is Map<String, dynamic>
              ? (raw['data'] ?? raw['items'] ?? []) as List<dynamic>
              : <dynamic>[];
      final reports = list
          .whereType<Map<String, dynamic>>()
          .map(ReportModel.fromJson)
          .where((r) => r.reportType == ReportType.caseReport)
          .toList();
      if (mounted) {
        setState(() {
          _nearbyCaseReports = reports;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearbyCaseReports = const [];
        });
      }
    } finally {
      _isCheckingNearbyCases = false;
    }
  }

  double? _nearestCaseDistanceKm(LatLng? userLocation, List<ReportModel> reports) {
    if (userLocation == null || reports.isEmpty) return null;
    final distance = const Distance();
    var minMeters = double.infinity;
    for (final report in reports) {
      final casePoint = LatLng(report.lat, report.lon);
      final meters = distance.as(LengthUnit.Meter, userLocation, casePoint);
      if (meters < minMeters) {
        minMeters = meters;
      }
    }
    return minMeters.isFinite ? minMeters / 1000 : null;
  }

  String _getWarningTitle(ZoneRiskLevel riskLevel) {
    switch (riskLevel) {
      case ZoneRiskLevel.critical:
        return '⚠️ CẢNH BÁO NGUY HIỂM!';
      case ZoneRiskLevel.high:
        return '⚠️ Cảnh báo vùng dịch!';
      case ZoneRiskLevel.medium:
        return '⚠️ Vùng có dịch bệnh';
      case ZoneRiskLevel.low:
        return 'ℹ️ Thông báo vùng dịch';
    }
  }

  Widget _buildZoneInfo(EpidemicZone zone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getBannerColor(zone.riskLevel),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${zone.diseaseName} • ${zone.activeCases} ca đang điều trị',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              zone.riskLevel.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTips(EpidemicZone zone) {
    final tips = _getSafetyTips(zone.diseaseType, zone.riskLevel);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛡️ Khuyến cáo phòng dịch:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSafetyTips(DiseaseType diseaseType, ZoneRiskLevel riskLevel) {
    switch (diseaseType) {
      case DiseaseType.dengue:
        return [
          'Diệt muỗi, lăng quăng, không để nước đọng',
          'Mặc quần áo dài tay, sử dụng kem chống muỗi',
          'Ngủ màn kể cả ban ngày',
          'Nếu sốt cao, đau đầu, đau cơ: đi khám ngay',
        ];
      case DiseaseType.covid19:
        return [
          'Đeo khẩu trang khi ra ngoài',
          'Rửa tay thường xuyên bằng xà phòng',
          'Giữ khoảng cách tối thiểu 2m',
          'Tránh tụ tập đông người',
        ];
      case DiseaseType.handFootMouth:
        return [
          'Rửa tay sạch sẽ, đặc biệt trước khi ăn',
          'Vệ sinh đồ chơi, dụng cụ của trẻ',
          'Không cho trẻ tiếp xúc với người bệnh',
          'Theo dõi triệu chứng: sốt, nổi mụn nước',
        ];
      case DiseaseType.influenza:
        return [
          'Che miệng khi ho, hắt hơi',
          'Rửa tay thường xuyên',
          'Tránh tiếp xúc người bệnh',
          'Uống đủ nước, nghỉ ngơi đầy đủ',
        ];
      case DiseaseType.cholera:
        return [
          'Uống nước đun sôi để nguội',
          'Ăn chín uống sôi',
          'Rửa tay trước khi ăn và sau khi đi vệ sinh',
          'Xử lý phân, rác đúng cách',
        ];
      default:
        return [
          'Thực hiện vệ sinh cá nhân tốt',
          'Theo dõi sức khỏe, đi khám nếu có triệu chứng',
          'Tuân thủ hướng dẫn của cơ quan y tế',
        ];
    }
  }
}
