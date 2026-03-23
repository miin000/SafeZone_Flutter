import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'package:mobile_flutter/presentation/screens/community/widgets/post_card.dart';
import 'package:mobile_flutter/presentation/screens/community/widgets/create_post_dialog.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load posts when screen initializes
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<PostProvider>();
      provider.initialize();
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      context.read<PostProvider>().refreshPosts(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng'),
        centerTitle: true,
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, _) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (postProvider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài viết nào',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy là người đầu tiên chia sẻ thông tin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => postProvider.refreshPosts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: postProvider.posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePostDialog(),
          );
        },
        tooltip: 'Tạo bài viết',
        child: const Icon(Icons.add),
      ),
    );
  }
}
