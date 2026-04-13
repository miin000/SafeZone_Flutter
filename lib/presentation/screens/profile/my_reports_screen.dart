import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/data/models/report_model.dart';
import 'package:mobile_flutter/presentation/providers/report_provider.dart';
import 'package:mobile_flutter/presentation/screens/profile/report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final reports = reportProvider.myReports;

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo của tôi')),
      body: reportProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportProvider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra:\n${reportProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ReportProvider>().fetchMyReports(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
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
          : RefreshIndicator(
              onRefresh: () => context.read<ReportProvider>().fetchMyReports(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _ReportCard(report: report);
                },
              ),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.diseaseType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (report.address != null)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(reportId: report.id),
                  ),
                );
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
      case ReportStatus.submitted:
        return Colors.grey;
      case ReportStatus.autoVerified:
        return Colors.cyan;
      case ReportStatus.underReview:
        return Colors.blue;
      case ReportStatus.fieldVerification:
        return Colors.orange;
      case ReportStatus.confirmed:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.closed:
        return Colors.blueGrey;
      case ReportStatus.verified:
        return Colors.green;
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
