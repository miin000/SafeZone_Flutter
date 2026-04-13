import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mobile_flutter/data/models/report_model.dart';
import 'package:mobile_flutter/presentation/providers/report_provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReportById(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final report = provider.selectedReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết báo cáo'),
      ),
      body: provider.isLoading && report == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && report == null
              ? _ErrorView(
                  error: provider.error!,
                  onRetry: () =>
                      context.read<ReportProvider>().fetchReportById(widget.reportId),
                )
              : report == null
                  ? const Center(child: Text('Không tìm thấy báo cáo'))
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<ReportProvider>()
                          .fetchReportById(widget.reportId),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _HeaderCard(report: report),
                          const SizedBox(height: 12),
                          _DetailCard(report: report),
                          const SizedBox(height: 12),
                          _TimelineCard(report: report),
                        ],
                      ),
                    ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ReportModel report;

  const _HeaderCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.statusText,
                    style: TextStyle(
                      color: _statusColor(report.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.diseaseType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${report.reportTypeText} • Mức độ: ${report.severityText}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ReportStatus status) {
    switch (status) {
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
}

class _DetailCard extends StatelessWidget {
  final ReportModel report;

  const _DetailCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin báo cáo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _kv('Mô tả', report.description.isNotEmpty ? report.description : '-'),
            const SizedBox(height: 8),
            _kv('Địa chỉ', report.address?.trim().isNotEmpty == true ? report.address!.trim() : '-'),
            const SizedBox(height: 8),
            _kv('Tọa độ', '${report.lat.toStringAsFixed(6)}, ${report.lon.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            _kv('Triệu chứng', report.symptoms.isNotEmpty ? report.symptoms.join(', ') : '-'),
            const SizedBox(height: 8),
            _kv('Ghi chú', report.adminNote?.trim().isNotEmpty == true ? report.adminNote!.trim() : '-'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final ReportModel report;

  const _TimelineCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep('Đã gửi', report.createdAt),
      if (report.autoVerifiedAt != null)
        _TimelineStep('Xác minh tự động', report.autoVerifiedAt!),
      if (report.preliminaryReviewAt != null)
        _TimelineStep('Duyệt sơ bộ', report.preliminaryReviewAt!),
      if (report.fieldVerifiedAt != null)
        _TimelineStep('Kiểm tra thực địa', report.fieldVerifiedAt!),
      if (report.officialConfirmAt != null)
        _TimelineStep('Xác nhận chính thức', report.officialConfirmAt!),
      if (report.closedAt != null)
        _TimelineStep('Đã đóng', report.closedAt!),
      if (report.status == ReportStatus.rejected)
        _TimelineStep('Bị từ chối', report.updatedAt),
    ].where((s) => s.at != null).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiến trình xử lý',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (steps.isEmpty)
              Text(
                'Chưa có cập nhật mới.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else
              ...steps.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(s.label),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(s.at!)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final DateTime? at;

  _TimelineStep(this.label, this.at);
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
