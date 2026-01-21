import 'package:dio/dio.dart';
import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/data/models/create_post_request.dart';

abstract class PostRemoteDatasource {
  Future<PostModel> createPost(CreatePostRequest request);
  Future<List<PostModel>> getPosts({int? page, int? limit, String? source});
  Future<List<PostModel>> getMyPosts();
  Future<PostModel> getPostById(String id);
  Future<PostModel> reactToPost(String postId, String reaction);
  Future<PostModel> updatePost(String id, Map<String, dynamic> data);
  Future<void> deletePost(String id);
}

class PostRemoteDatasourceImpl implements PostRemoteDatasource {
  final ApiClient _apiClient;

  PostRemoteDatasourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<PostModel> createPost(CreatePostRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.posts,
        data: request.toJson(),
      );
      return PostModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<PostModel>> getPosts({
    int? page,
    int? limit,
    String? source,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (source != null) queryParams['source'] = source;

      final response = await _apiClient.get(
        ApiConstants.posts,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['items'] ?? [];

      return data.map((json) => PostModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<PostModel>> getMyPosts() async {
    try {
      final response = await _apiClient.get(ApiConstants.myPosts);

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['items'] ?? [];

      return data.map((json) => PostModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<PostModel> getPostById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.posts}/$id');
      return PostModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<PostModel> reactToPost(String postId, String reaction) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.posts}/$postId/react',
        data: {'type': reaction},
      );
      return PostModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<PostModel> updatePost(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.posts}/$id',
        data: data,
      );
      return PostModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deletePost(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.posts}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String message = 'Đã xảy ra lỗi';

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
    }

    return Exception(message);
  }
}