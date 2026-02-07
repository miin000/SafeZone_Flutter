import 'package:flutter/foundation.dart';
import 'package:mobile_flutter/data/datasources/local/post_local_datasource.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/data/models/create_post_request.dart';
import 'package:mobile_flutter/data/repositories/post_repository_impl.dart';
import 'package:mobile_flutter/data/models/user_model.dart';

class PostProvider extends ChangeNotifier {
  final PostRepositoryImpl _repository;
  final PostLocalDatasource _localDatasource;
  UserModel? _currentUser;

  PostProvider({
    PostRepositoryImpl? repository,
    required PostLocalDatasource localDatasource,
    UserModel? currentUser,
  })  : _repository = repository ?? PostRepositoryImpl(),
        _localDatasource = localDatasource,
        _currentUser = currentUser;

  // THÊM: Setter cho current user
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  // State
  List<PostModel> _posts = [];
  List<PostModel> _drafts = [];
  bool _hasMorePosts = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<PostModel> get posts => List.unmodifiable(_posts);
  List<PostModel> get drafts => List.unmodifiable(_drafts);
  bool get hasMorePosts => _hasMorePosts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  UserModel? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _setInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  // Method để thêm post trực tiếp (cho mock data và testing)
  void addPostDirectly(PostModel post) {
    print('=== ADDING POST DIRECTLY ===');
    print('Post ID: ${post.id}');

    // Kiểm tra xem post đã tồn tại chưa
    final existingIndex = _posts.indexWhere((p) => p.id == post.id);
    if (existingIndex != -1) {
      // Update existing post
      _posts[existingIndex] = post;
    } else {
      // Add new post at the beginning
      _posts.insert(0, post);
    }

    // Cũng lưu vào local storage
    _localDatasource.savePosts([post]);

    notifyListeners();
    print('Post added successfully. Total posts: ${_posts.length}');
  }

  // ========== CÁC METHOD BỊ THIẾU ==========

  // Method 1: _loadFromLocal
  Future<void> _loadFromLocal() async {
    try {
      final localPosts = await _localDatasource.getSavedPosts();
      if (localPosts.isNotEmpty) {
        _posts = localPosts;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading from local: $e');
    }
  }

  // Method 2: loadDrafts
  Future<void> loadDrafts() async {
    try {
      final draftMaps = await _localDatasource.getDrafts();
      _drafts = draftMaps.map((draft) {
        return PostModel(
          id: 'draft_${draft['createdAt']}',
          content: draft['content'] ?? '',
          imageUrls: draft['imagePaths'] != null
              ? List<String>.from(draft['imagePaths'])
              : [],
          source: _parseSource(draft['source'] ?? 'citizen'),
          status: PostStatus.pending,
          location: draft['location'],
          diseaseType: draft['diseaseType'],
          authorId: 'draft_user',
          createdAt: DateTime.parse(draft['createdAt'] ?? DateTime.now().toIso8601String()),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading drafts: $e');
    }
  }

  // Method 3: loadMorePosts
  Future<void> loadMorePosts() async {
    if (_isLoading || !_hasMorePosts) return;

    _setLoading(true);
    _setError(null);

    try {
      final newPosts = await _repository.getPosts(
        page: _currentPage,
        limit: _pageSize,
      );

      if (newPosts.length < _pageSize) {
        _hasMorePosts = false;
      }

      // Save to local storage
      await _localDatasource.savePosts(newPosts);

      // Add to existing posts
      _posts.addAll(newPosts);
      _currentPage++;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      // Fallback to local data if network fails
      await _loadFromLocal();
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Method 4: initialize
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _setError(null);

    try {
      await _loadFromLocal();
      await loadDrafts();
      await loadMorePosts();
      _setInitialized(true);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Method 5: refreshPosts
  Future<void> refreshPosts() async {
    _currentPage = 1;
    _hasMorePosts = true;
    _posts.clear();
    await loadMorePosts();
  }

  // Method 6: getPostById
  PostModel? getPostById(String id) {
    return _posts.firstWhere(
          (post) => post.id == id,
      orElse: () => _drafts.firstWhere(
            (draft) => draft.id == id,
        orElse: () => PostModel.empty(),
      ),
    );
  }

  // Method 7: saveDraft
  Future<void> saveDraft({
    required String content,
    List<String> imagePaths = const [],
    String? location,
    String? diseaseType,
    String source = 'citizen',
  }) async {
    final draft = {
      'content': content,
      'imagePaths': imagePaths,
      'location': location,
      'diseaseType': diseaseType,
      'source': source,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _localDatasource.saveDraft(draft);
    await loadDrafts();
  }

  // Method để load posts cho notifications screen
  Future<void> loadPostsForNotifications() async {
    if (_isLoading) return;

    _setLoading(true);
    _setError(null);

    try {
      final newPosts = await _repository.getPosts(
        page: _currentPage,
        limit: _pageSize,
      );

      if (newPosts.length < _pageSize) {
        _hasMorePosts = false;
      }

      // Thêm vào danh sách hiện tại (không xóa cũ)
      _posts.addAll(newPosts);
      _currentPage++;

      // Lưu vào local storage
      await _localDatasource.savePosts(newPosts);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      // Fallback to local data
      await _loadFromLocal();
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Sửa method createPost để hoạt động đúng
  Future<PostModel> createPost(CreatePostRequest request) async {
    print('=== PROVIDER: createPost ===');
    print('Request: ${request.toJson()}');

    _setLoading(true);
    _setError(null);

    try {
      // Gọi repository
      final newPost = await _repository.createPost(request);

      // THÊM: Cập nhật author info nếu có current user
      final postWithAuthor = newPost.copyWith(
        author: _currentUser,
        authorId: _currentUser?.id ?? 'anonymous',
      );

      print('Post created: ${postWithAuthor.id}');

      // Thêm vào danh sách
      _posts.insert(0, postWithAuthor);

      // Lưu vào local storage
      await _localDatasource.savePosts([postWithAuthor]);

      _setLoading(false);
      notifyListeners();

      print('Post added to list. Total: ${_posts.length}');
      return postWithAuthor;

    } catch (e) {
      print('Provider error: $e');
      _setError('Không thể tạo bài viết: ${e.toString()}');
      _setLoading(false);
      rethrow;
    }
  }

  // Update post
  Future<PostModel> updatePost(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedPost = await _repository.updatePost(id, data);

      // Update in local list
      final index = _posts.indexWhere((post) => post.id == id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      // Update local storage
      await _localDatasource.savePosts([updatedPost]);

      _setLoading(false);
      notifyListeners();
      return updatedPost;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      await _repository.deletePost(id);

      // Remove from local list
      _posts.removeWhere((post) => post.id == id);

      // Remove from local storage
      await _localDatasource.deletePost(id);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      rethrow;
    }
  }

  // React to post
  Future<PostModel> reactToPost(String postId, String reaction) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedPost = await _repository.reactToPost(postId, reaction);

      // Update in local list
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      _setLoading(false);
      notifyListeners();
      return updatedPost;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      rethrow;
    }
  }

  // Get my posts
  Future<List<PostModel>> getMyPosts() async {
    _setLoading(true);
    _setError(null);

    try {
      final myPosts = await _repository.getMyPosts();
      _setLoading(false);
      return myPosts;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      rethrow;
    }
  }

  // Delete draft
  Future<void> deleteDraft(String draftId) async {
    try {
      // Extract timestamp from draft ID
      final timestamp = draftId.replaceFirst('draft_', '');
      await _localDatasource.deleteDraft(timestamp);
      await loadDrafts();
    } catch (e) {
      _setError('Không thể xóa bản nháp: ${e.toString()}');
    }
  }

  // Clear all data
  void clear() {
    _posts.clear();
    _drafts.clear();
    _currentPage = 1;
    _hasMorePosts = true;
    _isInitialized = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    _setLoading(true);
    _setError(null);

    try {
      final filteredPosts = _posts.where((post) {
        return post.content.toLowerCase().contains(query.toLowerCase()) ||
            (post.location?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (post.diseaseType?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();

      _setLoading(false);
      return filteredPosts;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return [];
    }
  }

  // Filter posts by source
  Future<List<PostModel>> filterBySource(PostSource source) async {
    _setLoading(true);
    _setError(null);

    try {
      final filteredPosts = await _repository.getPosts(
        page: 1,
        limit: 20,
        source: source.toString().split('.').last,
      );

      _setLoading(false);
      return filteredPosts;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return [];
    }
  }

  // ========== HELPER METHODS ==========

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

  // THÊM: Method để thêm mock data cho testing (KHÔNG dùng MockPosts)
  void addMockPostsForTesting() {
    print('=== ADDING MOCK POSTS FOR TESTING ===');

    // Tạo mock user
    final mockUser = UserModel(
      id: 'test_user_001',
      email: 'test@example.com',
      name: 'Người dùng thử nghiệm',
      role: UserRole.user,
      isEmailVerified: true,
      isPhoneVerified: true,
    );

    // Tạo một vài mock posts
    final mockPosts = [
      PostModel(
        id: 'test_post_001',
        content: 'Đây là bài viết thử nghiệm đầu tiên. Khu vực quận Hoàn Kiếm đang có dịch sốt xuất huyết, mọi người chú ý phòng tránh!',
        imageUrls: ['https://picsum.photos/400/300?random=1'],
        source: PostSource.government,
        status: PostStatus.approved,
        location: 'Quận Hoàn Kiếm, Hà Nội',
        diseaseType: 'Sốt xuất huyết',
        author: mockUser,
        authorId: mockUser.id,
        helpfulCount: 42,
        notHelpfulCount: 2,
        userReactions: {},
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      PostModel(
        id: 'test_post_002',
        content: 'Thông báo: Trung tâm y tế quận Đống Đa tổ chức tiêm vaccine COVID-19 miễn phí trong tuần này.',
        imageUrls: [],
        source: PostSource.healthWorker,
        status: PostStatus.approved,
        location: 'Quận Đống Đa, Hà Nội',
        diseaseType: 'COVID-19',
        author: mockUser,
        authorId: mockUser.id,
        helpfulCount: 35,
        notHelpfulCount: 1,
        userReactions: {},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PostModel(
        id: 'test_post_003',
        content: 'Nhà tôi ở phường Trung Hòa vừa có trẻ bị tay chân miệng. Các phụ huynh trong khu vực chú ý theo dõi con em!',
        imageUrls: ['https://picsum.photos/400/300?random=2'],
        source: PostSource.citizen,
        status: PostStatus.approved,
        location: 'Phường Trung Hòa, Cầu Giấy',
        diseaseType: 'Tay chân miệng',
        author: mockUser,
        authorId: mockUser.id,
        helpfulCount: 28,
        notHelpfulCount: 3,
        userReactions: {},
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Thêm vào danh sách
    for (final post in mockPosts) {
      addPostDirectly(post);
    }

    print('✅ Added ${mockPosts.length} mock posts for testing');
  }
}