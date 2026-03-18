// Health Info Model
class HealthInfo {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String? imageUrl;
  final String? source;
  final bool published;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HealthInfo({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.imageUrl,
    this.source,
    required this.published,
    required this.createdAt,
    this.updatedAt,
  });

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString().toLowerCase();
    final imageUrls = json['imageUrls'];
    String? resolvedImageUrl;
    if (json['imageUrl'] is String && (json['imageUrl'] as String).isNotEmpty) {
      resolvedImageUrl = json['imageUrl'] as String;
    } else if (json['thumbnailUrl'] is String && (json['thumbnailUrl'] as String).isNotEmpty) {
      resolvedImageUrl = json['thumbnailUrl'] as String;
    } else if (imageUrls is List && imageUrls.isNotEmpty) {
      final first = imageUrls.first;
      if (first is String && first.isNotEmpty) {
        resolvedImageUrl = first;
      }
    }

    String? resolvedSource;
    if (json['source'] is String && (json['source'] as String).isNotEmpty) {
      resolvedSource = json['source'] as String;
    } else if (json['sourceName'] is String && (json['sourceName'] as String).isNotEmpty) {
      resolvedSource = json['sourceName'] as String;
    } else if (json['sourceUrl'] is String && (json['sourceUrl'] as String).isNotEmpty) {
      resolvedSource = json['sourceUrl'] as String;
    }

    return HealthInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'],
      imageUrl: resolvedImageUrl,
      source: resolvedSource,
      published: json['published'] == true || status == 'published',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class HealthInfoResponse {
  final List<HealthInfo> data;
  final PaginationMeta? meta;

  HealthInfoResponse({required this.data, this.meta});

  factory HealthInfoResponse.fromJson(Map<String, dynamic> json) {
    return HealthInfoResponse(
      data: (json['data'] as List?)
          ?.map((e) => HealthInfo.fromJson(e))
          .toList() ??
          [],
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'])
          : null,
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
