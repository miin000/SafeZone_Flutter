import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';
import 'package:mobile_flutter/presentation/providers/zone_provider.dart';
import 'package:mobile_flutter/presentation/providers/location_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _showLegend = true;
  DiseaseType? _selectedDiseaseFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    final locationProvider = context.read<LocationProvider>();
    final zoneProvider = context.read<ZoneProvider>();

    // Get user location
    await locationProvider.getCurrentLocation();

    // Load zones from API
    await zoneProvider.fetchZones();
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
        return Colors.red.shade900;
      case ZoneRiskLevel.high:
        return Colors.red;
      case ZoneRiskLevel.medium:
        return Colors.orange;
      case ZoneRiskLevel.low:
        return Colors.yellow.shade700;
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
      builder: (context) => _ZoneDetailSheet(zone: zone),
    );
  }

  List<EpidemicZone> _getFilteredZones(ZoneProvider zoneProvider) {
    if (_selectedDiseaseFilter == null) {
      return zoneProvider.activeZones;
    }
    return zoneProvider.getZonesByDisease(_selectedDiseaseFilter!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<LocationProvider, ZoneProvider>(
        builder: (context, locationProvider, zoneProvider, child) {
          final userLocation = locationProvider.currentLatLng;
          final zones = _getFilteredZones(zoneProvider);

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
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.4),
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
                      Container(
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
                            ...DiseaseType.values.map((type) {
                              return _FilterChip(
                                label: type.displayName,
                                isSelected: _selectedDiseaseFilter == type,
                                onSelected: () {
                                  setState(() => _selectedDiseaseFilter = type);
                                },
                                icon: _getDiseaseIcon(type),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
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
              if (zoneProvider.status == ZoneStatus.loading ||
                  locationProvider.status == LocationStatus.loading)
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
                        '${zones.length} vùng dịch',
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

  const _ZoneDetailSheet({required this.zone});

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
                        onPressed: () {},
                        icon: const Icon(Icons.directions),
                        label: const Text('Chỉ đường'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
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
