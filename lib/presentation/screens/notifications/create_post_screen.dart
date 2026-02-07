import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'package:mobile_flutter/presentation/providers/auth_provider.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
import 'package:mobile_flutter/data/models/create_post_request.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _diseaseTypeController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  // Disease types
  final List<String> _diseaseTypes = [
    'Sốt xuất huyết',
    'Tay chân miệng',
    'COVID-19',
    'Cúm mùa',
    'Sởi',
    'Thủy đậu',
    'Tiêu chảy cấp',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadLastDraft();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _diseaseTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadLastDraft() async {
    final postProvider = context.read<PostProvider>();
    await postProvider.loadDrafts();

    if (postProvider.drafts.isNotEmpty) {
      final lastDraft = postProvider.drafts.last;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tiếp tục bản nháp?'),
            content: const Text('Bạn có một bài viết chưa hoàn thành. Tiếp tục chỉnh sửa?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bỏ qua'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadDraft(lastDraft);
                },
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _loadDraft(PostModel draft) {
    setState(() {
      _contentController.text = draft.content;
      _locationController.text = draft.location ?? '';
      _diseaseTypeController.text = draft.diseaseType ?? '';
    });
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể đăng tối đa 4 ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể đăng tối đa 4 ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    print('=== DEBUG SUBMIT POST ===');
    print('Content: ${_contentController.text}');
    print('Images: ${_selectedImages.length}');

    // Check authentication
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để đăng bài'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Debug mock URLs
      final mockImageUrls = List.generate(
        _selectedImages.length,
            (index) => 'https://example.com/image_$index.jpg',
      );
      print('Mock URLs: $mockImageUrls');

      final request = CreatePostRequest(
        content: _contentController.text.trim(),
        imageUrls: mockImageUrls,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        diseaseType: _diseaseTypeController.text.trim().isNotEmpty
            ? _diseaseTypeController.text.trim()
            : null,
      );

      print('Request: ${request.toJson()}');
      print('Current user: ${authProvider.user?.name}');
      print('Current user ID: ${authProvider.user?.id}');

      final postProvider = context.read<PostProvider>();
      print('Calling createPost...');

      await postProvider.createPost(request);

      print('Create post successful!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('ERROR: $e');
      print('Stack trace: ${e.toString()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng bài lên cộng đồng'),
        actions: [
          IconButton(
            icon: _isSubmitting
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _isSubmitting ? null : _submitPost,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content input
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Nội dung bài viết *',
                  hintText: 'Chia sẻ thông tin, cảnh báo, hoặc kinh nghiệm về dịch bệnh...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  if (value.trim().length < 10) {
                    return 'Nội dung phải có ít nhất 10 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Disease type dropdown
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _diseaseTypes;
                  }
                  return _diseaseTypes.where(
                        (type) => type.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                  );
                },
                onSelected: (String selection) {
                  _diseaseTypeController.text = selection;
                },
                fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                    ) {
                  _diseaseTypeController.text = fieldTextEditingController.text;
                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Loại dịch bệnh (tùy chọn)',
                      hintText: 'Chọn hoặc nhập loại bệnh...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: () {
                          _showDiseaseTypePicker(context, fieldTextEditingController);
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Location input
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm (tùy chọn)',
                  hintText: 'Nhập địa chỉ, quận/huyện...',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Image picker section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hình ảnh đính kèm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tối đa 4 ảnh (${_selectedImages.length}/4)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Selected images grid
                      if (_selectedImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 16),

                      // Image picker buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Chọn từ thư viện'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Chụp ảnh'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Guidelines
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Hướng dẫn đăng bài',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Chia sẻ thông tin chính xác, có ích cho cộng đồng\n'
                            '• Tránh đăng thông tin sai lệch hoặc gây hoang mang\n'
                            '• Bài đăng sẽ được kiểm duyệt trước khi hiển thị công khai\n'
                            '• Vi phạm có thể bị xóa bài hoặc khóa tài khoản',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiseaseTypePicker(
      BuildContext context,
      TextEditingController controller,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chọn loại dịch bệnh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _diseaseTypes.length,
                  itemBuilder: (context, index) {
                    final disease = _diseaseTypes[index];
                    return ListTile(
                      leading: Icon(
                        Icons.coronavirus,
                        color: Colors.red.shade400,
                      ),
                      title: Text(disease),
                      onTap: () {
                        controller.text = disease;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}