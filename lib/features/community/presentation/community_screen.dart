import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/device_image_picker.dart';
import '../../auth/services/auth_service.dart';
import '../models/article_api_models.dart';
import '../models/blog_post.dart';
import '../services/article_api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ArticleApiService _articleApiService = ArticleApiService();

  List<BlogPost> _posts = [];
  List<ArticleResponseDTO> _expertMyArticles = [];

  bool _isLoadingFeed = true;
  bool _isLoadingExpertArticles = false;

  /// Chế độ hiển thị khi đăng nhập bằng Role EXPERT:
  /// 0 = Diễn đàn Cộng đồng (GET /api/articles)
  /// 1 = Quản lý Bài viết của tôi (GET/POST/PUT/PATCH/DELETE /api/expert/articles)
  int _expertViewMode = 0;

  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Tất cả',
    'Chuyên gia',
    'Kỹ thuật Film',
    'Phòng tối',
    'Thiết bị',
  ];

  /// Bộ lọc trạng thái cho tab Bài viết của Expert: '', 'PUBLISHED', 'DRAFT'
  String _expertStatusFilter = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  String _searchQuery = '';

  bool get _isExpertRole {
    final role = (AuthService().currentUser?.role ?? '').trim().toUpperCase();
    return role == 'EXPERT' || role.contains('EXPERT');
  }

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
    _loadCommunityArticles();
    if (_isExpertRole) {
      _loadExpertMyArticles();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Gọi API GET /api/articles cho cả Photographer và Expert xem diễn đàn chung
  Future<void> _loadCommunityArticles({String? category}) async {
    if (!mounted) return;
    setState(() => _isLoadingFeed = true);

    try {
      final page = await _articleApiService.getPublishedArticles(
        category: category,
        page: 1,
        pageSize: 50,
      );
      if (!mounted) return;

      final apiPosts =
          page?.items.map((dto) => dto.toBlogPost()).toList() ?? [];
      setState(() {
        if (apiPosts.isNotEmpty) {
          _posts = [...apiPosts, ...BlogPost.samplePosts];
        } else {
          _posts = List<BlogPost>.from(BlogPost.samplePosts);
        }
        _isLoadingFeed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posts = List<BlogPost>.from(BlogPost.samplePosts);
        _isLoadingFeed = false;
      });
    }
  }

  /// Gọi API GET /api/expert/articles dành riêng cho Role EXPERT
  Future<void> _loadExpertMyArticles() async {
    if (!_isExpertRole || !mounted) return;
    setState(() => _isLoadingExpertArticles = true);

    try {
      final page = await _articleApiService.getExpertArticles(
        status: _expertStatusFilter.isEmpty ? null : _expertStatusFilter,
        page: 1,
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _expertMyArticles = page?.items ?? [];
        _isLoadingExpertArticles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _expertMyArticles = [];
        _isLoadingExpertArticles = false;
      });
    }
  }

  List<BlogPost> get _filteredPosts {
    List<BlogPost> list = _posts;

    if (_selectedFilterIndex == 1) {
      list = list
          .where((p) =>
              p.authorRole.toLowerCase().contains('chuyên gia') ||
              p.isApiArticle)
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

  List<ArticleResponseDTO> get _filteredExpertArticles {
    if (_searchQuery.isEmpty) return _expertMyArticles;
    final q = _searchQuery.toLowerCase();
    return _expertMyArticles
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.content.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q))
        .toList();
  }

  void _handleLike(BlogPost post) {
    setState(() {
      if (post.userReaction == 'like') {
        post.userReaction = null;
        post.likes--;
      } else {
        if (post.userReaction == 'dislike') {
          post.dislikes--;
        }
        post.userReaction = 'like';
        post.likes++;
      }
    });
  }

  void _handleDislike(BlogPost post) {
    setState(() {
      if (post.userReaction == 'dislike') {
        post.userReaction = null;
        post.dislikes--;
      } else {
        if (post.userReaction == 'like') {
          post.likes--;
        }
        post.userReaction = 'dislike';
        post.dislikes++;
      }
    });
  }

  /// Xem chi tiết bài viết:
  /// - Gọi GET /api/articles/{articleId} (cho bài viết đã xuất bản trên diễn đàn)
  /// - Hoặc GET /api/expert/articles/{articleId} (nếu là bài viết của Expert trong tab Quản lý)
  Future<void> _showArticleDetailModal({
    BlogPost? post,
    ArticleResponseDTO? expertArticle,
  }) async {
    ArticleResponseDTO? loadedDto = expertArticle;
    final String targetId = expertArticle?.articleId ?? post?.id ?? '';

    if (targetId.length >= 32) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      if (expertArticle != null && _isExpertRole) {
        loadedDto = await _articleApiService.getExpertArticleDetail(targetId) ??
            expertArticle;
      } else {
        loadedDto =
            await _articleApiService.getPublishedArticleDetail(targetId) ??
                expertArticle;
      }

      if (!mounted) return;
      Navigator.pop(context);
    }

    if (!mounted) return;

    final displayTitle = loadedDto?.title ?? post?.title ?? '';
    final displayContent = loadedDto?.content ?? post?.content ?? '';
    final displayAuthor =
        loadedDto?.expertName ?? post?.authorName ?? 'Chuyên gia Film';
    final displayCategory =
        loadedDto?.category ?? post?.category ?? 'Kỹ thuật Film';
    final displayStatus = loadedDto?.status ?? post?.status ?? 'PUBLISHED';
    final displayTime = loadedDto != null
        ? ArticleResponseDTO.formatTimeAgo(
            loadedDto.updatedAt ?? loadedDto.createdAt)
        : (post?.timeAgo ?? 'Vừa xong');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
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
              if (post?.imageUrl != null) ...[
                SafeNetworkImage(
                  url: post!.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                displayContent,
                style: TextStyle(
                  fontSize: 15,
                  color: context.textColor,
                  height: 1.65,
                ),
              ),
              if (_isExpertRole && loadedDto != null) ...[
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showExpertArticleFormModal(existing: loadedDto);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Sửa bài'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final nextStatus =
                              loadedDto!.status.toUpperCase() == 'PUBLISHED'
                                  ? 'DRAFT'
                                  : 'PUBLISHED';
                          _handleToggleExpertArticleStatus(
                            loadedDto,
                            nextStatus,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          loadedDto.status.toUpperCase() == 'PUBLISHED'
                              ? Icons.unpublished_outlined
                              : Icons.publish_rounded,
                          size: 18,
                        ),
                        label: Text(
                          loadedDto.status.toUpperCase() == 'PUBLISHED'
                              ? 'Chuyển về Nháp'
                              : 'Xuất bản ngay',
                        ),
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

  /// Modal Tạo mới (POST /api/expert/articles) hoặc Cập nhật (PUT /api/expert/articles/{articleId})
  /// dành cho Role EXPERT (và hỗ trợ đăng bài chia sẻ nhanh cho Photographer trên feed)
  void _showExpertArticleFormModal({ArticleResponseDTO? existing}) {
    final isEditing = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController =
        TextEditingController(text: existing?.content ?? '');
    final categories = const [
      'Kỹ thuật chụp Film',
      'Tráng rọi Phòng tối',
      'Đánh giá Thiết bị & Film',
      'Kinh nghiệm Ánh sáng Studio',
      'Phục chế & Lưu trữ',
    ];
    String selectedCategory = existing?.category.isNotEmpty == true
        ? existing!.category
        : categories.first;
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    bool publishImmediately =
        existing == null ? true : existing.status.toUpperCase() == 'PUBLISHED';
    String? selectedImagePath;
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
                        ? 'Chỉnh Sửa Bài Viết Chuyên Môn'
                        : (_isExpertRole
                            ? 'Tạo Bài Viết Chuyên Gia (API)'
                            : 'Đăng Bài Chia Sẻ Cộng Đồng'),
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
                      labelText: 'Danh mục bài viết',
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
                      labelText: 'Tiêu đề bài viết',
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
                      labelText: 'Nội dung bài viết chuyên sâu...',
                      filled: true,
                      fillColor: context.inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_isExpertRole) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Xuất bản công khai lên Diễn đàn (PUBLISHED)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      subtitle: Text(
                        publishImmediately
                            ? 'Mọi Photographer đều xem được trên GET /api/articles'
                            : 'Lưu dưới dạng Bản nháp (DRAFT)',
                        style: TextStyle(
                            fontSize: 12, color: context.textSecColor),
                      ),
                      value: publishImmediately,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setModalState(() => publishImmediately = val);
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = await DeviceImagePicker.pickImageFromDevice(
                          context,
                          title: 'Chọn Ảnh Bài Viết Từ Thiết Bị',
                        );
                        if (url != null) {
                          setModalState(() => selectedImagePath = url);
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const Text(
                        'Thêm Ảnh Từ Thư Viện Máy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    if (selectedImagePath != null) ...[
                      const SizedBox(height: 12),
                      SafeNetworkImage(
                        url: selectedImagePath!,
                        width: double.infinity,
                        height: 160,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ],
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
                              if (title.isEmpty || content.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Vui lòng nhập đầy đủ tiêu đề và nội dung bài viết'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              if (_isExpertRole) {
                                setModalState(() => isSubmitting = true);
                                final writeDto = ArticleWriteRequestDTO(
                                  title: title,
                                  content: content,
                                  category: selectedCategory,
                                );

                                Map<String, dynamic> res;
                                if (isEditing) {
                                  // PUT /api/expert/articles/{articleId}
                                  res = await _articleApiService
                                      .updateExpertArticle(
                                    articleId: existing.articleId,
                                    request: writeDto,
                                  );
                                } else {
                                  // POST /api/expert/articles
                                  res = await _articleApiService
                                      .createExpertArticle(writeDto);
                                }

                                if (res['success'] == true) {
                                  final createdOrUpdated =
                                      res['article'] as ArticleResponseDTO?;
                                  final targetStatus = publishImmediately
                                      ? 'PUBLISHED'
                                      : 'DRAFT';
                                  if (createdOrUpdated != null &&
                                      createdOrUpdated.status.toUpperCase() !=
                                          targetStatus) {
                                    // PATCH /api/expert/articles/{articleId}/status
                                    await _articleApiService
                                        .updateExpertArticleStatus(
                                      articleId: createdOrUpdated.articleId,
                                      status: targetStatus,
                                    );
                                  }

                                  if (!modalCtx.mounted) return;
                                  Navigator.pop(modalCtx);
                                  await Future.wait([
                                    _loadExpertMyArticles(),
                                    _loadCommunityArticles(),
                                  ]);
                                  if (!mounted) return;
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.success,
                                    style: ToastificationStyle.flatColored,
                                    title: Text(
                                      isEditing
                                          ? 'Đã cập nhật bài viết!'
                                          : 'Đã tạo bài viết mới!',
                                    ),
                                    description: Text(
                                      publishImmediately
                                          ? 'Bài viết "$title" đã được xuất bản lên Diễn đàn.'
                                          : 'Bài viết "$title" đã được lưu ở trạng thái Bản nháp.',
                                    ),
                                    alignment: Alignment.topCenter,
                                    autoCloseDuration:
                                        const Duration(seconds: 4),
                                    showProgressBar: false,
                                  );
                                } else {
                                  if (!modalCtx.mounted) return;
                                  setModalState(() => isSubmitting = false);
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.error,
                                    style: ToastificationStyle.flatColored,
                                    title: const Text('Thao tác thất bại'),
                                    description: Text(
                                      res['message']?.toString() ??
                                          'Không thể lưu bài viết.',
                                    ),
                                    alignment: Alignment.topCenter,
                                    autoCloseDuration:
                                        const Duration(seconds: 4),
                                    showProgressBar: false,
                                  );
                                }
                              } else {
                                // Photographer local share
                                final currentUser = AuthService().currentUser;
                                final resolvedName = (currentUser != null &&
                                        currentUser.fullName.trim().isNotEmpty)
                                    ? currentUser.fullName.trim()
                                    : 'Lê Hoàng Anh';

                                final newPost = BlogPost(
                                  id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                                  authorName: resolvedName,
                                  authorRole:
                                      'Nhiếp ảnh gia • $selectedCategory',
                                  authorAvatar:
                                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                                  timeAgo: 'Vừa xong',
                                  title: title,
                                  content: content,
                                  imageUrl: selectedImagePath,
                                  category: selectedCategory,
                                );

                                setState(() {
                                  _posts.insert(0, newPost);
                                });
                                Navigator.pop(modalCtx);
                                NotificationService().triggerLocalNotification(
                                  context: context,
                                  title: 'Đăng Bài Chia Sẻ Thành Công! 💬',
                                  body:
                                      'Bài viết "$title" của bạn đã hiển thị trên Diễn đàn.',
                                  route: '/notifications',
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

  /// PATCH /api/expert/articles/{articleId}/status
  Future<void> _handleToggleExpertArticleStatus(
    ArticleResponseDTO article,
    String newStatus,
  ) async {
    final res = await _articleApiService.updateExpertArticleStatus(
      articleId: article.articleId,
      status: newStatus,
    );
    if (!mounted) return;

    if (res['success'] == true) {
      await Future.wait([
        _loadExpertMyArticles(),
        _loadCommunityArticles(),
      ]);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: Text(
          newStatus == 'PUBLISHED'
              ? 'Đã xuất bản bài viết!'
              : 'Đã chuyển về Bản nháp!',
        ),
        description: Text('Bài viết "${article.title}" -> $newStatus'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Cập nhật trạng thái thất bại'),
        description: Text(res['message']?.toString() ?? 'Vui lòng thử lại.'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
    }
  }

  /// DELETE /api/expert/articles/{articleId}
  Future<void> _handleDeleteExpertArticle(ArticleResponseDTO article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài viết "${article.title}" không?',
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

    final ok = await _articleApiService.deleteExpertArticle(article.articleId);
    if (!mounted) return;

    if (ok) {
      await Future.wait([
        _loadExpertMyArticles(),
        _loadCommunityArticles(),
      ]);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Đã xóa bài viết thành công'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Xóa bài viết thất bại'),
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

  void _showCommentsModal(BlogPost post) {
    final commentController = TextEditingController();
    final List<Map<String, String>> comments = [
      {
        'author': 'An Nhiên',
        'text': 'Bài viết chia sẻ rất bổ ích, cảm ơn bạn!',
        'time': '30 phút trước'
      },
      {
        'author': 'Minh Đức Film',
        'text': 'Tone màu này tráng D-76 ra cực đậm và chi tiết.',
        'time': '1 giờ trước'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
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
                  const SizedBox(height: 20),
                  Text(
                    'Bình Luận (${comments.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: context.inputColor),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Viết bình luận...',
                              hintStyle: const TextStyle(
                                  fontSize: 14, color: AppColors.textHint),
                              filled: true,
                              fillColor: context.inputColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (commentController.text.trim().isNotEmpty) {
                              final authorName =
                                  AuthService().currentUser?.fullName.trim();
                              setModalState(() {
                                comments.add({
                                  'author': (authorName != null &&
                                          authorName.isNotEmpty)
                                      ? authorName
                                      : 'Bạn',
                                  'text': commentController.text.trim(),
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
                            child: Icon(Icons.send_rounded,
                                color: context.cardColor, size: 20),
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
    final isExpert = _isExpertRole;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          isExpert && _expertViewMode == 1
              ? 'Quản Lý Bài Viết Chuyên Gia'
              : 'Diễn Đàn Cộng Đồng Film',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            tooltip: isExpert ? 'Tạo bài viết chuyên môn' : 'Đăng bài viết mới',
            onPressed: () => _showExpertArticleFormModal(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isExpert)
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
                          onTap: () => setState(() => _expertViewMode = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _expertViewMode == 0
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Diễn Đàn Chung',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _expertViewMode == 0
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
                            setState(() => _expertViewMode = 1);
                            _loadExpertMyArticles();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _expertViewMode == 1
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Bài Viết Của Tôi (${_expertMyArticles.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _expertViewMode == 1
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
            if (isExpert && _expertViewMode == 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildExpertStatusChip('Tất cả', ''),
                    const SizedBox(width: 8),
                    _buildExpertStatusChip('Đã xuất bản', 'PUBLISHED'),
                    const SizedBox(width: 8),
                    _buildExpertStatusChip('Bản nháp', 'DRAFT'),
                  ],
                ),
              )
            else
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
              child: isExpert && _expertViewMode == 1
                  ? _buildExpertArticlesView()
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

  Widget _buildExpertStatusChip(String label, String statusValue) {
    final isSelected = _expertStatusFilter == statusValue;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? AppColors.primary : context.cardColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.borderColor,
        ),
      ),
      onPressed: () {
        setState(() => _expertStatusFilter = statusValue);
        _loadExpertMyArticles();
      },
    );
  }

  Widget _buildCommunityFeedView() {
    if (_isLoadingFeed) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final posts = _filteredPosts;
    if (posts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadCommunityArticles,
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
      onRefresh: _loadCommunityArticles,
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

  Widget _buildExpertArticlesView() {
    if (_isLoadingExpertArticles) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final items = _filteredExpertArticles;
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadExpertMyArticles,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.article_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài viết chuyên môn nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo bài viết mới để chia sẻ kiến thức nhiếp ảnh film lên Diễn đàn Cộng đồng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showExpertArticleFormModal(),
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
                'Tạo Bài Viết Mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadExpertMyArticles,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final article = items[index];
          final isPublished = article.status.toUpperCase() == 'PUBLISHED';

          return GestureDetector(
            onTap: () => _showArticleDetailModal(expertArticle: article),
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
                          article.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildArticleStatusBadge(article.status),
                      const Spacer(),
                      Text(
                        ArticleResponseDTO.formatTimeAgo(
                            article.updatedAt ?? article.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: context.textSecColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecColor,
                      height: 1.45,
                    ),
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _showExpertArticleFormModal(existing: article),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Sửa'),
                      ),
                      TextButton.icon(
                        onPressed: () => _handleToggleExpertArticleStatus(
                          article,
                          isPublished ? 'DRAFT' : 'PUBLISHED',
                        ),
                        icon: Icon(
                          isPublished
                              ? Icons.unpublished_outlined
                              : Icons.publish_rounded,
                          size: 17,
                        ),
                        label: Text(isPublished ? 'Ẩn về Nháp' : 'Xuất bản'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Xóa bài viết',
                        onPressed: () => _handleDeleteExpertArticle(article),
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
      onTap: () => _showArticleDetailModal(post: post),
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
                  onPressed: () => _showArticleDetailModal(post: post),
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
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _handleDislike(post),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.userReaction == 'dislike'
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.userReaction == 'dislike'
                              ? Icons.thumb_down_rounded
                              : Icons.thumb_down_alt_outlined,
                          color: post.userReaction == 'dislike'
                              ? context.textColor
                              : context.textSecColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.dislikes}',
                          style: TextStyle(
                            color: post.userReaction == 'dislike'
                                ? context.textColor
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
