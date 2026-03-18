import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';
import 'package:mobile_flutter/presentation/providers/location_provider.dart';
import 'package:mobile_flutter/presentation/providers/statistics_provider.dart';
import 'package:mobile_flutter/presentation/providers/zone_provider.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  int _timelineDays = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StatisticsProvider>().fetchStatistics();
      context.read<StatisticsProvider>().fetchTimeline(days: _timelineDays);
      _loadNearbyStats();
    });
  }

  Future<void> _loadNearbyStats() async {
    final locationProvider = context.read<LocationProvider>();
    final zoneProvider = context.read<ZoneProvider>();

    await locationProvider.getCurrentLocation();
    final position = locationProvider.currentPosition;
    if (position == null) return;

    await zoneProvider.fetchZonesNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, provider, _) {
        final locationProvider = context.watch<LocationProvider>();
        final zoneProvider = context.watch<ZoneProvider>();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchStatistics(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final stats = provider.stats;
        if (stats == null) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            _buildSummaryCard(
              title: 'Tổng cộng',
              value: stats.total.toString(),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            // Disease Distribution
            _buildSectionTitle('Phân bố theo bệnh'),
            _buildDiseaseDistribution(stats.byDisease),
            const SizedBox(height: 20),

            // Status Distribution
            _buildSectionTitle('Phân bố theo trạng thái'),
            _buildStatusDistribution(stats.byStatus),
            const SizedBox(height: 20),

            // Trend
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Xu hướng'),
                _buildTrendCards(stats.trend),
                const SizedBox(height: 20),
              ],
            ),

            _buildSectionTitle('Diễn biến theo ngày'),
            _buildTimelineRangeFilter(provider),
            const SizedBox(height: 12),
            _buildTimelinePieChart(provider.timeline),
            const SizedBox(height: 20),

            // Top Regions
            if (stats.byRegion.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Top vùng miền'),
                  ..._buildRegionList(stats.byRegion),
                  const SizedBox(height: 20),
                ],
              ),

            _buildSectionTitle('Thống kê xung quanh bạn'),
            _buildNearbySection(locationProvider, zoneProvider),
          ],
        );
      },
    );
  }

  Widget _buildNearbySection(
    LocationProvider locationProvider,
    ZoneProvider zoneProvider,
  ) {
    if (locationProvider.status == LocationStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (locationProvider.status == LocationStatus.denied ||
        locationProvider.status == LocationStatus.error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locationProvider.errorMessage ?? 'Cần quyền vị trí để hiển thị thống kê gần bạn.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadNearbyStats,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (zoneProvider.status == ZoneStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (zoneProvider.status == ZoneStatus.error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              zoneProvider.errorMessage ?? 'Không tải được dữ liệu vùng dịch gần bạn.',
              style: TextStyle(color: Colors.red.shade900),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadNearbyStats,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final nearbyZones = zoneProvider.activeZones;
    if (nearbyZones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Text('Không phát hiện vùng dịch hoạt động trong bán kính 5km.'),
      );
    }

    final highRiskCount = nearbyZones
        .where((z) => z.riskLevel == ZoneRiskLevel.high || z.riskLevel == ZoneRiskLevel.critical)
        .length;
    final totalCases = nearbyZones.fold<int>(0, (sum, z) => sum + z.confirmedCases);
    final sortedZones = [...nearbyZones]..sort((a, b) {
        final da = locationProvider.distanceTo(a.latitude, a.longitude) ?? double.infinity;
        final db = locationProvider.distanceTo(b.latitude, b.longitude) ?? double.infinity;
        return da.compareTo(db);
      });

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTrendCard(
                label: 'Vùng dịch gần bạn',
                value: nearbyZones.length.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTrendCard(
                label: 'Nguy cơ cao',
                value: highRiskCount.toString(),
                isTrend: highRiskCount > 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTrendCard(
                label: 'Tổng ca gần bạn',
                value: totalCases.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedZones.take(3).map((zone) {
          final distanceMeters = locationProvider.distanceTo(zone.latitude, zone.longitude);
          final distanceKm = distanceMeters == null ? '-' : (distanceMeters / 1000).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${zone.diseaseName} - ${zone.riskLevel.displayName}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$distanceKm km',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDiseaseDistribution(Map<String, int> byDisease) {
    return Column(
      children: byDisease.entries
          .map((e) => _buildDistributionItem(
                name: e.key,
                count: e.value,
                color: _diseaseColor(e.key),
              ))
          .toList(),
    );
  }

  Color _diseaseColor(String diseaseName) {
    final palette = [
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.green,
      Colors.brown,
      Colors.indigo,
    ];
    final seed = diseaseName.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return palette[seed % palette.length];
  }

  Widget _buildStatusDistribution(Map<String, int> byStatus) {
    return Column(
      children: byStatus.entries
          .map((e) => _buildDistributionItem(
                name: e.key,
                count: e.value,
                color: Colors.teal,
              ))
          .toList(),
    );
  }

  Widget _buildDistributionItem({
    required String name,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCards(dynamic trend) {
    return Row(
      children: [
        Expanded(
          child: _buildTrendCard(
            label: 'Hôm nay',
            value: trend.today.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrendCard(
            label: 'Tuần này',
            value: trend.thisWeek.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTrendCard(
            label: 'Thay đổi',
            value: '${trend.percentChange}%',
            isTrend: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard({
    required String label,
    required String value,
    bool isTrend = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isTrend ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRegionList(List<dynamic> regions) {
    return regions
        .map((region) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            region.regionCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      region.count.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  Widget _buildTimelineRangeFilter(StatisticsProvider provider) {
    final options = [7, 30, 90, 180];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((days) {
        final selected = _timelineDays == days;
        return ChoiceChip(
          label: Text('$days ngày'),
          selected: selected,
          onSelected: (_) async {
            if (selected) {
              return;
            }
            setState(() {
              _timelineDays = days;
            });
            await provider.fetchTimeline(days: days);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimelinePieChart(dynamic timelineData) {
    final points = timelineData?.timeline as List<dynamic>?;
    if (points == null || points.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Chưa có dữ liệu timeline'),
      );
    }

    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: _timelineDays - 1));

    final filtered = points.where((point) {
      final rawDate = (point.date ?? '').toString();
      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) {
        return false;
      }
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(from);
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Không có dữ liệu trong $_timelineDays ngày gần nhất'),
      );
    }

    final sorted = [...filtered]
      ..sort((a, b) => (b.count as int).compareTo(a.count as int));

    const palette = [
      Color(0xFF1565C0),
      Color(0xFF00897B),
      Color(0xFFF4511E),
      Color(0xFF6A1B9A),
      Color(0xFF2E7D32),
      Color(0xFFEF6C00),
      Color(0xFF546E7A),
      Color(0xFFC62828),
    ];

    final slices = <_TimelineSlice>[];
    final topCount = sorted.length > 6 ? 6 : sorted.length;
    for (var i = 0; i < topCount; i++) {
      final point = sorted[i];
      final rawDate = point.date.toString();
      final label = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
      slices.add(
        _TimelineSlice(
          label: label,
          count: point.count as int,
          color: palette[i % palette.length],
        ),
      );
    }

    if (sorted.length > topCount) {
      final otherCount = sorted
          .skip(topCount)
          .fold<int>(0, (sum, point) => sum + (point.count as int));
      if (otherCount > 0) {
        slices.add(
          const _TimelineSlice(
            label: 'Các ngày khác',
            count: 0,
            color: Color(0xFF90A4AE),
          ).copyWith(count: otherCount),
        );
      }
    }

    final total = slices.fold<int>(0, (sum, s) => sum + s.count);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _PieChartPainter(slices),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tổng ca',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...slices.map((slice) {
            final percent = total == 0 ? 0 : (slice.count / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: slice.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      slice.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${slice.count} (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineSlice {
  final String label;
  final int count;
  final Color color;

  const _TimelineSlice({
    required this.label,
    required this.count,
    required this.color,
  });

  _TimelineSlice copyWith({String? label, int? count, Color? color}) {
    return _TimelineSlice(
      label: label ?? this.label,
      count: count ?? this.count,
      color: color ?? this.color,
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<_TimelineSlice> slices;

  _PieChartPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) {
      return;
    }

    final total = slices.fold<int>(0, (sum, s) => sum + s.count);
    if (total <= 0) {
      return;
    }

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2,
    );

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.count / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = slice.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      math.min(size.width, size.height) * 0.28,
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (var i = 0; i < slices.length; i++) {
      if (oldDelegate.slices[i].label != slices[i].label ||
          oldDelegate.slices[i].count != slices[i].count ||
          oldDelegate.slices[i].color != slices[i].color) {
        return true;
      }
    }
    return false;
  }
}
