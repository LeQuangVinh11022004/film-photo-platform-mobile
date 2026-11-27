import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/blog_post.dart';
import '../models/community_post_api_models.dart';
import '../services/community_post_api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityPostApiService _communityPostApiService =
      CommunityPostApiService();

  List<BlogPost> _posts = [];
  List<CommunityPostResponseDTO> _myCommunityPosts = [];

  bool _isLoadingFeed = true;
  bool _isLoadingMyPosts = false;
  bool _myPostsError = false;
  bool _feedError = false;

  /// Chế độ hiển thị:
  /// 0 = Diễn đàn Chung (GET /api/community/posts)
  /// 1 = Bài đăng Cộng đồng của tôi (GET/POST/PUT/DELETE /api/community/posts/mine)
  int _viewMode = 0;

  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Tất cả',
    'Chuyên gia',
    'Kỹ thuật Film',
    'Phòng tối',
    'Thiết bị',
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showFab) {
        setState(() => _showFab = true);
      } else if (_scrollController.offset <= 300 && _showFab) {
        setState(() => _showFab = false);
      }
    });
    _loadCommunityFeed();
    _loadMyCommunityPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Gọi GET /api/community/posts cho Diễn đàn chung.
  Future<void> _loadCommunityFeed({String? category}) async {
    if (!mounted) return;
    setState(() => _isLoadingFeed = true);

    try {
      final page = await _communityPostApiService.getFeed(
          category: category,
          page: 1,
          pageSize: 50,
        );
      if (!mounted) return;
      setState(() {
        _feedError = page == null;
        if (page != null) {
          _posts = page.items.map((dto) => dto.toBlogPost()).toList();
        }
        _isLoadingFeed = false;
      });
    } catch (e) {
      debugPrint('Không thể tải bài đăng cộng đồng: $e');
      if (!mounted) return;
      setState(() {
        _feedError = true;
        _isLoadingFeed = false;
      });
    }
  }

  /// Gọi GET /api/community/posts/mine cho cả PHOTOGRAPHER và EXPERT
  Future<void> _loadMyCommunityPosts() async {
    if (!mounted) return;
    setState(() => _isLoadingMyPosts = true);

    try {
      final page = await _communityPostApiService.getMyPosts(
        page: 1,
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _myPostsError = page == null;
        if (page != null) _myCommunityPosts = page.items;
        _isLoadingMyPosts = false;
      });
    } catch (e) {
      debugPrint('Không thể tải bài đăng của bạn: $e');
      if (!mounted) return;
      setState(() {
        _myPostsError = true;
        _isLoadingMyPosts = false;
      });
    }
  }

  List<BlogPost> get _filteredPosts {
    List<BlogPost> list = _posts;

    if (_selectedFilterIndex == 1) {
      list = list
          .where((p) =>
              p.authorRole.toLowerCase().contains('chuyên gia'))
          .toList();
    } else if (_selectedFilterIndex == 2) {
      list = list
          .where((p) =>
              p.category.toLowerCase().contains('kỹ thuật') ||
              p.title.toLowerCase().contains('kỹ thuật') ||
              p.title.toLowerCase().contains('iso'))
          .toList();
    } else if (_selectedFilterIndex == 3) {
      list = list
          .where((p) =>
              p.category.toLowerCase().contains('darkroom') ||
              p.category.toLowerCase().contains('phòng tối') ||
              p.category.toLowerCase().contains('tráng') ||
              p.title.toLowerCase().contains('phòng tối') ||
              p.title.toLowerCase().contains('tráng'))
          .toList();
    } else if (_selectedFilterIndex == 4) {
      list = list
          .where((p) =>
              p.category.toLowerCase().contains('thiết bị') ||
              p.category.toLowerCase().contains('camera') ||
              p.title.toLowerCase().contains('film') ||
              p.title.toLowerCase().contains('kodak'))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.content.toLowerCase().contains(q) ||
              p.authorName.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  List<CommunityPostResponseDTO> get _filteredMyCommunityPosts {
    if (_searchQuery.isEmpty) return _myCommunityPosts;
    final q = _searchQuery.toLowerCase();
    return _myCommunityPosts
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.content.toLowerCase().contains(q) ||
            (p.category ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// PUT /api/community/posts/{postId}/like & DELETE /api/community/posts/{postId}/like
  Future<void> _handleLike(BlogPost post) async {
    final bool wasLiked = post.userReaction == 'like';
    setState(() {
      if (wasLiked) {
        post.userReaction = null;
        if (post.likes > 0) post.likes--;
      } else {
        if (post.userReaction == 'dislike') {
          if (post.dislikes > 0) post.dislikes--;
        }
        post.userReaction = 'like';
        post.likes++;
      }
    });

    if (post.isCommunityPost && post.id.length >= 32) {
      final bool ok = wasLiked
          ? await _communityPostApiService.unlikePost(post.id)
          : await _communityPostApiService.likePost(post.id);

      if (!ok && mounted) {
        // Hoàn tác nếu API lỗi
        setState(() {
          if (wasLiked) {
            post.userReaction = 'like';
            post.likes++;
          } else {
            post.userReaction = null;
            if (post.likes > 0) post.likes--;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật lượt thích.')),
        );
      } else {
        _loadMyCommunityPosts();
      }
    }
  }

  bool _isMyCommunityPost(String postId, String? authorUserId) {
    if (_myCommunityPosts.any((p) => p.postId == postId)) return true;
    final userId = AuthService().currentUser?.userId;
    return userId != null && userId.isNotEmpty && userId == authorUserId;
  }

  /// Xem chi tiết bài đăng cộng đồng.
  Future<void> _showPostDetailModal({
    BlogPost? post,
    CommunityPostResponseDTO? communityPost,
  }) async {
    CommunityPostResponseDTO? loadedCommunityPost = communityPost;
    final String targetId = communityPost?.postId ?? post?.id ?? '';

    if (targetId.length >= 32) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      loadedCommunityPost = await _communityPostApiService.getPostDetail(targetId);

      if (!mounted) return;
      Navigator.pop(context);
      if (loadedCommunityPost == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải chi tiết bài đăng.')),
        );
        return;
      }
    }

    if (!mounted) return;

    final displayTitle = loadedCommunityPost?.title ??
        post?.title ??
        '';
    final displayContent = loadedCommunityPost?.content ??
        post?.content ??
        '';
    final displayAuthor = loadedCommunityPost?.authorName ??
        post?.authorName ??
        'Thành viên Film';
    final displayCategory = loadedCommunityPost?.category ??
        post?.category ??
        'Kỹ thuật Film';
    final displayStatus = loadedCommunityPost?.status ??
        post?.status ??
        'PUBLISHED';
    final displayTime = loadedCommunityPost != null
        ? CommunityPostResponseDTO.formatTimeAgo(
            loadedCommunityPost.updatedAt ?? loadedCommunityPost.createdAt)
        : (post?.timeAgo ?? 'Vừa xong');

    final List<String> displayImages = loadedCommunityPost != null &&
            loadedCommunityPost.images.isNotEmpty
        ? loadedCommunityPost.images.map((e) => e.imageUrl).toList()
        : (post?.imageUrl != null ? [post!.imageUrl!] : []);

    final bool isMyOwnCommPost = loadedCommunityPost != null &&
        _isMyCommunityPost(
          loadedCommunityPost.postId,
          loadedCommunityPost.userId,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildArticleStatusBadge(displayStatus),
                  const Spacer(),
                  Text(
                    displayTime,
                    style: TextStyle(fontSize: 12, color: context.textSecColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tác giả: $displayAuthor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              if (displayImages.isNotEmpty) ...[
                ...displayImages.map(
                  (imgUrl) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SafeNetworkImage(
                      url: imgUrl,
                      width: double.infinity,
                      height: 210,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                displayContent,
                style: TextStyle(
                  fontSize: 15,
                  color: context.textColor,
                  height: 1.65,
                ),
              ),
              if (loadedCommunityPost != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      loadedCommunityPost.isLiked
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: loadedCommunityPost.isLiked
                          ? AppColors.primary
                          : context.textSecColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${loadedCommunityPost.likeCount} lượt thích',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecColor,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: context.textSecColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${loadedCommunityPost.commentCount} bình luận',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCommentsModal(
                          post ?? loadedCommunityPost!.toBlogPost(),
                        );
                      },
                      icon: const Icon(Icons.forum_outlined, size: 17),
                      label: const Text('Mở Bình Luận'),
                    ),
                  ],
                ),
              ],
              if (isMyOwnCommPost) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCommunityPostFormModal(
                            existing: loadedCommunityPost,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Sửa bài đăng'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleDeleteCommunityPost(loadedCommunityPost!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Xóa bài đăng'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Modal Tạo mới (POST /api/community/posts) hoặc Cập nhật (PUT /api/community/posts/{postId})
  /// dành cho cả PHOTOGRAPHER và EXPERT
  void _showCommunityPostFormModal({CommunityPostResponseDTO? existing}) {
    final isEditing = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController =
        TextEditingController(text: existing?.content ?? '');
    final imageCaptionController = TextEditingController(
      text: (existing != null && existing.images.isNotEmpty)
          ? (existing.images.first.caption ?? '')
          : '',
    );
    final categories = [
      'Kỹ thuật chụp Film',
      'Tráng rọi Phòng tối',
      'Đánh giá Thiết bị & Film',
      'Kinh nghiệm Ánh sáng Studio',
      'Góc Ảnh Film Cộng Đồng',
    ];
    String selectedCategory =
        (existing?.category != null && existing!.category!.trim().isNotEmpty)
            ? existing.category!.trim()
            : categories.first;
    if (!categories.contains(selectedCategory)) categories.add(selectedCategory);

    String? selectedImageUrl =
        (existing != null && existing.images.isNotEmpty)
            ? existing.images.first.imageUrl
            : null;
    XFile? selectedImageFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
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
                    isEditing
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
                    initialValue: selectedCategory,
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
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
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
                    controller: contentController,
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
                  OutlinedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            try {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                                maxWidth: 2000,
                                maxHeight: 2000,
                              );
                              if (image != null && modalCtx.mounted) {
                                setModalState(() {
                                  selectedImageFile = image;
                                  selectedImageUrl = null;
                                });
                              }
                            } catch (e) {
                              if (!modalCtx.mounted) return;
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                SnackBar(
                                  content: Text('Không thể mở thư viện ảnh: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      selectedImageFile == null
                          ? 'Chọn ảnh từ thư viện'
                          : 'Chọn ảnh khác',
                    ),
                  ),
                  if (selectedImageFile != null || selectedImageUrl != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: selectedImageFile != null
                              ? Image.file(
                                  File(selectedImageFile!.path),
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                )
                              : SafeNetworkImage(
                                  url: selectedImageUrl!,
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
                              onPressed: () {
                                setModalState(() {
                                  selectedImageFile = null;
                                  selectedImageUrl = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageCaptionController,
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
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final content = contentController.text.trim();
                              if (title.isEmpty || title.length > 255 || content.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nhập nội dung và tiêu đề tối đa 255 ký tự.',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              final List<CommunityPostImageWriteRequestDTO>
                                  imageDtos = [];
                              if ((selectedImageFile != null ||
                                      selectedImageUrl != null) &&
                                  imageCaptionController.text.trim().length >
                                      500) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Chú thích ảnh tối đa 500 ký tự.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);

                              if (selectedImageFile != null) {
                                final uploadResult =
                                    await _communityPostApiService.uploadPostImage(
                                  selectedImageFile!,
                                );
                                if (uploadResult['success'] != true) {
                                  if (!modalCtx.mounted) return;
                                  setModalState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        uploadResult['message']?.toString() ??
                                            'Không thể tải ảnh lên.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }
                                selectedImageUrl =
                                    uploadResult['imageUrl'] as String;
                                selectedImageFile = null;
                              }

                              if (selectedImageUrl != null &&
                                  selectedImageUrl!.trim().isNotEmpty) {
                                imageDtos.add(
                                  CommunityPostImageWriteRequestDTO(
                                    imageUrl: selectedImageUrl!.trim(),
                                    caption: imageCaptionController.text
                                            .trim()
                                            .isNotEmpty
                                        ? imageCaptionController.text.trim()
                                        : title,
                                    displayOrder: 0,
                                  ),
                                );
                              }
                              if (existing != null) {
                                imageDtos.addAll(existing.images.skip(1).map(
                                      (image) => CommunityPostImageWriteRequestDTO(
                                        imageUrl: image.imageUrl,
                                        caption: image.caption,
                                        displayOrder: image.displayOrder,
                                      ),
                                    ));
                              }

                              final requestDto = CommunityPostWriteRequestDTO(
                                title: title,
                                content: content,
                                category: selectedCategory,
                                images: imageDtos,
                              );

                              final Map<String, dynamic> res;
                              if (isEditing) {
                                res = await _communityPostApiService.updatePost(
                                  postId: existing.postId,
                                  request: requestDto,
                                );
                              } else {
                                res = await _communityPostApiService
                                    .createPost(requestDto);
                              }

                              if (res['success'] == true) {
                                if (!modalCtx.mounted) return;
                                Navigator.pop(modalCtx);
                                await Future.wait([
                                  _loadCommunityFeed(),
                                  _loadMyCommunityPosts(),
                                ]);
                                if (!mounted) return;
                                toastification.show(
                                  context: context,
                                  type: ToastificationType.success,
                                  style: ToastificationStyle.flatColored,
                                  title: Text(
                                    isEditing
                                        ? 'Đã cập nhật bài đăng!'
                                        : 'Đăng bài cộng đồng thành công!',
                                  ),
                                  description: Text(
                                    'Bài đăng "$title" đã được đồng bộ lên Diễn đàn Cộng đồng.',
                                  ),
                                  alignment: Alignment.topCenter,
                                  autoCloseDuration:
                                      const Duration(seconds: 4),
                                  showProgressBar: false,
                                );
                              } else {
                                if (!modalCtx.mounted || !mounted) return;
                                setModalState(() => isSubmitting = false);
                                toastification.show(
                                  context: context,
                                  type: ToastificationType.error,
                                  style: ToastificationStyle.flatColored,
                                  title: const Text('Không thể lưu bài đăng'),
                                  description: Text(
                                    res['message']?.toString() ??
                                        'Vui lòng kiểm tra lại kết nối.',
                                  ),
                                  alignment: Alignment.topCenter,
                                  autoCloseDuration:
                                      const Duration(seconds: 4),
                                  showProgressBar: false,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing ? 'Lưu Thay Đổi' : 'Đăng Bài Ngay',
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
        },
      ),
    );
  }

  /// DELETE /api/community/posts/{postId}
  Future<void> _handleDeleteCommunityPost(
      CommunityPostResponseDTO post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài đăng cộng đồng?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài đăng "${post.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await _communityPostApiService.deletePost(post.postId);
    if (!mounted) return;

    if (ok) {
      await Future.wait([
        _loadMyCommunityPosts(),
        _loadCommunityFeed(),
      ]);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Đã xóa bài đăng cộng đồng'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Xóa bài đăng thất bại'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
    }
  }

  Widget _buildArticleStatusBadge(String status) {
    final isPub = status.toUpperCase() == 'PUBLISHED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPub ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPub ? 'Đã xuất bản' : 'Bản nháp',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPub ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }

  /// Modal Bình luận tích hợp đầy đủ:
  /// - GET /api/community/posts/{postId}/comments
  /// - POST /api/community/posts/{postId}/comments (hỗ trợ cả parentCommentId)
  /// - PUT /api/community/posts/{postId}/comments/{commentId}
  /// - DELETE /api/community/posts/{postId}/comments/{commentId}
  void _showCommentsModal(BlogPost post) {
    final commentController = TextEditingController();
    final bool isLiveCommunityPost =
        post.isCommunityPost && post.id.length >= 32;

    List<CommunityCommentResponseDTO> apiComments = [];
    bool isLoadingComments = isLiveCommunityPost;
    bool hasRequestedComments = false;
    bool commentsError = false;
    bool isSending = false;
    CommunityCommentResponseDTO? replyingTo;
    CommunityCommentResponseDTO? editingComment;

    final List<Map<String, String>> fallbackComments = [
      {
        'author': 'An Nhiên',
        'text': 'Bài viết chia sẻ rất bổ ích, cảm ơn bạn!',
        'time': '30 phút trước',
      },
      {
        'author': 'Minh Đức Film',
        'text': 'Tone màu này tráng D-76 ra cực đậm và chi tiết.',
        'time': '1 giờ trước',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          Future<void> fetchLiveComments() async {
            if (!isLiveCommunityPost || !modalCtx.mounted) return;
            setModalState(() => isLoadingComments = true);
            final page = await _communityPostApiService.getComments(
              postId: post.id,
              page: 1,
              pageSize: 50,
            );
            if (!modalCtx.mounted) return;
            setModalState(() {
              commentsError = page == null;
              if (page != null) apiComments = page.items;
              isLoadingComments = false;
            });
            if (mounted && page != null) {
              setState(() {
                post.commentsCount = page.totalCount > 0
                    ? page.totalCount
                    : apiComments.length;
              });
            }
          }

          if (!hasRequestedComments && isLiveCommunityPost) {
            hasRequestedComments = true;
            Future.microtask(fetchLiveComments);
          }

          final totalDisplayCount = isLiveCommunityPost
              ? apiComments.length
              : fallbackComments.length;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(modalCtx).size.height * 0.72,
              child: Column(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bình Luận ($totalDisplayCount)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      if (isLiveCommunityPost)
                        IconButton(
                          tooltip: 'Tải lại bình luận',
                          onPressed: fetchLiveComments,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLiveCommunityPost
                        ? (isLoadingComments
                            ? const Center(child: CircularProgressIndicator())
                            : commentsError
                            ? Center(
                                child: TextButton(
                                  onPressed: fetchLiveComments,
                                  child: const Text('Không thể tải bình luận. Nhấn để thử lại.'),
                                ),
                              )
                            : apiComments.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có bình luận nào. Hãy là người đầu tiên chia sẻ ý kiến!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.textSecColor,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: apiComments.length,
                                separatorBuilder: (_, _) =>
                                    Divider(color: context.inputColor),
                                itemBuilder: (_, index) {
                                  final c = apiComments[index];
                                  final isReply = c.parentCommentId != null &&
                                      c.parentCommentId!.isNotEmpty;
                                  final initial = c.authorName.isNotEmpty
                                      ? c.authorName[0].toUpperCase()
                                      : 'U';

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: isReply ? 28.0 : 0.0,
                                      top: 10.0,
                                      bottom: 10.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: isReply ? 16 : 20,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          child: Text(
                                            initial,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isReply ? 12 : 14,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      c.authorName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color:
                                                            context.textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      c.authorRole
                                                              .toUpperCase()
                                                              .contains(
                                                                  'EXPERT')
                                                          ? 'Chuyên gia'
                                                          : 'Photographer',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    CommunityPostResponseDTO
                                                        .formatTimeAgo(
                                                            c.createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textHint,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                c.content,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: context.textColor,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      setModalState(() {
                                                        editingComment = null;
                                                        replyingTo = c;
                                                      });
                                                    },
                                                    child: const Text(
                                                      'Trả lời',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (c.isMine) ...[
                                                    const SizedBox(width: 16),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          replyingTo = null;
                                                          editingComment = c;
                                                          commentController
                                                              .text = c.content;
                                                        });
                                                      },
                                                      child: Text(
                                                        'Sửa',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: context
                                                              .textSecColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        final ok =
                                                            await _communityPostApiService
                                                                .deleteComment(
                                                          postId: post.id,
                                                          commentId:
                                                              c.commentId,
                                                        );
                                                        if (ok) {
                                                          await fetchLiveComments();
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Xóa',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ))
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: fallbackComments.length,
                            separatorBuilder: (_, _) =>
                                Divider(color: context.inputColor),
                            itemBuilder: (_, index) {
                              final c = fallbackComments[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        c['author']![0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                c['author']!,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: context.textColor,
                                                ),
                                              ),
                                              Text(
                                                c['time']!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textHint,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            c['text']!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context.textSecColor,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  if (replyingTo != null || editingComment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            editingComment != null
                                ? Icons.edit_outlined
                                : Icons.reply_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              editingComment != null
                                  ? 'Đang sửa bình luận của bạn'
                                  : 'Đang trả lời ${replyingTo!.authorName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                replyingTo = null;
                                if (editingComment != null) {
                                  editingComment = null;
                                  commentController.clear();
                                }
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: editingComment != null
                                  ? 'Nhập nội dung bình luận mới...'
                                  : (replyingTo != null
                                      ? 'Trả lời ${replyingTo!.authorName}...'
                                      : 'Viết bình luận...'),
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textHint,
                              ),
                              filled: true,
                              fillColor: context.inputColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: isSending
                              ? null
                              : () async {
                                  final text = commentController.text.trim();
                                  if (text.isEmpty) return;

                                  if (isLiveCommunityPost) {
                                    setModalState(() => isSending = true);
                                    Map<String, dynamic> res;
                                    if (editingComment != null) {
                                      res = await _communityPostApiService
                                          .updateComment(
                                        postId: post.id,
                                        commentId: editingComment!.commentId,
                                        content: text,
                                      );
                                    } else {
                                      res = await _communityPostApiService
                                          .createComment(
                                        postId: post.id,
                                        request:
                                            CommunityCommentWriteRequestDTO(
                                          content: text,
                                          parentCommentId:
                                              replyingTo?.commentId,
                                        ),
                                      );
                                    }

                                    if (!modalCtx.mounted || !mounted) return;
                                    setModalState(() {
                                      isSending = false;
                                      if (res['success'] == true) {
                                        replyingTo = null;
                                        editingComment = null;
                                      }
                                    });
                                    if (res['success'] == true) {
                                      commentController.clear();
                                      await fetchLiveComments();
                                    } else {
                                      toastification.show(
                                        context: context,
                                        type: ToastificationType.error,
                                        style: ToastificationStyle.flatColored,
                                        title: const Text(
                                            'Không thể gửi bình luận'),
                                        description: Text(
                                          res['message']?.toString() ?? '',
                                        ),
                                        alignment: Alignment.topCenter,
                                        autoCloseDuration:
                                            const Duration(seconds: 3),
                                        showProgressBar: false,
                                      );
                                    }
                                  } else {
                                    final authorName = AuthService()
                                        .currentUser
                                        ?.fullName
                                        .trim();
                                    setModalState(() {
                                      fallbackComments.add({
                                        'author': (authorName != null &&
                                                authorName.isNotEmpty)
                                            ? authorName
                                            : 'Bạn',
                                        'text': text,
                                        'time': 'Vừa xong',
                                      });
                                    });
                                    setState(() {
                                      post.commentsCount++;
                                    });
                                    commentController.clear();
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: context.cardColor,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showShareModal(BlogPost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Text(
              'Chia Sẻ Bài Viết',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: context.inputColor,
                child: const Icon(Icons.copy_rounded, color: AppColors.primary),
              ),
              title: const Text(
                'Sao chép liên kết',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Đã sao chép liên kết bài viết vào khay nhớ tạm!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          _viewMode == 1
                  ? 'Bài Đăng Cộng Đồng Của Tôi'
                  : 'Diễn Đàn Cộng Đồng Film',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.post_add_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'Đăng bài chia sẻ cộng đồng',
            onPressed: () => _showCommunityPostFormModal(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh chuyển chế độ (Diễn đàn chung / Bài đăng của tôi / Bài viết chuyên gia)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.inputColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _viewMode == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Diễn Đàn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _viewMode == 0
                                  ? Colors.white
                                  : context.textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _viewMode = 1);
                          _loadMyCommunityPosts();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _viewMode == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Bài Đăng (${_myCommunityPosts.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _viewMode == 1
                                  ? Colors.white
                                  : context.textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Input
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: context.inputColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài viết, chủ đề, tác giả...',
                    hintStyle:
                        const TextStyle(color: AppColors.textHint, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: context.textSecColor, size: 22),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Filter Row
            if (_viewMode == 0)
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: ActionChip(
                        label: Text(_filters[index]),
                        backgroundColor:
                            isSelected ? AppColors.primary : context.cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : context.borderColor,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),

            // Content Area
            Expanded(
              child: _viewMode == 1
                      ? _buildMyCommunityPostsView()
                      : _buildCommunityFeedView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 110.0),
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child:
                    const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildCommunityFeedView() {
    if (_isLoadingFeed) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_feedError) {
      return Center(
        child: TextButton(
          onPressed: _loadCommunityFeed,
          child: const Text('Không thể tải bài đăng. Nhấn để thử lại.'),
        ),
      );
    }

    final posts = _filteredPosts;
    if (posts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadCommunityFeed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy bài viết phù hợp',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.textSecColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadCommunityFeed,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  /// Giao diện quản lý Bài đăng Cộng đồng của chính mình (GET /api/community/posts/mine)
  Widget _buildMyCommunityPostsView() {
    if (_isLoadingMyPosts) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_myPostsError) {
      return Center(
        child: TextButton(
          onPressed: _loadMyCommunityPosts,
          child: const Text('Không thể tải bài đăng của bạn. Nhấn để thử lại.'),
        ),
      );
    }

    final items = _filteredMyCommunityPosts;
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadMyCommunityPosts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.forum_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có bài đăng cộng đồng nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chia sẻ kinh nghiệm chụp film, góc ảnh đẹp hoặc đặt câu hỏi cùng cộng đồng Photographer & Chuyên gia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCommunityPostFormModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Đăng Bài Cộng Đồng Mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMyCommunityPosts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final postDto = items[index];
          final blogPost = postDto.toBlogPost();

          return GestureDetector(
            onTap: () =>
                _showPostDetailModal(communityPost: postDto),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          postDto.category ?? 'Cộng đồng Film',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildArticleStatusBadge(postDto.status),
                      const Spacer(),
                      Text(
                        CommunityPostResponseDTO.formatTimeAgo(
                            postDto.updatedAt ?? postDto.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: context.textSecColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    postDto.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    postDto.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecColor,
                      height: 1.45,
                    ),
                  ),
                  if (postDto.images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SafeNetworkImage(
                      url: postDto.images.first.imageUrl,
                      width: double.infinity,
                      height: 160,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ],
                  const Divider(height: 22),
                  Row(
                    children: [
                      Icon(
                        postDto.isLiked
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: postDto.isLiked
                            ? AppColors.primary
                            : context.textSecColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${postDto.likeCount}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textSecColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _showCommentsModal(blogPost),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: context.textSecColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${postDto.commentCount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textSecColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            _showCommunityPostFormModal(existing: postDto),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Sửa'),
                      ),
                      IconButton(
                        tooltip: 'Xóa bài đăng',
                        onPressed: () => _handleDeleteCommunityPost(postDto),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BlogPost post) {
    return GestureDetector(
      onTap: () => _showPostDetailModal(post: post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(post.authorAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                post.authorRole,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new_rounded,
                      size: 18, color: context.textSecColor),
                  tooltip: 'Xem chi tiết bài viết',
                  onPressed: () => _showPostDetailModal(post: post),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              post.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),

            // Image (if any)
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SafeNetworkImage(
                  url: post.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

            Divider(height: 1, color: context.inputColor),
            const SizedBox(height: 12),

            // Interactions
            Row(
              children: [
                GestureDetector(
                  onTap: () => _handleLike(post),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.userReaction == 'like'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.userReaction == 'like'
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_alt_outlined,
                          color: post.userReaction == 'like'
                              ? AppColors.primary
                              : context.textSecColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            color: post.userReaction == 'like'
                                ? AppColors.primary
                                : context.textSecColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showCommentsModal(post),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: context.textSecColor, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          color: context.textSecColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showShareModal(post),
                  child: Icon(Icons.share_outlined,
                      color: context.textSecColor, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
