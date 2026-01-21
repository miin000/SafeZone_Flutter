import 'package:hive/hive.dart';
import 'package:mobile_flutter/data/models/post_model.dart';

class PostLocalDatasource {
  static const String _postBox = 'posts_box';
  static const String _draftBox = 'draft_posts_box';

  Future<Box<PostModel>> _openPostBox() async {
    if (!Hive.isBoxOpen(_postBox)) {
      return await Hive.openBox<PostModel>(_postBox);
    }
    return Hive.box<PostModel>(_postBox);
  }

  Future<Box<Map<String, dynamic>>> _openDraftBox() async {
    if (!Hive.isBoxOpen(_draftBox)) {
      return await Hive.openBox<Map<String, dynamic>>(_draftBox);
    }
    return Hive.box<Map<String, dynamic>>(_draftBox);
  }

  // Save post locally (for offline viewing)
  Future<void> savePost(PostModel post) async {
    final box = await _openPostBox();
    await box.put(post.id, post);
  }

  // Save multiple posts
  Future<void> savePosts(List<PostModel> posts) async {
    final box = await _openPostBox();
    final Map<String, PostModel> postsMap = {
      for (var post in posts) post.id: post
    };
    await box.putAll(postsMap);
  }

  // Get all saved posts
  Future<List<PostModel>> getSavedPosts() async {
    final box = await _openPostBox();
    return box.values.toList();
  }

  // Get post by ID
  Future<PostModel?> getPostById(String id) async {
    final box = await _openPostBox();
    return box.get(id);
  }

  // Delete post locally
  Future<void> deletePost(String id) async {
    final box = await _openPostBox();
    await box.delete(id);
  }

  // Clear all posts
  Future<void> clearAllPosts() async {
    final box = await _openPostBox();
    await box.clear();
  }

  // Save draft post
  Future<void> saveDraft(Map<String, dynamic> draft) async {
    final box = await _openDraftBox();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(timestamp, draft);
  }

  // Get all drafts
  Future<List<Map<String, dynamic>>> getDrafts() async {
    final box = await _openDraftBox();
    return box.values.toList();
  }

  // Delete draft
  Future<void> deleteDraft(String key) async {
    final box = await _openDraftBox();
    await box.delete(key);
  }

  // Get posts count
  Future<int> getPostsCount() async {
    final box = await _openPostBox();
    return box.length;
  }
}