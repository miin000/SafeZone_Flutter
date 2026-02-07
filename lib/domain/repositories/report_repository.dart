// Report Repository Interface
import '../../data/models/post_model.dart';
import '../../data/models/create_post_request.dart';

abstract class PostRepository {
  Future<PostModel> createPost(CreatePostRequest request);
  Future<List<PostModel>> getPosts({int? page, int? limit, String? source});
  Future<List<PostModel>> getMyPosts();
  Future<PostModel> getPostById(String id);
  Future<PostModel> reactToPost(String postId, String reaction);
  Future<PostModel> updatePost(String id, Map<String, dynamic> data);
  Future<void> deletePost(String id);
}