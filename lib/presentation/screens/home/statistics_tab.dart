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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StatisticsProvider>().fetchStatistics();
      context.read<StatisticsProvider>().fetchTimeline();
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
                          '${zone.diseaseType.displayName} - ${zone.riskLevel.displayName}',
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
    final colors = {
      'dengue': Colors.red,
      'hfmd': Colors.orange,
      'covid-19': Colors.purple,
      'influenza': Colors.blue,
    };

    return Column(
      children: byDisease.entries
          .map((e) => _buildDistributionItem(
                name: e.key,
                count: e.value,
                color: colors[e.key] ?? Colors.grey,
              ))
          .toList(),
    );
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
}
