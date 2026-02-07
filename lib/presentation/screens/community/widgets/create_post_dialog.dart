import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late TextEditingController _diseaseTypeController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _locationController = TextEditingController();
    _diseaseTypeController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _diseaseTypeController.dispose();
    super.dispose();
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

              // Disease type field
              TextField(
                controller: _diseaseTypeController,
                decoration: InputDecoration(
                  labelText: 'Loại bệnh (tùy chọn)',
                  hintText: 'Ví dụ: Cúm, COVID-19...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                        onPressed: postProvider.isLoading
                            ? null
                            : () async {
                          if (_contentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập nội dung'),
                              ),
                            );
                            return;
                          }

                          try {
                            final request = CreatePostRequest(
                              content: _contentController.text,
                              location: _locationController.text.isEmpty
                                  ? null
                                  : _locationController.text,
                              diseaseType: _diseaseTypeController.text.isEmpty
                                  ? null
                                  : _diseaseTypeController.text,
                            );

                            await postProvider.createPost(request);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bài viết đã được tạo!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                        icon: postProvider.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.check),
                        label: const Text('Đăng'),
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
