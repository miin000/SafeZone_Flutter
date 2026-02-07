import 'package:flutter/material.dart'; // THÊM
import 'package:hive/hive.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/data/models/user_model.dart';
import 'package:mobile_flutter/data/models/post_model.dart';

// Register all adapters
void registerHiveAdapters() {
  // PostModel adapter
  Hive.registerAdapter(PostModelAdapter());
  Hive.registerAdapter(PostStatusAdapter());
  Hive.registerAdapter(PostSourceAdapter());

  // UserModel adapter
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(UserRoleAdapter());
}

// PostModel Adapter
class PostModelAdapter extends TypeAdapter<PostModel> {
  @override
  final int typeId = 0;

  @override
  PostModel read(BinaryReader reader) {
    try {
      final id = reader.readString();
      final content = reader.readString();
      final imageUrlsList = reader.readList();
      final imageUrls = imageUrlsList != null
          ? List<String>.from(imageUrlsList)
          : <String>[];
      final sourceIndex = reader.readByte();
      final source = sourceIndex < PostSource.values.length
          ? PostSource.values[sourceIndex]
          : PostSource.citizen;
      final statusIndex = reader.readByte();
      final status = statusIndex < PostStatus.values.length
          ? PostStatus.values[statusIndex]
          : PostStatus.pending;
      final locationStr = reader.readString();
      final location = locationStr.isEmpty ? null : locationStr;
      final diseaseTypeStr = reader.readString();
      final diseaseType = diseaseTypeStr.isEmpty ? null : diseaseTypeStr;
      final authorId = reader.readString();
      final helpfulCount = reader.readInt();
      final notHelpfulCount = reader.readInt();
      final createdAtStr = reader.readString();
      final createdAt = createdAtStr.isNotEmpty
          ? DateTime.parse(createdAtStr)
          : DateTime.now();
      
      // Handle updatedAt properly
      DateTime? updatedAt;
      try {
        final updatedAtStr = reader.readString();
        if (updatedAtStr.isNotEmpty) {
          updatedAt = DateTime.parse(updatedAtStr);
        }
      } catch (e) {
        print('Error reading updatedAt: $e');
        updatedAt = null;
      }

      return PostModel(
        id: id,
        content: content,
        imageUrls: imageUrls,
        source: source,
        status: status,
        location: location,
        diseaseType: diseaseType,
        author: null, // Author is not persisted in Hive to avoid circular references
        authorId: authorId,
        helpfulCount: helpfulCount,
        notHelpfulCount: notHelpfulCount,
        userReactions: {}, // userReactions are not persisted in Hive
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error reading PostModel: $e');
      // Return empty post on error
      return PostModel(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: '[Error reading post]',
        source: PostSource.citizen,
        authorId: 'unknown',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  void write(BinaryWriter writer, PostModel obj) {
    try {
      writer.writeString(obj.id);
      writer.writeString(obj.content);
      writer.writeList(obj.imageUrls);
      writer.writeByte(obj.source.index);
      writer.writeByte(obj.status.index);
      writer.writeString(obj.location ?? '');
      writer.writeString(obj.diseaseType ?? '');
      writer.writeString(obj.authorId);
      writer.writeInt(obj.helpfulCount);
      writer.writeInt(obj.notHelpfulCount);
      writer.writeString(obj.createdAt.toIso8601String());
      writer.writeString(obj.updatedAt?.toIso8601String() ?? '');
    } catch (e) {
      print('Error writing PostModel: $e');
    }
  }
}

// PostStatus Adapter
class PostStatusAdapter extends TypeAdapter<PostStatus> {
  @override
  final int typeId = 1;

  @override
  PostStatus read(BinaryReader reader) {
    return PostStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PostStatus obj) {
    writer.writeByte(obj.index);
  }
}

// PostSource Adapter
class PostSourceAdapter extends TypeAdapter<PostSource> {
  @override
  final int typeId = 2;

  @override
  PostSource read(BinaryReader reader) {
    return PostSource.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PostSource obj) {
    writer.writeByte(obj.index);
  }
}

// UserModel Adapter (simplified version)
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 3;

  @override
  UserModel read(BinaryReader reader) {
    final id = reader.readString();
    final emailStr = reader.readString();
    final name = reader.readString();
    final phone = reader.readString();
    final avatarUrlStr = reader.readString();
    final roleIndex = reader.readByte();
    final isEmailVerified = reader.readBool();
    final isPhoneVerified = reader.readBool();
    
    return UserModel(
      id: id,
      email: emailStr.isEmpty ? null : emailStr,
      name: name,
      phone: phone,
      avatarUrl: avatarUrlStr.isEmpty ? null : avatarUrlStr,
      role: UserRole.values[roleIndex],
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.email ?? '');
    writer.writeString(obj.name);
    writer.writeString(obj.phone);
    writer.writeString(obj.avatarUrl ?? '');
    writer.writeByte(obj.role.index);
    writer.writeBool(obj.isEmailVerified);
    writer.writeBool(obj.isPhoneVerified);
  }
}

// UserRole Adapter
class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 4;

  @override
  UserRole read(BinaryReader reader) {
    return UserRole.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    writer.writeByte(obj.index);
  }
}