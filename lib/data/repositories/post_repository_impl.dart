import 'package:mobile_flutter/data/datasources/remote/post_remote_datasource.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/data/models/create_post_request.dart';

// Định nghĩa abstract repository interface
abstract class PostRepository {
  Future<PostModel> createPost(CreatePostRequest request);
  Future<List<PostModel>> getPosts({int? page, int? limit, String? source});
  Future<List<PostModel>> getMyPosts();
  Future<PostModel> getPostById(String id);
  Future<PostModel> reactToPost(String postId, String reaction);
  Future<PostModel> updatePost(String id, Map<String, dynamic> data);
  Future<void> deletePost(String id);
}

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDatasource _remoteDatasource;

  PostRepositoryImpl({PostRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? PostRemoteDatasourceImpl();

  @override
  Future<PostModel> createPost(CreatePostRequest request) async {
    print('=== REPOSITORY: createPost ===');
    print('Request: ${request.toJson()}');

    try {
      // GỌI API THẬT - không dùng mock fallback!
      final response = await _remoteDatasource.createPost(request);
      print(' Post created successfully: ${response.id}');
      return response;

    } catch (e) {
      print(' Repository error: $e');
      rethrow; // Ném lỗi để UI xử lý
    }
  }

  PostSource _parseSource(String source) {
    switch (source) {
      case 'health_worker':
        return PostSource.healthWorker;
      case 'verified_user':
        return PostSource.verifiedUser;
      case 'government':
        return PostSource.government;
      default:
        return PostSource.citizen;
    }
  }

  @override
  Future<List<PostModel>> getPosts({
    int? page,
    int? limit,
    String? source,
  }) {
    return _remoteDatasource.getPosts(
      page: page,
      limit: limit,
      source: source,
    );
  }

  @override
  Future<List<PostModel>> getMyPosts() {
    return _remoteDatasource.getMyPosts();
  }

  @override
  Future<PostModel> getPostById(String id) {
    return _remoteDatasource.getPostById(id);
  }

  @override
  Future<PostModel> reactToPost(String postId, String reaction) {
    return _remoteDatasource.reactToPost(postId, reaction);
  }

  @override
  Future<PostModel> updatePost(String id, Map<String, dynamic> data) {
    return _remoteDatasource.updatePost(id, data);
  }

  @override
  Future<void> deletePost(String id) {
    return _remoteDatasource.deletePost(id);
  }
}
