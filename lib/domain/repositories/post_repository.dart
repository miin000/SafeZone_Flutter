import '../entities/post.dart';

abstract class PostRepository {
  Future<Post> createPost({
    required String content,
    List<String> imageUrls,
    String? location,
    String? diseaseType,
    String source,
  });

  Future<List<Post>> getPosts({int page, int limit});
  Future<List<Post>> getMyPosts();
  Future<Post> getPostById(String id);
  Future<Post> reactToPost(String postId, String reaction);
  Future<void> deletePost(String id);
}
