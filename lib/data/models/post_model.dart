import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'user_model.dart';

// KEEP ENUMS HERE
enum PostStatus { pending, approved, rejected }

enum PostSource { government, healthWorker, citizen, verifiedUser }

class PostModel extends Equatable {
  final String id;
  final String content;
  final List<String> imageUrls;
  final PostSource source;
  final PostStatus status;
  final String? location;
  final String? diseaseType;
  final UserModel? author;
  final String authorId;
  final int helpfulCount;
  final int notHelpfulCount;
  final Map<String, String> userReactions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PostModel({
    required this.id,
    required this.content,
    this.imageUrls = const [],
    required this.source,
    this.status = PostStatus.pending,
    this.location,
    this.diseaseType,
    this.author,
    required this.authorId,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    this.userReactions = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] ?? json['user'];

    return PostModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      source: _parseSource(json['source']),
      status: _parseStatus(json['status']),
      location: json['location'],
      diseaseType: json['diseaseType'],
        author: authorJson != null
          ? UserModel.fromJson(authorJson)
          : null,
        authorId: json['authorId'] ?? json['userId'] ?? '',
      helpfulCount: json['helpfulCount'] ?? 0,
      notHelpfulCount: json['notHelpfulCount'] ?? 0,
      userReactions: json['userReactions'] != null
          ? Map<String, String>.from(json['userReactions'])
          : {},
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
    );
  }

      static DateTime _parseDateTime(dynamic raw) {
      if (raw == null) return DateTime.now();
      final value = raw.toString();
      final hasTimezone =
        value.endsWith('Z') || RegExp(r'([+-]\d{2}:?\d{2})$').hasMatch(value);
      final normalized = hasTimezone ? value : '${value}Z';
      return DateTime.parse(normalized).toLocal();
      }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'imageUrls': imageUrls,
      'source': source.name,
      'status': status.name,
      'location': location,
      'diseaseType': diseaseType,
      'authorId': authorId,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'userReactions': userReactions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static PostSource _parseSource(String? source) {
    switch (source) {
      case 'government':
        return PostSource.government;
      case 'health_worker':
        return PostSource.healthWorker;
      case 'verified_user':
        return PostSource.verifiedUser;
      default:
        return PostSource.citizen;
    }
  }

  static PostStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return PostStatus.pending;
      case 'rejected':
        return PostStatus.rejected;
      default:
        return PostStatus.approved;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  Color get sourceColor {
    switch (source) {
      case PostSource.government:
        return Colors.red.shade600;
      case PostSource.healthWorker:
        return Colors.blue.shade600;
      case PostSource.verifiedUser:
        return Colors.green.shade600;
      case PostSource.citizen:
        return Colors.grey.shade600;
    }
  }

  String get sourceText {
    switch (source) {
      case PostSource.government:
        return 'Trạm y tế chính thức';
      case PostSource.healthWorker:
        return 'Nhân viên y tế';
      case PostSource.verifiedUser:
        return 'Người dùng đã xác minh';
      case PostSource.citizen:
        return 'Công dân';
    }
  }

  IconData get sourceIcon {
    switch (source) {
      case PostSource.government:
        return Icons.verified;
      case PostSource.healthWorker:
        return Icons.medical_services;
      case PostSource.verifiedUser:
        return Icons.verified_user;
      case PostSource.citizen:
        return Icons.person;
    }
  }

  bool get isApproved => status == PostStatus.approved;

  String get authorName => author?.name ?? 'Ẩn danh';

  @override
  List<Object?> get props => [
    id,
    content,
    imageUrls,
    source,
    status,
    location,
    diseaseType,
    authorId,
    helpfulCount,
    notHelpfulCount,
    createdAt,
  ];

  PostModel copyWith({
    String? id,
    String? content,
    List<String>? imageUrls,
    PostSource? source,
    PostStatus? status,
    String? location,
    String? diseaseType,
    UserModel? author,
    String? authorId,
    int? helpfulCount,
    int? notHelpfulCount,
    Map<String, String>? userReactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      source: source ?? this.source,
      status: status ?? this.status,
      location: location ?? this.location,
      diseaseType: diseaseType ?? this.diseaseType,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      userReactions: userReactions ?? this.userReactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Thêm method empty()
  static PostModel empty() {
    return PostModel(
      id: '',
      content: '',
      source: PostSource.citizen,
      authorId: '',
      createdAt: DateTime.now(),
    );
  }
}
