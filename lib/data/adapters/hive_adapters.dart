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
      final location = reader.readStringOrNull();
      final diseaseType = reader.readStringOrNull();
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
        final updatedAtStr = reader.readStringOrNull();
        if (updatedAtStr != null && updatedAtStr.isNotEmpty) {
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
        authorId: authorId,
        helpfulCount: helpfulCount,
        notHelpfulCount: notHelpfulCount,
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
    return UserModel(
      id: reader.readString(),
      email: reader.readString(),
      name: reader.readString(),
      phone: reader.readStringOrNull(),
      avatarUrl: reader.readStringOrNull(),
      role: UserRole.values[reader.readByte()],
      isEmailVerified: reader.readBool(),
      isPhoneVerified: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.name);
    writer.writeString(obj.phone ?? '');
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

// Extension for nullable string reading
extension BinaryReaderExtensions on BinaryReader {
  String? readStringOrNull() {
    final hasValue = readBool();
    return hasValue ? readString() : null;
  }
}