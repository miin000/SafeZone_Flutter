import 'package:flutter/material.dart';
import 'package:mobile_flutter/data/models/report_model.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - in real app, fetch from provider
    final reports = [
      ReportModel(
        id: '1',
        diseaseType: 'Sốt xuất huyết',
        description: 'Phát hiện 2 ca sốt xuất huyết tại chung cư...',
        lat: 21.0285,
        lon: 105.8542,
        address: 'Số 10 Phố Huế, Hai Bà Trưng, Hà Nội',
        symptoms: ['sốt cao', 'đau đầu', 'phát ban'],
        status: ReportStatus.verified,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        userId: 'user_001',
      ),
      ReportModel(
        id: '2',
        diseaseType: 'COVID-19',
        description: 'Nghi ngờ ca COVID-19 tại tòa nhà văn phòng...',
        lat: 21.0333,
        lon: 105.7994,
        address: 'Cầu Giấy, Hà Nội',
        symptoms: ['ho', 'sốt', 'mệt mỏi'],
        status: ReportStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
        userId: 'user_001',
      ),
      ReportModel(
        id: '3',
        diseaseType: 'Tay chân miệng',
        description: 'Trẻ em trong khu vực có triệu chứng tay chân miệng...',
        lat: 21.0167,
        lon: 105.8333,
        address: 'Đống Đa, Hà Nội',
        symptoms: ['sốt', 'nổi mụn nước'],
        status: ReportStatus.rejected,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
        userId: 'user_001',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo của tôi'),
      ),
      body: reports.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có báo cáo nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các báo cáo của bạn sẽ hiển thị ở đây',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _ReportCard(report: report);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.statusText,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.diseaseType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            if (report.address != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: View report details
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Xem chi tiết'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (report.status) {
      case ReportStatus.verified:
        return Colors.green;
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.resolved:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}