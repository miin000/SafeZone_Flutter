import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';
import 'package:mobile_flutter/presentation/providers/auth_provider.dart';
import 'package:mobile_flutter/presentation/providers/zone_provider.dart';
import 'package:mobile_flutter/presentation/providers/location_provider.dart';
import 'zone_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();
  bool _showLegend = true;
  String? _selectedDiseaseFilter;
  bool _casesLoading = false;
  List<_MapCase> _cases = [];
  late final AnimationController _dangerPulseController;
  late final Animation<double> _dangerPulseScale;
  ZoneRiskLevel? _activeDangerRisk;

  @override
  void initState() {
    super.initState();
    _dangerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _dangerPulseScale = Tween<double>(begin: 0.92, end: 1.2).animate(
      CurvedAnimation(
        parent: _dangerPulseController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    final locationProvider = context.read<LocationProvider>();
    final zoneProvider = context.read<ZoneProvider>();

    // Load map data in parallel to reduce first-render latency.
    await Future.wait([
      locationProvider.getCurrentLocation(),
      zoneProvider.fetchZones(),
      _loadCases(),
    ]);
  }

  bool _isUserInsideAnyZone(LatLng userLocation, List<EpidemicZone> zones) {
    for (final zone in zones) {
      final center = LatLng(zone.latitude, zone.longitude);
      final distanceMeters = _distance(userLocation, center);
      if (distanceMeters <= zone.radiusMeters) {
        return true;
      }
    }
    return false;
  }

  ZoneRiskLevel? _getUserDangerRisk(LatLng userLocation, List<EpidemicZone> zones) {
    ZoneRiskLevel? highestRisk;
    for (final zone in zones) {
      final center = LatLng(zone.latitude, zone.longitude);
      final distanceMeters = _distance(userLocation, center);
      if (distanceMeters > zone.radiusMeters) continue;

      if (highestRisk == null || zone.riskLevel.index > highestRisk.index) {
        highestRisk = zone.riskLevel;
      }
    }
    return highestRisk;
  }

  Duration _pulseDurationForRisk(ZoneRiskLevel riskLevel) {
    switch (riskLevel) {
      case ZoneRiskLevel.critical:
        return const Duration(milliseconds: 450);
      case ZoneRiskLevel.high:
        return const Duration(milliseconds: 650);
      case ZoneRiskLevel.medium:
        return const Duration(milliseconds: 900);
      case ZoneRiskLevel.low:
        return const Duration(milliseconds: 1200);
    }
  }

  void _syncDangerPulse(ZoneRiskLevel? riskLevel) {
    if (_activeDangerRisk == riskLevel || !mounted) return;
    _activeDangerRisk = riskLevel;

    if (riskLevel == null) {
      return;
    }

    _dangerPulseController.duration = _pulseDurationForRisk(riskLevel);
    _dangerPulseController
      ..reset()
      ..repeat(reverse: true);
  }

  Future<void> _loadCases() async {
    setState(() => _casesLoading = true);
    try {
      final response = await ApiClient.instance.get(ApiConstants.gisCases);
      final data = response.data;

      if (data is Map && data['features'] is List) {
        final features = data['features'] as List;
        final parsedCases = <_MapCase>[];

        for (final feature in features) {
          if (feature is! Map) continue;
          final geometry = feature['geometry'];
          final properties = feature['properties'];
          if (geometry is! Map || properties is! Map) continue;

          final coords = geometry['coordinates'];
          if (coords is! List || coords.length < 2) continue;

          final lon = (coords[0] as num?)?.toDouble();
          final lat = (coords[1] as num?)?.toDouble();
          if (lat == null || lon == null) continue;

          parsedCases.add(
            _MapCase(
              id: properties['id']?.toString() ?? '',
              diseaseType: properties['disease_type']?.toString() ?? 'Unknown',
              status: properties['status']?.toString() ?? 'unknown',
              reportedTime: properties['reported_time']?.toString(),
              patientName: properties['patient_name']?.toString(),
              notes: properties['notes']?.toString(),
              regionName: properties['region_name']?.toString(),
              lat: lat,
              lon: lon,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _cases = parsedCases;
          });
        }
      }
    } catch (_) {
      // Keep map usable even if case API fails.
    } finally {
      if (mounted) {
        setState(() => _casesLoading = false);
      }
    }
  }

  Color _getCaseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.red.shade700;
      case 'probable':
        return Colors.deepOrange;
      case 'suspected':
        return Colors.orange;
      case 'under treatment':
        return Colors.blue;
      case 'under observation':
        return Colors.cyan.shade700;
      case 'recovered':
        return Colors.green;
      case 'deceased':
      case 'died':
        return Colors.black87;
      default:
        return Colors.grey;
    }
  }

  void _showCaseDetails(_MapCase caseData) {
    final authProvider = context.read<AuthProvider>();
    final canViewSensitive = authProvider.user?.role.name == 'admin' ||
        authProvider.user?.role.name == 'healthWorker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CaseDetailSheet(
            caseData: caseData,
            canViewSensitive: canViewSensitive,
            onDirections: () => _openDirections(caseData.lat, caseData.lon),
            onShare: () => _shareCase(caseData),
          ),
    );
  }

  Future<void> _openDirections(double lat, double lon) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở ứng dụng chỉ đường'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareZone(EpidemicZone zone) async {
    final text = [
      'Canh bao vung dich: ${zone.name}',
      'Benh: ${zone.diseaseName}',
      'Muc do: ${zone.riskLevel.displayName}',
      'Toa do: ${zone.latitude.toStringAsFixed(6)}, ${zone.longitude.toStringAsFixed(6)}',
      'Ban do: https://maps.google.com/?q=${zone.latitude},${zone.longitude}',
    ].join('\n');

    await Share.share(text, subject: 'SafeZone - Vung dich ${zone.name}');
  }

  Future<void> _shareCase(_MapCase caseData) async {
    final text = [
      'Thong tin ca benh SafeZone',
      'Loai benh: ${caseData.diseaseType}',
      'Trang thai: ${caseData.status}',
      if (caseData.regionName?.isNotEmpty == true) 'Khu vuc: ${caseData.regionName}',
      'Toa do: ${caseData.lat.toStringAsFixed(6)}, ${caseData.lon.toStringAsFixed(6)}',
      'Ban do: https://maps.google.com/?q=${caseData.lat},${caseData.lon}',
    ].join('\n');

    await Share.share(text, subject: 'SafeZone - Ca benh ${caseData.diseaseType}');
  }

  void _centerOnUserLocation() {
    final locationProvider = context.read<LocationProvider>();
    final latLng = locationProvider.currentLatLng;
    if (latLng != null) {
      _mapController.move(latLng, 14);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lấy vị trí của bạn'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getRiskColor(ZoneRiskLevel level) {
    switch (level) {
      case ZoneRiskLevel.critical:
        return AppColors.severityHigh; // Red - matching web admin High severity
      case ZoneRiskLevel.high:
        return AppColors.severityHigh; // Red - matching web admin High severity
      case ZoneRiskLevel.medium:
        return AppColors.severityMedium; // Orange - matching web admin Medium severity
      case ZoneRiskLevel.low:
        return AppColors.severityLow; // Green - matching web admin Low severity
    }
  }

  Color _getRiskColorWithOpacity(ZoneRiskLevel level) {
    return _getRiskColor(level).withValues(alpha: 0.3);
  }

  IconData _getDiseaseIcon(DiseaseType type) {
    switch (type) {
      case DiseaseType.covid19:
        return Icons.coronavirus;
      case DiseaseType.dengue:
        return Icons.bug_report;
      case DiseaseType.influenza:
        return Icons.sick;
      case DiseaseType.handFootMouth:
        return Icons.child_care;
      case DiseaseType.cholera:
        return Icons.water_drop;
      case DiseaseType.other:
        return Icons.warning;
    }
  }

  void _showZoneDetails(EpidemicZone zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ZoneDetailSheet(
        zone: zone,
        onDirections: () => _openDirections(zone.latitude, zone.longitude),
        onShare: () => _shareZone(zone),
      ),
    );
  }

  List<EpidemicZone> _getFilteredZones(ZoneProvider zoneProvider) {
    if (_selectedDiseaseFilter == null) {
      return zoneProvider.activeZones;
    }
    return zoneProvider.activeZones
        .where((z) => z.diseaseName == _selectedDiseaseFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<LocationProvider, ZoneProvider>(
        builder: (context, locationProvider, zoneProvider, child) {
          final userLocation = locationProvider.currentLatLng;
          final zones = _getFilteredZones(zoneProvider);
          final userDangerRisk = userLocation != null
            ? _getUserDangerRisk(userLocation, zoneProvider.activeZones)
            : null;
          final userInsideDangerZone = userLocation != null &&
              _isUserInsideAnyZone(userLocation, zoneProvider.activeZones);
          _syncDangerPulse(userDangerRisk);
          final diseaseFilters = zoneProvider.activeZones
              .map((z) => z.diseaseName)
              .where((name) => name.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final warningColor = userDangerRisk != null
            ? _getRiskColor(userDangerRisk)
            : Colors.red;

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLocation ?? LocationProvider.defaultLocation,
                  initialZoom: 13,
                  minZoom: 5,
                  maxZoom: 18,
                ),
                children: [
                  // Tile layer (OpenStreetMap)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.safezone.app',
                  ),

                  // Zone circles
                  CircleLayer(
                    circles: zones.map((zone) {
                      return CircleMarker(
                        point: LatLng(zone.latitude, zone.longitude),
                        radius: zone.radiusMeters,
                        useRadiusInMeter: true,
                        color: _getRiskColorWithOpacity(zone.riskLevel),
                        borderColor: _getRiskColor(zone.riskLevel),
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  ),

                  // Zone markers
                  MarkerLayer(
                    markers: [
                      ..._cases.map((caseData) {
                        return Marker(
                          point: LatLng(caseData.lat, caseData.lon),
                          width: 26,
                          height: 26,
                          child: GestureDetector(
                            onTap: () => _showCaseDetails(caseData),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getCaseStatusColor(caseData.status),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Zone center markers
                      ...zones.map((zone) {
                        return Marker(
                          point: LatLng(zone.latitude, zone.longitude),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showZoneDetails(zone),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getRiskColor(zone.riskLevel),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getDiseaseIcon(zone.diseaseType),
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        );
                      }),

                      // User location marker
                      if (userLocation != null)
                        Marker(
                          point: userLocation,
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (userInsideDangerZone)
                                AnimatedBuilder(
                                  animation: _dangerPulseScale,
                                  builder: (context, _) {
                                    return Transform.scale(
                                      scale: _dangerPulseScale.value,
                                      child: Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: warningColor.withValues(alpha: 0.24),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: warningColor.withValues(alpha: 0.7),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: userInsideDangerZone ? warningColor : Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (userInsideDangerZone ? warningColor : Colors.blue)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Top bar with search and filter
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm địa điểm...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.filter_list),
                                    onPressed: () => _showFilterDialog(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ZoneListScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.list_alt),
                            label: const Text('DS vùng dịch'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Disease filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Tất cả',
                              isSelected: _selectedDiseaseFilter == null,
                              onSelected: () {
                                setState(() => _selectedDiseaseFilter = null);
                              },
                            ),
                            ...diseaseFilters.map((diseaseName) {
                              final sampleZone = zoneProvider.activeZones.firstWhere(
                                (z) => z.diseaseName == diseaseName,
                              );
                              return _FilterChip(
                                label: diseaseName,
                                isSelected: _selectedDiseaseFilter == diseaseName,
                                onSelected: () {
                                  setState(() => _selectedDiseaseFilter = diseaseName);
                                },
                                icon: _getDiseaseIcon(sampleZone.diseaseType),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (userInsideDangerZone)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 132,
                  child: FadeTransition(
                    opacity: _dangerPulseController,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: warningColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: warningColor.withValues(alpha: 0.28),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cảnh báo mức ${userDangerRisk?.displayName ?? 'Cao'}: Bạn đang trong vùng dịch.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Legend
              if (_showLegend)
                Positioned(
                  left: 16,
                  bottom: 100,
                  child: _MapLegend(
                    onClose: () => setState(() => _showLegend = false),
                  ),
                ),

              // Loading indicator
              if ((zoneProvider.status == ZoneStatus.loading && zones.isEmpty) ||
                  (_casesLoading && _cases.isEmpty))
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              // Zone count indicator
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${zones.length} vùng dịch • ${_cases.length} ca bệnh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // FAB buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Toggle legend
          FloatingActionButton.small(
            heroTag: 'legend',
            onPressed: () => setState(() => _showLegend = !_showLegend),
            backgroundColor: Colors.white,
            child: Icon(
              _showLegend ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),

          // Center on user location
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _centerOnUserLocation,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn mức độ nguy hiểm:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ZoneRiskLevel.values.map((level) {
                return FilterChip(
                  label: Text(level.displayName),
                  selected: false,
                  onSelected: (selected) {
                    Navigator.pop(context);
                  },
                  backgroundColor: _getRiskColorWithOpacity(level),
                  selectedColor: _getRiskColor(level),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dangerPulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue,
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
    );
  }
}

// Map legend widget
class _MapLegend extends StatelessWidget {
  final VoidCallback onClose;

  const _MapLegend({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chú thích',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const Divider(),
          _LegendItem(color: Colors.red.shade900, label: 'Nguy hiểm'),
          _LegendItem(color: Colors.red, label: 'Cao'),
          _LegendItem(color: Colors.orange, label: 'Trung bình'),
          _LegendItem(color: Colors.yellow.shade700, label: 'Thấp'),
          const Divider(),
          _LegendItem(color: Colors.red.shade700, label: 'Ca xác nhận'),
          _LegendItem(color: Colors.orange, label: 'Ca nghi ngờ'),
          _LegendItem(color: Colors.blue, label: 'Đang điều trị'),
          _LegendItem(color: Colors.green, label: 'Đã hồi phục'),
          const Divider(),
          const _LegendItem(
            icon: Icons.person,
            color: Colors.blue,
            label: 'Vị trí của bạn',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;

  const _LegendItem({
    required this.color,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            )
          else
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// Zone detail bottom sheet
class _ZoneDetailSheet extends StatelessWidget {
  final EpidemicZone zone;
  final VoidCallback onDirections;
  final VoidCallback onShare;

  const _ZoneDetailSheet({
    required this.zone,
    required this.onDirections,
    required this.onShare,
  });

  Color _getRiskColor(ZoneRiskLevel level) {
    switch (level) {
      case ZoneRiskLevel.critical:
        return Colors.red.shade900;
      case ZoneRiskLevel.high:
        return Colors.red;
      case ZoneRiskLevel.medium:
        return Colors.orange;
      case ZoneRiskLevel.low:
        return Colors.yellow.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getRiskColor(zone.riskLevel).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warning_amber,
                        color: _getRiskColor(zone.riskLevel),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRiskColor(zone.riskLevel),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              zone.riskLevel.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Disease type
                _InfoRow(
                  icon: Icons.coronavirus,
                  label: 'Loại bệnh',
                  value: zone.diseaseType.displayName,
                ),

                // Description
                if (zone.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    zone.description!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Statistics
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Ca nhiễm',
                              value: zone.confirmedCases.toString(),
                              color: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Đang điều trị',
                              value: zone.activeCases.toString(),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Đã hồi phục',
                              value: zone.recoveredCases.toString(),
                              color: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Tử vong',
                              value: zone.deaths.toString(),
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Radius info
                _InfoRow(
                  icon: Icons.radar,
                  label: 'Bán kính vùng dịch',
                  value: '${(zone.radiusMeters / 1000).toStringAsFixed(1)} km',
                ),

                const SizedBox(height: 8),

                // Reported date
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Ngày báo cáo',
                  value: _formatDate(zone.reportedAt),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDirections,
                        icon: const Icon(Icons.directions),
                        label: const Text('Chỉ đường'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share),
                        label: const Text('Chia sẻ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _MapCase {
  final String id;
  final String diseaseType;
  final String status;
  final String? reportedTime;
  final String? patientName;
  final String? notes;
  final String? regionName;
  final double lat;
  final double lon;

  const _MapCase({
    required this.id,
    required this.diseaseType,
    required this.status,
    required this.reportedTime,
    required this.patientName,
    required this.notes,
    required this.regionName,
    required this.lat,
    required this.lon,
  });
}

class _CaseDetailSheet extends StatelessWidget {
  final _MapCase caseData;
  final bool canViewSensitive;
  final VoidCallback onDirections;
  final VoidCallback onShare;

  const _CaseDetailSheet({
    required this.caseData,
    required this.canViewSensitive,
    required this.onDirections,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              canViewSensitive
                  ? 'Ca bệnh ${caseData.id.isEmpty ? '' : '#${caseData.id}'}'
                  : 'Thông tin ca bệnh',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text('Loại bệnh: ${caseData.diseaseType}'),
            const SizedBox(height: 6),
            Text('Trạng thái: ${caseData.status}'),
            const SizedBox(height: 6),
            Text('Khu vực: ${caseData.regionName ?? 'Không rõ'}'),
            const SizedBox(height: 6),
            Text(
              'Thời gian báo cáo: ${caseData.reportedTime ?? 'Không rõ'}',
            ),
            if (canViewSensitive) ...[
              const SizedBox(height: 6),
              Text('Bệnh nhân: ${caseData.patientName?.isNotEmpty == true ? caseData.patientName : 'Ẩn danh'}'),
            ],
            if (canViewSensitive && caseData.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Ghi chú: ${caseData.notes}'),
            ],
            if (canViewSensitive) ...[
              const SizedBox(height: 8),
              Text(
                'Tọa độ: ${caseData.lat.toStringAsFixed(5)}, ${caseData.lon.toStringAsFixed(5)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'Chi tiết bệnh nhân chỉ dành cho cơ quan y tế.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text('Chỉ đường'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
