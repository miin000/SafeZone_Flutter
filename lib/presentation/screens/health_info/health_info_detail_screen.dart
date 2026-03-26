import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobile_flutter/data/models/health_info_model.dart';
import 'package:mobile_flutter/data/repositories/health_info_repository.dart';

class HealthInfoDetailScreen extends StatefulWidget {
  final HealthInfo initialData;

  const HealthInfoDetailScreen({
    super.key,
    required this.initialData,
  });

  @override
  State<HealthInfoDetailScreen> createState() => _HealthInfoDetailScreenState();
}

class _HealthInfoDetailScreenState extends State<HealthInfoDetailScreen> {
  final HealthInfoRepository _repository = HealthInfoRepositoryImpl();

  bool _loading = true;
  String? _error;
  late HealthInfo _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _repository.fetchById(widget.initialData.id);
      if (!mounted) return;
      setState(() => _data = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _normalizeMarkdown(String value) {
    var normalized = value
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll('\r\n', '\n');

    // Some legacy content stores escaped markdown tokens like \# or \*.
    // Unescape them so heading, list, and bold syntax render correctly.
    final escapedMarkdownTokenCount = RegExp(
      r'\\([#*`_\-+>\[\]])',
    ).allMatches(normalized).length;

    if (escapedMarkdownTokenCount >= 2) {
      normalized = normalized.replaceAllMapped(
        RegExp(r'\\([#*`_\-+>\[\]])'),
        (match) => match.group(1)!,
      );
    }

    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông tin y tế'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_data.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _data.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
            if (_data.imageUrl != null) const SizedBox(height: 12),
            if (_data.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _data.category!,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              _data.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_data.summary?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                _data.summary!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Cập nhật: ${_formatDate(_data.updatedAt ?? _data.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_data.source != null) ...[
              const SizedBox(height: 4),
              Text(
                'Nguồn: ${_data.source}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetaChip(label: 'Bệnh: ${_data.diseaseType}'),
                _MetaChip(label: 'Đối tượng: ${_data.target}'),
                _MetaChip(label: 'Mức độ: ${_data.severityLevel}'),
                ..._data.tags.map((tag) => _MetaChip(label: '#$tag')),
              ],
            ),
            const SizedBox(height: 16),
            MarkdownBody(
              data: _normalizeMarkdown(_data.content),
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 16, height: 1.5),
                h3: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                listBullet: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Không thể tải chi tiết mới nhất: $_error',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
