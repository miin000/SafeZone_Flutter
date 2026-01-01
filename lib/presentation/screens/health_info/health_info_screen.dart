import 'package:flutter/material.dart';

class HealthInfoScreen extends StatelessWidget {
  const HealthInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthInfoCategories = [
      _HealthInfoCategory(
        title: 'Phòng chống dịch bệnh',
        icon: Icons.shield,
        color: Colors.red,
        items: [
          'Hướng dẫn phòng chống COVID-19',
          'Cách phòng tránh sốt xuất huyết',
          'Phòng bệnh tay chân miệng cho trẻ',
          'Vệ sinh an toàn thực phẩm',
        ],
      ),
      _HealthInfoCategory(
        title: 'Tiêm chủng',
        icon: Icons.vaccines,
        color: Colors.green,
        items: [
          'Lịch tiêm chủng cho trẻ em',
          'Vaccine COVID-19: Những điều cần biết',
          'Tiêm phòng cúm mùa',
          'Các loại vaccine khuyến nghị',
        ],
      ),
      _HealthInfoCategory(
        title: 'Sức khỏe cộng đồng',
        icon: Icons.people,
        color: Colors.blue,
        items: [
          'Thống kê dịch bệnh Việt Nam',
          'Bản đồ vùng dịch cập nhật',
          'Các điểm xét nghiệm miễn phí',
          'Hotline y tế các tỉnh thành',
        ],
      ),
      _HealthInfoCategory(
        title: 'Hướng dẫn y tế',
        icon: Icons.medical_services,
        color: Colors.orange,
        items: [
          'Sơ cứu cơ bản tại nhà',
          'Khi nào cần đến bệnh viện',
          'Cách chăm sóc người bệnh',
          'Dinh dưỡng cho người bệnh',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin y tế'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cập nhật tình hình dịch bệnh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Theo dõi thông tin mới nhất về tình hình dịch bệnh tại Việt Nam và trên thế giới.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to detailed stats
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade600,
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            ...healthInfoCategories.map((category) => _HealthInfoCategoryCard(category: category)),
          ],
        ),
      ),
    );
  }
}

class _HealthInfoCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  _HealthInfoCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _HealthInfoCategoryCard extends StatelessWidget {
  final _HealthInfoCategory category;

  const _HealthInfoCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.1),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(
          category.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: category.items.map((item) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.article, color: Colors.grey.shade400, size: 20),
            title: Text(item),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to article detail
            },
          );
        }).toList(),
      ),
    );
  }
}
