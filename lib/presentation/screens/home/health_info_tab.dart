import 'package:flutter/material.dart';
import 'package:mobile_flutter/data/models/health_info_model.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/health_info_provider.dart';
import 'package:mobile_flutter/presentation/screens/health_info/health_info_detail_screen.dart';

class HealthInfoTab extends StatefulWidget {
  const HealthInfoTab({super.key});

  @override
  State<HealthInfoTab> createState() => _HealthInfoTabState();
}

class _HealthInfoTabState extends State<HealthInfoTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  String _selectedDisease = 'Tất cả';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HealthInfoProvider>().fetchHealthInfo();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<HealthInfoProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthInfoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.healthInfoList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.healthInfoList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchHealthInfo(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.healthInfoList.isEmpty) {
          return const Center(child: Text('Không có thông tin y tế'));
        }

        final categories = <String>{'Tất cả'}
          ..addAll(
            provider.healthInfoList
                .map((item) => (item.category ?? '').trim())
                .where((v) => v.isNotEmpty),
          );
        final diseases = <String>{'Tất cả'}
          ..addAll(
            provider.healthInfoList
                .map((item) => item.diseaseType.trim())
                .where((v) => v.isNotEmpty),
          );

        final query = _searchController.text.trim().toLowerCase();
        final filtered = provider.healthInfoList.where((item) {
          if (_selectedCategory != 'Tất cả' && (item.category ?? '').trim() != _selectedCategory) {
            return false;
          }
          if (_selectedDisease != 'Tất cả' && item.diseaseType.trim() != _selectedDisease) {
            return false;
          }
          if (query.isEmpty) return true;
          final haystack = '${item.title} ${item.summary ?? ''} ${item.content} ${item.tags.join(' ')}'.toLowerCase();
          return haystack.contains(query);
        }).toList();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length +
              1 +
              (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tiêu đề, nội dung, thẻ...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Danh mục',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            items: categories
                                .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v ?? 'Tất cả'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDisease,
                            decoration: InputDecoration(
                              labelText: 'Bệnh',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            items: diseases
                                .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedDisease = v ?? 'Tất cả'),
                          ),
                        ),
                      ],
                    ),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Không có bài phù hợp bộ lọc.'),
                        ),
                      ),
                  ],
                ),
              );
            }

            final adjustedIndex = index - 1;
            if (adjustedIndex == filtered.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            final healthInfo = filtered[adjustedIndex];

            return _buildHealthInfoCard(healthInfo);
          },
        );
      },
    );
  }

  String _plainPreview(String input) {
    return input
        .replaceAll(RegExp(r'\r\n|\n|\r'), ' ')
        .replaceAll(RegExp(r'(^|\s)#{1,6}\s*'), ' ')
        .replaceAll(RegExp(r'[*_`~>-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildHealthInfoCard(HealthInfo healthInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (healthInfo.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                healthInfo.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (healthInfo.category != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        healthInfo.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Text(
                  _plainPreview(healthInfo.title),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _plainPreview(
                    healthInfo.summary?.trim().isNotEmpty == true
                        ? healthInfo.summary!
                        : healthInfo.content,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cập nhật: ${_formatDate(healthInfo.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (healthInfo.source != null)
                      Text(
                        'Nguồn: ${healthInfo.source}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(label: 'Bệnh: ${healthInfo.diseaseType}'),
                    _MetaChip(label: 'Đối tượng: ${healthInfo.target}'),
                    _MetaChip(label: 'Mức độ: ${healthInfo.severityLevel}'),
                    ...healthInfo.tags.take(2).map((tag) => _MetaChip(label: '#$tag')),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HealthInfoDetailScreen(initialData: healthInfo),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Xem chi tiết'),
                  ),
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
