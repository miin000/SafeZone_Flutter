import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadService {
  CloudinaryUploadService._();

  static const String _cloudName = 'ddquvbdc7';
  static const String _uploadPreset = 'safezone';
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  static Future<List<String>> uploadImages({
    required List<XFile> files,
    required String folder,
  }) async {
    if (files.isEmpty) {
      return const [];
    }

    debugPrint('[Cloudinary] Start uploading ${files.length} images to $folder');
    final uploadedUrls = <String>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = _buildUploadFileName(file, i);

      if (!_isSupportedImage(fileName: fileName, mimeType: file.mimeType)) {
        throw Exception(
          'Ảnh "$fileName" không đúng định dạng. Chỉ hỗ trợ: ${_allowedExtensions.join(', ')}',
        );
      }

      final fileBytes = await file.readAsBytes();
      if (fileBytes.length > _maxFileSizeBytes) {
        throw Exception('Ảnh "$fileName" vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.');
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'upload_preset': _uploadPreset,
        'folder': folder,
      });

      try {
        debugPrint(
          '[Cloudinary] Uploading image ${i + 1}/${files.length}: $fileName (${fileBytes.length} bytes)',
        );

        final response = await Dio().post(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
          data: formData,
        );

        final secureUrl = response.data?['secure_url']?.toString();
        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception('Cloudinary không trả về secure_url hợp lệ cho $fileName');
        }

        uploadedUrls.add(secureUrl);
        debugPrint('[Cloudinary] Uploaded: $secureUrl');
      } on DioException catch (e) {
        final responseData = e.response?.data;
        String? cloudinaryMessage;
        if (responseData is Map && responseData['error'] is Map) {
          cloudinaryMessage =
              (responseData['error'] as Map)['message']?.toString();
        }
        debugPrint('[Cloudinary] DioException: ${e.message} | data: ${e.response?.data}');
        throw Exception(
          cloudinaryMessage ?? 'Không thể tải ảnh "$fileName" lên Cloudinary',
        );
      }
    }

    debugPrint('[Cloudinary] Upload completed. Total: ${uploadedUrls.length}');
    return uploadedUrls;
  }

  static String _extractFileName(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isNotEmpty ? parts.last : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  static String _buildUploadFileName(XFile file, int index) {
    final rawName = file.name.trim();
    String fileName;

    if (rawName.isNotEmpty) {
      fileName = rawName;
    } else {
      fileName = _extractFileName(file.path);
    }

    final extension = _extractExtension(fileName);
    if (extension.isNotEmpty && _allowedExtensions.contains(extension)) {
      return fileName;
    }

    final inferred = _extensionFromMimeType(file.mimeType);
    if (inferred != null) {
      return 'image_${DateTime.now().millisecondsSinceEpoch}_$index.$inferred';
    }

    return fileName;
  }

  static bool _isSupportedImage({
    required String fileName,
    required String? mimeType,
  }) {
    final extension = _extractExtension(fileName);
    if (_allowedExtensions.contains(extension)) {
      return true;
    }

    final inferred = _extensionFromMimeType(mimeType);
    if (inferred != null && _allowedExtensions.contains(inferred)) {
      return true;
    }

    return false;
  }

  static String? _extensionFromMimeType(String? mimeType) {
    final normalized = (mimeType ?? '').toLowerCase().trim();
    if (normalized.isEmpty) return null;

    switch (normalized) {
      case 'image/jpg':
      case 'image/jpeg':
      case 'image/pjpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      default:
        return null;
    }
  }

  static String _extractExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}
