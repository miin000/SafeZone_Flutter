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
  int _timelineDays = 7;
  DateTime? _lastNearbyStatsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StatisticsProvider>().fetchStatistics();
      context.read<StatisticsProvider>().fetchTimeline(days: _timelineDays);
      _loadNearbyStats();
      context.read<LocationProvider>().addListener(_onLocationUpdated);
    });
  }

  void _onLocationUpdated() {
    if (!mounted) return;
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition == null) return;

    final now = DateTime.now();
    if (_lastNearbyStatsAt != null &&
        now.difference(_lastNearbyStatsAt!).inSeconds < 30) {
      return;
    }

    _loadNearbyStats();
  }

  Future<void> _loadNearbyStats() async {
    final locationProvider = context.read<LocationProvider>();
    final zoneProvider = context.read<ZoneProvider>();

    var position = locationProvider.currentPosition;
    if (position == null) {
      await locationProvider.getCurrentLocation();
      position = locationProvider.currentPosition;
    }

    if (position == null) return;

    await zoneProvider.fetchZonesNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: 5,
    );
    _lastNearbyStatsAt = DateTime.now();
  }

  @override
  void dispose() {
    context.read<LocationProvider>().removeListener(_onLocationUpdated);
    super.dispose();
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
            _buildSummaryGrid(stats),
            const SizedBox(height: 12),

            // Disease Distribution
            _buildSectionTitle('Top 5 bệnh (biểu đồ)'),
            _buildDiseaseDistribution(stats.byDisease),
            const SizedBox(height: 20),

            // Status Distribution
            _buildSectionTitle('Top 5 trạng thái (biểu đồ)'),
            _buildStatusDistribution(stats.byStatus),
            const SizedBox(height: 20),

            _buildSectionTitle('Diễn biến theo ngày'),
            _buildTimelineRangeFilter(provider),
            const SizedBox(height: 12),
            _buildTimelineBarChart(provider.timeline),
            const SizedBox(height: 20),

            // Top Regions
            if (stats.byRegion.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Top 5 vùng miền'),
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

  Widget _buildSummaryGrid(dynamic stats) {
    final confirmed = stats.byStatus['confirmed'] ?? 0;
    final suspected = stats.byStatus['suspected'] ?? 0;
    final recovered = stats.byStatus['recovered'] ?? 0;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: [
        _buildSummaryCard(title: 'Tổng ca', value: stats.total.toString(), color: Colors.blue),
        _buildSummaryCard(title: 'Xác nhận', value: '$confirmed', color: Colors.red),
        _buildSummaryCard(title: 'Nghi ngờ', value: '$suspected', color: Colors.orange),
        _buildSummaryCard(title: 'Đã khỏi', value: '$recovered', color: Colors.green),
      ],
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
    final topEntries = [...byDisease.entries]
      ..sort((a, b) => b.value.compareTo(a.value));
    return _buildHorizontalBarChart(
      entries: topEntries.take(5).toList(),
      colorBuilder: (name) => _diseaseColor(name),
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
    final topEntries = [...byStatus.entries]
      ..sort((a, b) => b.value.compareTo(a.value));
    return _buildHorizontalBarChart(
      entries: topEntries.take(5).toList(),
      colorBuilder: (_) => Colors.teal,
    );
  }

  Widget _buildHorizontalBarChart({
    required List<MapEntry<String, int>> entries,
    required Color Function(String name) colorBuilder,
  }) {
    if (entries.isEmpty) {
      return const Text('Không có dữ liệu');
    }

    final maxValue = entries.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: entries.map((entry) {
        final color = colorBuilder(entry.key);
        final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    final sorted = [...regions]
      ..sort((a, b) => (b.count as num).compareTo(a.count as num));

    return sorted
        .take(5)
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
    final options = [7, 14, 30];
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

  Widget _buildTimelineBarChart(dynamic timelineData) {
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
      ..sort((a, b) => a.date.toString().compareTo(b.date.toString()));

    final maxCount = sorted
        .map((point) => point.count as int)
        .fold<int>(1, (max, value) => value > max ? value : max);
    final total = sorted
        .fold<int>(0, (sum, point) => sum + (point.count as int));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7 ngày gần nhất',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Tổng: $total ca',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sorted.map((point) {
                final rawDate = point.date.toString();
                final shortDate = rawDate.length >= 10 ? rawDate.substring(5, 10) : rawDate;
                final count = point.count as int;
                final barHeight = maxCount == 0 ? 0.0 : (count / maxCount) * 130;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight.clamp(6, 130),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shortDate,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
