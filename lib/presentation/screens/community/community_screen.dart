import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'package:mobile_flutter/presentation/screens/community/widgets/post_card.dart';
import 'package:mobile_flutter/presentation/screens/community/widgets/create_post_dialog.dart';

class CommunityScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const CommunityScreen({super.key, this.hideAppBar = false});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // Load posts when screen initializes
    Future.microtask(() {
      context.read<PostProvider>().loadMorePosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<PostProvider>(
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

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: postProvider.posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final post = postProvider.posts[index];
            return PostCard(post: post);
          },
        );
      },
    );

    final fab = FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const CreatePostDialog(),
        );
      },
      tooltip: 'Tạo bài viết',
      child: const Icon(Icons.add),
    );

    // If hideAppBar is true, return body without Scaffold
    if (widget.hideAppBar) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: fab,
          ),
        ],
      );
    }

    // Otherwise return full Scaffold with AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng'),
        centerTitle: true,
      ),
      body: body,
      floatingActionButton: fab,
    );
  }
}
