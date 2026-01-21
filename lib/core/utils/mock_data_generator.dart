// lib/core/utils/mock_data_generator.dart
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/data/models/user_model.dart';

class MockDataGenerator {
  static UserModel get mockUser => UserModel(
    id: 'user_001',
    email: 'user@example.com',
    name: 'Người dùng thử nghiệm',
    phone: '0912345678',
    role: UserRole.user,
    isEmailVerified: true,
    isPhoneVerified: true,
  );

  static List<PostModel> generateMockPosts(int count) {
    final posts = <PostModel>[];

    for (int i = 1; i <= count; i++) {
      posts.add(PostModel(
        id: 'mock_post_$i',
        content: 'Bài viết mẫu số $i: Thông tin về dịch bệnh trong khu vực...',
        imageUrls: i % 3 == 0 ? ['https://picsum.photos/400/300'] : [],
        source: i % 4 == 0 ? PostSource.government : PostSource.citizen,
        status: PostStatus.approved,
        location: i % 2 == 0 ? 'Hà Nội' : 'Hồ Chí Minh',
        diseaseType: i % 3 == 0 ? 'Sốt xuất huyết' : 'COVID-19',
        author: mockUser,
        authorId: 'user_001',
        helpfulCount: i * 3,
        notHelpfulCount: i ~/ 2,
        userReactions: {},
        createdAt: DateTime.now().subtract(Duration(days: i)),
      ));
    }

    return posts;
  }
}