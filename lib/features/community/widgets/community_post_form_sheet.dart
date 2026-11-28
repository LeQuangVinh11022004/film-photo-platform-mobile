import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/community_post_api_models.dart';
import '../services/community_post_api_service.dart';

Future<String?> showCommunityPostFormSheet({
  required BuildContext context,
  required CommunityPostApiService apiService,
  CommunityPostResponseDTO? existing,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CommunityPostFormSheetContent(
      apiService: apiService,
      existing: existing,
    ),
  );
}

class _CommunityPostFormSheetContent extends StatefulWidget {
  final CommunityPostApiService apiService;
  final CommunityPostResponseDTO? existing;

  const _CommunityPostFormSheetContent({
    required this.apiService,
    this.existing,
  });

  @override
  State<_CommunityPostFormSheetContent> createState() =>
      _CommunityPostFormSheetContentState();
}

class _CommunityPostFormSheetContentState
    extends State<_CommunityPostFormSheetContent> {
  static const List<String> _defaultCategories = [
    'Kỹ thuật chụp Film',
    'Tráng rọi Phòng tối',
    'Đánh giá Thiết bị & Film',
    'Kinh nghiệm Ánh sáng Studio',
    'Góc Ảnh Film Cộng Đồng',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageCaptionController;
  late final List<String> _categories;
  late String _selectedCategory;

  String? _selectedImageUrl;
  XFile? _selectedImageFile;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _contentController = TextEditingController(text: existing?.content ?? '');
    _imageCaptionController = TextEditingController(
      text: (existing != null && existing.images.isNotEmpty)
          ? (existing.images.first.caption ?? '')
          : '',
    );

    _categories = List<String>.from(_defaultCategories);
    _selectedCategory =
        (existing?.category != null && existing!.category!.trim().isNotEmpty)
            ? existing.category!.trim()
            : _categories.first;
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }

    _selectedImageUrl = (existing != null && existing.images.isNotEmpty)
        ? existing.images.first.imageUrl
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageCaptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImageFile = image;
          _selectedImageUrl = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở thư viện ảnh: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || title.length > 255 || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập nội dung và tiêu đề tối đa 255 ký tự.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if ((_selectedImageFile != null || _selectedImageUrl != null) &&
        _imageCaptionController.text.trim().length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chú thích ảnh tối đa 500 ký tự.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (_selectedImageFile != null) {
      final uploadResult =
          await widget.apiService.uploadPostImage(_selectedImageFile!);
      if (!mounted) return;
      if (uploadResult['success'] != true) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadResult['message']?.toString() ?? 'Không thể tải ảnh lên.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _selectedImageUrl = uploadResult['imageUrl'] as String;
      _selectedImageFile = null;
    }

    final List<CommunityPostImageWriteRequestDTO> imageDtos = [];
    if (_selectedImageUrl != null && _selectedImageUrl!.trim().isNotEmpty) {
      imageDtos.add(
        CommunityPostImageWriteRequestDTO(
          imageUrl: _selectedImageUrl!.trim(),
          caption: _imageCaptionController.text.trim().isNotEmpty
              ? _imageCaptionController.text.trim()
              : title,
          displayOrder: 0,
        ),
      );
    }
    if (widget.existing != null) {
      imageDtos.addAll(
        widget.existing!.images.skip(1).map(
              (image) => CommunityPostImageWriteRequestDTO(
                imageUrl: image.imageUrl,
                caption: image.caption,
                displayOrder: image.displayOrder,
              ),
            ),
      );
    }

    final requestDto = CommunityPostWriteRequestDTO(
      title: title,
      content: content,
      category: _selectedCategory,
      images: imageDtos,
    );

    final Map<String, dynamic> res = _isEditing
        ? await widget.apiService.updatePost(
            postId: widget.existing!.postId,
            request: requestDto,
          )
        : await widget.apiService.createPost(requestDto);

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.pop(context, title);
    } else {
      setState(() => _isSubmitting = false);
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Không thể lưu bài đăng'),
        description: Text(
          res['message']?.toString() ?? 'Vui lòng kiểm tra lại kết nối.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing
                  ? 'Chỉnh Sửa Bài Đăng Cộng Đồng'
                  : 'Đăng Bài Chia Sẻ Cộng Đồng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Danh mục bài đăng',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề bài đăng',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Nội dung chia sẻ cùng cộng đồng...',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _isSubmitting ? null : _pickImage,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _selectedImageFile == null
                          ? 'Chọn ảnh từ thư viện'
                          : 'Chọn ảnh khác',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedImageFile != null || _selectedImageUrl != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _selectedImageFile != null
                        ? Image.file(
                            File(_selectedImageFile!.path),
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : SafeNetworkImage(
                            url: _selectedImageUrl!,
                            width: double.infinity,
                            height: 160,
                            borderRadius: BorderRadius.circular(16),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _selectedImageFile = null;
                                  _selectedImageUrl = null;
                                });
                              },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _imageCaptionController,
                decoration: InputDecoration(
                  labelText: 'Chú thích ảnh (tùy chọn)',
                  filled: true,
                  fillColor: context.inputColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Lưu Thay Đổi' : 'Đăng Bài Ngay',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
