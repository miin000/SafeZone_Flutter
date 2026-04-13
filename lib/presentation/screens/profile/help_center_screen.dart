import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<_HelpTopic> _popularTopics = [
    _HelpTopic(
      icon: Icons.warning_amber_rounded,
      title: 'Cách nhận cảnh báo vùng dịch',
      summary: 'Bật định vị và thông báo để nhận cảnh báo kịp thời khi đi vào vùng nguy cơ.',
      content:
          'Mở Cài đặt ứng dụng trong SafeZone, bật theo dõi vị trí và âm thanh thông báo. Ứng dụng sẽ tự động kiểm tra vùng dịch quanh bạn và hiển thị cảnh báo theo mức độ nguy hiểm.',
    ),
    _HelpTopic(
      icon: Icons.report_gmailerrorred_rounded,
      title: 'Cách gửi báo cáo ca bệnh',
      summary: 'Bạn có thể gửi báo cáo nhanh hoặc báo cáo chi tiết kèm hình ảnh.',
      content:
          'Vào tab Bao cao, chọn loai bao cao, dien noi dung va vi tri. Neu co bang chung, hay dinh kem anh de can bo y te xu ly nhanh hon.',
    ),
    _HelpTopic(
      icon: Icons.privacy_tip_outlined,
      title: 'Bảo mật dữ liệu cá nhân',
      summary: 'SafeZone chỉ sử dụng dữ liệu cần thiết để cảnh báo và thống kê dịch tễ.',
      content:
          'Thong tin ca nhan duoc gioi han truong du lieu va su dung cho muc dich canh bao y te. Ban co the quan ly quyen thong bao va vi tri trong cai dat ung dung.',
    ),
    _HelpTopic(
      icon: Icons.map_outlined,
      title: 'Bản đồ không cập nhật',
      summary: 'Kiểm tra mạng, quyền vị trí và thử làm mới dữ liệu.',
      content:
          'Neu ban do khong hien thi du lieu moi, hay kiem tra ket noi internet, quyen truy cap vi tri, sau do thu tat mo ung dung hoac mo lai trang ban do.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm hỗ trợ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nội dung phổ biến giúp bạn sử dụng SafeZone hiệu quả hơn.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._popularTopics.map((topic) => _TopicCard(topic: topic)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Liên hệ hỗ trợ'),
              subtitle: const Text('Email: support@safezone.vn | Hotline: 1900 6868'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng liên hệ hỗ trợ qua email hoặc hotline.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _HelpTopic topic;

  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(topic.icon, color: Colors.blue.shade700),
        title: Text(
          topic.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(topic.summary),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              topic.content,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTopic {
  final IconData icon;
  final String title;
  final String summary;
  final String content;

  const _HelpTopic({
    required this.icon,
    required this.title,
    required this.summary,
    required this.content,
  });
}
