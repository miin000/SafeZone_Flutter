import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';
import 'package:mobile_flutter/presentation/providers/zone_provider.dart';

class ZoneListScreen extends StatelessWidget {
  const ZoneListScreen({super.key});

  Color _riskColor(ZoneRiskLevel level) {
    switch (level) {
      case ZoneRiskLevel.critical:
        return Colors.red.shade700;
      case ZoneRiskLevel.high:
        return Colors.red.shade500;
      case ZoneRiskLevel.medium:
        return Colors.orange.shade600;
      case ZoneRiskLevel.low:
        return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách vùng dịch'),
      ),
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          final zones = [...zoneProvider.activeZones]
            ..sort((a, b) => b.activeCases.compareTo(a.activeCases));

          if (zoneProvider.status == ZoneStatus.loading && zones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (zones.isEmpty) {
            return const Center(
              child: Text('Chưa có vùng dịch hoạt động'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final zone = zones[index];
              final riskColor = _riskColor(zone.riskLevel);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              zone.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: riskColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              zone.riskLevel.displayName,
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Bệnh: ${zone.diseaseName}'),
                      Text('Số ca: ${zone.confirmedCases} (đang điều trị: ${zone.activeCases})'),
                      Text(
                        'Tọa độ: ${zone.latitude.toStringAsFixed(5)}, ${zone.longitude.toStringAsFixed(5)}',
                      ),
                      Text('Bán kính: ${(zone.radiusMeters / 1000).toStringAsFixed(1)} km'),
                      if ((zone.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          zone.description!,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
