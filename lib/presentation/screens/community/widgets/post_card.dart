import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'package:mobile_flutter/presentation/providers/auth_provider.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _reacting = false;

  Future<void> _react(String type) async {
    if (_reacting) return;
    setState(() => _reacting = true);
    try {
      await context.read<PostProvider>().reactToPost(widget.post.id, type);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tương tác bài viết: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reacting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isMyPost = currentUserId != null && currentUserId == post.authorId;
    final fallbackName = isMyPost ? 'Bạn' : 'Ẩn danh';
    final displayAuthorName =
        post.author?.name ?? (post.authorName == 'Ẩn danh' ? fallbackName : post.authorName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.author?.avatarUrl != null
                      ? NetworkImage(post.author!.avatarUrl!)
                      : null,
                  child: post.author?.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayAuthorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(
                            post.sourceIcon,
                            size: 14,
                            color: post.sourceColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.sourceText,
                            style: TextStyle(
                              fontSize: 12,
                              color: post.sourceColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 14),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

            // Images (if any)
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrls[index],
                        fit: BoxFit.cover,
                        width: 200,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Status badge
            if (post.status != PostStatus.approved)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(post.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(post.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Meta info
            if (post.diseaseType != null || post.location != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (post.diseaseType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          post.diseaseType!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (post.location != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          post.location!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

            // Reactions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reacting ? null : () => _react('helpful'),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                    label: Text('${post.helpfulCount} Hữu ích'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reacting ? null : () => _react('not_helpful'),
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                    label: Text('${post.notHelpfulCount} Không hữu ích'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PostStatus status) {
    switch (status) {
      case PostStatus.pending:
        return Colors.orange;
      case PostStatus.approved:
        return Colors.green;
      case PostStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(PostStatus status) {
    switch (status) {
      case PostStatus.pending:
        return 'Chờ phê duyệt';
      case PostStatus.approved:
        return 'Đã phê duyệt';
      case PostStatus.rejected:
        return 'Bị từ chối';
    }
  }
}
