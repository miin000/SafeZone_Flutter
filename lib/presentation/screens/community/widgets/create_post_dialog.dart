import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/core/constants/api_constants.dart';
import 'package:mobile_flutter/core/network/api_client.dart';
import 'package:mobile_flutter/core/services/cloudinary_upload_service.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'package:mobile_flutter/data/models/create_post_request.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  late TextEditingController _contentController;
  late TextEditingController _locationController;
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];

  List<String> _diseaseTypes = ['Dengue'];
  String? _selectedDiseaseType;
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _locationController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiseaseTypes();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadDiseaseTypes() async {
    try {
      final response = await ApiClient.instance.get(ApiConstants.diseases);
      final rows = response.data;
      if (rows is! List || !mounted) return;

      final names = rows
          .map((item) => (item is Map ? item['name']?.toString().trim() : null))
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isEmpty) return;

      setState(() {
        _diseaseTypes = names;
      });
    } catch (e) {
      debugPrint('[CreatePostDialog] Load diseases failed: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 4 ảnh cho mỗi bài viết')),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 95,
    );

    if (picked == null) return;

    setState(() {
      _selectedImages.add(picked);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tạo bài viết',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content field
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Chia sẻ thông tin của bạn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 5,
                maxLength: 2000,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                initialValue: _selectedDiseaseType,
                decoration: InputDecoration(
                  labelText: 'Loại bệnh (tùy chọn)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Không chọn'),
                  ),
                  ..._diseaseTypes.map(
                    (type) => DropdownMenuItem<String?>(
                      value: type,
                      child: Text(type),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDiseaseType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Ảnh bài viết (${_selectedImages.length}/4)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hỗ trợ: jpg, jpeg, png, webp, heic, heif. Tối đa 5MB/ảnh.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._selectedImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.network(
                                        file.path,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(file.path),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Thư viện'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Camera'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location field
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm (tùy chọn)',
                  hintText: 'Ví dụ: Hà Nội, Quốc Oai...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              Consumer<PostProvider>(
                builder: (context, postProvider, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: (postProvider.isCreatingPost || _isUploadingImages)
                            ? null
                            : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          if (_contentController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập nội dung'),
                              ),
                            );
                            return;
                          }

                          try {
                            setState(() {
                              _isUploadingImages = true;
                            });

                            final uploadedImageUrls =
                                await CloudinaryUploadService.uploadImages(
                                  files: _selectedImages,
                                  folder: 'safezone/posts',
                                );

                            debugPrint(
                              '[CreatePostDialog] Uploaded ${uploadedImageUrls.length} images',
                            );

                            final request = CreatePostRequest(
                              content: _contentController.text,
                              imageUrls: uploadedImageUrls,
                              location: _locationController.text.isEmpty
                                  ? null
                                  : _locationController.text,
                              diseaseType: _selectedDiseaseType,
                            );

                            await postProvider.createPost(request);

                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Bài viết đã được tạo!'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: ${e.toString()}'),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isUploadingImages = false;
                              });
                            }
                          }
                        },
                        icon: (postProvider.isCreatingPost || _isUploadingImages)
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.check),
                        label: Text(_isUploadingImages ? 'Đang tải ảnh...' : 'Đăng'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
