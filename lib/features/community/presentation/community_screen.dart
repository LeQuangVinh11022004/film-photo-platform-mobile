import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../auth/services/auth_service.dart';
import '../models/blog_post.dart';
import '../models/community_post_api_models.dart';
import '../services/community_post_api_service.dart';
import '../widgets/community_comments_sheet.dart';
import '../widgets/community_filter_header.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_post_detail_sheet.dart';
import '../widgets/community_post_form_sheet.dart';
import '../widgets/community_share_sheet.dart';

class CommunityScreen extends StatefulWidget {
  final int initialViewMode;
  const CommunityScreen({super.key, this.initialViewMode = 0});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const int _pageSize = 5;

  final CommunityPostApiService _communityPostApiService =
      CommunityPostApiService();

  List<BlogPost> _posts = [];
  List<CommunityPostResponseDTO> _myCommunityPosts = [];

  bool _isLoadingFeed = true;
  bool _isLoadingMyPosts = false;
  bool _myPostsError = false;
  bool _feedError = false;

  int _feedPage = 1;
  int _feedTotalCount = 0;
  int _myPostsPage = 1;
  int _myPostsTotalCount = 0;

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
    _viewMode = widget.initialViewMode;
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

  bool get _isLocalFeedFilterActive =>
      _selectedFilterIndex != 0 || _searchQuery.isNotEmpty;

  /// Gọi GET /api/community/posts cho Diễn đàn chung (hỗ trợ phân trang server-side).
  Future<void> _loadCommunityFeed({String? category, int? page}) async {
    if (!mounted) return;
    final targetPage = page ?? _feedPage;
    final useLargeBatch = _isLocalFeedFilterActive;
    setState(() {
      _isLoadingFeed = true;
      _feedPage = targetPage;
    });

    try {
      final result = await _communityPostApiService.getFeed(
        category: category,
        page: useLargeBatch ? 1 : targetPage,
        pageSize: useLargeBatch ? 50 : _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _feedError = result == null;
        if (result != null) {
          _posts = result.items.map((dto) => dto.toBlogPost()).toList();
          _feedTotalCount =
              result.totalCount > 0 ? result.totalCount : result.items.length;
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

  /// Gọi GET /api/community/posts/mine cho cả PHOTOGRAPHER và EXPERT (hỗ trợ phân trang server-side).
  Future<void> _loadMyCommunityPosts({int? page}) async {
    if (!mounted) return;
    final targetPage = page ?? _myPostsPage;
    final useLargeBatch = _searchQuery.isNotEmpty;
    setState(() {
      _isLoadingMyPosts = true;
      _myPostsPage = targetPage;
    });

    try {
      final result = await _communityPostApiService.getMyPosts(
        page: useLargeBatch ? 1 : targetPage,
        pageSize: useLargeBatch ? 50 : _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _myPostsError = result == null;
        if (result != null) {
          _myCommunityPosts = result.items;
          _myPostsTotalCount =
              result.totalCount > 0 ? result.totalCount : result.items.length;
        }
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
          .where((p) => p.authorRole.toLowerCase().contains('chuyên gia'))
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

      loadedCommunityPost =
          await _communityPostApiService.getPostDetail(targetId);

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

    final bool isMyOwnCommPost = loadedCommunityPost != null &&
        _isMyCommunityPost(
          loadedCommunityPost.postId,
          loadedCommunityPost.userId,
        );

    await showCommunityPostDetailSheet(
      context: context,
      post: post,
      loadedCommunityPost: loadedCommunityPost,
      isMyOwnCommPost: isMyOwnCommPost,
      onOpenComments: _showCommentsModal,
      onEdit: (dto) => _showCommunityPostFormModal(existing: dto),
      onDelete: _handleDeleteCommunityPost,
    );
  }

  Future<void> _showCommunityPostFormModal({
    CommunityPostResponseDTO? existing,
  }) async {
    final isEditing = existing != null;
    final savedTitle = await showCommunityPostFormSheet(
      context: context,
      apiService: _communityPostApiService,
      existing: existing,
    );

    if (savedTitle != null && mounted) {
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
          'Bài đăng "$savedTitle" đã được đồng bộ lên Diễn đàn Cộng đồng.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
      );
    }
  }

  /// DELETE /api/community/posts/{postId}
  Future<void> _handleDeleteCommunityPost(
    CommunityPostResponseDTO post,
  ) async {
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

  void _showCommentsModal(BlogPost post) {
    showCommunityCommentsSheet(
      context: context,
      post: post,
      apiService: _communityPostApiService,
      onCommentsCountChanged: (count) {
        if (!mounted) return;
        setState(() {
          post.commentsCount = count;
        });
      },
    );
  }

  void _showShareModal(BlogPost post) {
    showCommunityShareSheet(
      context: context,
      onCopyLink: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép liên kết bài viết vào khay nhớ tạm!'),
          ),
        );
      },
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            CommunityViewModeToggle(
              viewMode: _viewMode,
              myPostsCount: _myCommunityPosts.length,
              onModeChanged: (mode) {
                setState(() => _viewMode = mode);
                if (mode == 1) {
                  _loadMyCommunityPosts();
                }
              },
            ),
            CommunitySearchAndFilters(
              searchController: _searchController,
              searchQuery: _searchQuery,
              viewMode: _viewMode,
              filters: _filters,
              selectedFilterIndex: _selectedFilterIndex,
              onSearchChanged: (val) {
                final wasLocal = _isLocalFeedFilterActive;
                final prevSearch = _searchQuery;
                setState(() {
                  _searchQuery = val.trim();
                  _feedPage = 1;
                  _myPostsPage = 1;
                });
                if (wasLocal != _isLocalFeedFilterActive) {
                  _loadCommunityFeed(page: 1);
                }
                if (prevSearch.isEmpty != _searchQuery.isEmpty) {
                  _loadMyCommunityPosts(page: 1);
                }
              },
              onClearSearch: () {
                final wasLocal = _isLocalFeedFilterActive;
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _feedPage = 1;
                  _myPostsPage = 1;
                });
                if (wasLocal != _isLocalFeedFilterActive) {
                  _loadCommunityFeed(page: 1);
                }
                _loadMyCommunityPosts(page: 1);
              },
              onFilterSelected: (index) {
                final wasLocal = _isLocalFeedFilterActive;
                setState(() {
                  _selectedFilterIndex = index;
                  _feedPage = 1;
                });
                if (wasLocal != _isLocalFeedFilterActive) {
                  _loadCommunityFeed(page: 1);
                }
              },
            ),
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
              padding: EdgeInsets.only(
                bottom: math.max(
                      MediaQuery.paddingOf(context).bottom,
                      MediaQuery.viewPaddingOf(context).bottom,
                    ) +
                    12,
              ),
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
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
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

    final bool isLocalPaged = _isLocalFeedFilterActive;
    final int totalItems = isLocalPaged
        ? posts.length
        : (_feedTotalCount > posts.length ? _feedTotalCount : posts.length);
    final int totalPages = (totalItems / _pageSize).ceil().clamp(1, 9999);
    final int safePage = _feedPage.clamp(1, totalPages);
    final List<BlogPost> displayedPosts = isLocalPaged
        ? posts.skip((safePage - 1) * _pageSize).take(_pageSize).toList()
        : posts;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadCommunityFeed(page: safePage),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + (_showFab ? 72 : 0),
        ),
        itemCount: displayedPosts.length + 1,
        itemBuilder: (context, index) {
          if (index == displayedPosts.length) {
            return PaginationBar(
              currentPage: safePage,
              totalPages: totalPages,
              totalItems: totalItems,
              pageSize: _pageSize,
              itemLabel: 'bài viết',
              onPageChanged: (newPage) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
                if (isLocalPaged) {
                  setState(() => _feedPage = newPage);
                } else {
                  _loadCommunityFeed(page: newPage);
                }
              },
            );
          }
          final post = displayedPosts[index];
          return CommunityPostCard(
            post: post,
            onOpenDetail: () => _showPostDetailModal(post: post),
            onLikeTap: () => _handleLike(post),
            onCommentsTap: () => _showCommentsModal(post),
            onShareTap: () => _showShareModal(post),
          );
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
            const Icon(
              Icons.forum_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
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

    final bool isLocalPaged = _searchQuery.isNotEmpty;
    final int totalItems = isLocalPaged
        ? items.length
        : (_myPostsTotalCount > items.length ? _myPostsTotalCount : items.length);
    final int totalPages = (totalItems / _pageSize).ceil().clamp(1, 9999);
    final int safePage = _myPostsPage.clamp(1, totalPages);
    final List<CommunityPostResponseDTO> displayedItems = isLocalPaged
        ? items.skip((safePage - 1) * _pageSize).take(_pageSize).toList()
        : items;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadMyCommunityPosts(page: safePage),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + (_showFab ? 72 : 0),
        ),
        itemCount: displayedItems.length + 1,
        itemBuilder: (context, index) {
          if (index == displayedItems.length) {
            return PaginationBar(
              currentPage: safePage,
              totalPages: totalPages,
              totalItems: totalItems,
              pageSize: _pageSize,
              itemLabel: 'bài viết',
              onPageChanged: (newPage) {
                if (isLocalPaged) {
                  setState(() => _myPostsPage = newPage);
                } else {
                  _loadMyCommunityPosts(page: newPage);
                }
              },
            );
          }
          final postDto = displayedItems[index];
          final blogPost = postDto.toBlogPost();

          return CommunityMyPostCard(
            post: postDto,
            onOpenDetail: () => _showPostDetailModal(communityPost: postDto),
            onOpenComments: () => _showCommentsModal(blogPost),
            onEdit: () => _showCommunityPostFormModal(existing: postDto),
            onDelete: () => _handleDeleteCommunityPost(postDto),
          );
        },
      ),
    );
  }
}
