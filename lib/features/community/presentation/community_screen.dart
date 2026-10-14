import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/device_image_picker.dart';
import '../models/blog_post.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<BlogPost> _posts = BlogPost.samplePosts;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Tất cả', 'Chuyên gia', 'Nhà cung cấp', 'Nhiếp ảnh gia'];

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<BlogPost> get _filteredPosts {
    List<BlogPost> list = _posts;

    if (_selectedFilterIndex == 1) {
      list = list.where((p) => p.authorRole.contains('Chuyên gia')).toList();
    } else if (_selectedFilterIndex == 2) {
      list = list.where((p) => p.authorRole.contains('Nhà cung cấp')).toList();
    } else if (_selectedFilterIndex == 3) {
      list = list.where((p) => p.authorRole.contains('Nhiếp ảnh gia')).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.authorName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return list;
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

  void _showCreatePostModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String? selectedImagePath;

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
                    'Đăng Bài Viết Mới Trên Diễn Đàn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề bài viết',
                      filled: true,
                      fillColor: context.inputColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Nội dung chia sẻ...',
                      filled: true,
                      fillColor: context.inputColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pick Image From Gallery Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = await DeviceImagePicker.pickImageFromDevice(
                        context,
                        title: 'Chọn Ảnh Bài Viết Từ Thiết Bị',
                      );
                      if (url != null) {
                        setModalState(() {
                          selectedImagePath = url;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Thêm Ảnh Từ Thư Viện Máy', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  // Image Preview if picked
                  if (selectedImagePath != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        SafeNetworkImage(
                          url: selectedImagePath!,
                          width: double.infinity,
                          height: 180,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedImagePath = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      if (title.isNotEmpty && content.isNotEmpty) {
                        final newPost = BlogPost(
                          id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                          authorName: 'Lê Hoàng Anh',
                          authorRole: 'Nhiếp ảnh gia',
                          authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                          timeAgo: 'Vừa xong',
                          title: title,
                          content: content,
                          imageUrl: selectedImagePath,
                          likes: 0,
                          dislikes: 0,
                          commentsCount: 0,
                          sharesCount: 0,
                        );

                        setState(() {
                          _posts.insert(0, newPost);
                        });

                        Navigator.pop(context);

                        NotificationService().triggerLocalNotification(
                          context: context,
                          title: 'Đăng Bài Viết Mới Thành Công! 💬',
                          body: 'Bài viết "$title" của bạn đã được chia sẻ lên Diễn đàn Cộng đồng Film.',
                          route: '/notifications',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tiêu đề và nội dung bài viết'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Đăng Bài Ngay', style: TextStyle(color: context.cardColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCommentsModal(BlogPost post) {
    final commentController = TextEditingController();
    final List<Map<String, String>> comments = [
      {'author': 'An Nhiên', 'text': 'Bài viết chia sẻ rất bổ ích, cảm ơn bạn!', 'time': '30 phút trước'},
      {'author': 'Minh Đức Film', 'text': 'Tone màu này tráng D-76 ra cực đâm và chi tiết.', 'time': '1 giờ trước'},
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
                  SizedBox(height: 20),
                  Text(
                    'Bình Luận (${comments.length})',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
                  ),
                  SizedBox(height: 20),

                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => Divider(color: context.inputColor),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(c['author']![0], style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(c['author']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textColor)),
                                        Text(c['time']!, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Text(c['text']!, style: TextStyle(fontSize: 14, color: context.textSecColor, height: 1.4)),
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
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Viết bình luận...',
                              hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                              filled: true,
                              fillColor: context.inputColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (commentController.text.trim().isNotEmpty) {
                              setModalState(() {
                                comments.add({
                                  'author': 'Bạn',
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
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.send_rounded, color: context.cardColor, size: 20),
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
        padding: EdgeInsets.all(24),
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
            SizedBox(height: 20),
            Text(
              'Chia Sẻ Bài Viết',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(radius: 24, backgroundColor: context.inputColor, child: Icon(Icons.copy_rounded, color: AppColors.primary)),
              title: Text('Sao chép liên kết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết bài viết vào khay nhớ tạm!')),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(radius: 24, backgroundColor: Color(0xFF1877F2), child: Icon(Icons.facebook, color: context.cardColor)),
              title: Text('Chia sẻ lên Facebook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang mở ứng dụng Facebook...')));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(radius: 24, backgroundColor: Color(0xFF0088CC), child: Icon(Icons.send, color: context.cardColor)),
              title: Text('Chia sẻ qua Zalo / Telegram', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chọn chia sẻ tin nhắn!')));
              },
            ),
            SizedBox(height: 16),
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
        title: Text('Diễn Đàn Cộng Đồng Film'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
            tooltip: 'Đăng bài viết mới',
            onPressed: _showCreatePostModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                    hintText: 'Tìm kiếm trên diễn đàn...',
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: context.textSecColor, size: 22),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
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

            // Filter Categories Row
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.0),
                    child: ActionChip(
                      label: Text(_filters[index]),
                      backgroundColor: isSelected ? AppColors.primary : context.cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: isSelected ? AppColors.primary : context.borderColor),
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
            SizedBox(height: 12),

            // Posts List
            Expanded(
              child: _filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text('Không tìm thấy bài viết phù hợp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: context.textSecColor)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = _filteredPosts[index];
                        return _buildPostCard(post);
                      },
                    ),
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
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildPostCard(BlogPost post) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
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
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textColor)),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            post.authorRole,
                            style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(post.timeAgo, style: TextStyle(fontSize: 12, color: context.textSecColor)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.more_vert, color: context.textSecColor), onPressed: () {}),
            ],
          ),
          SizedBox(height: 16),

          // Content
          Text(post.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textColor, height: 1.3)),
          SizedBox(height: 10),
          Text(post.content, style: TextStyle(fontSize: 14, color: context.textSecColor, height: 1.5)),
          SizedBox(height: 14),

          // Image (if any)
          if (post.imageUrl != null)
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: SafeNetworkImage(
                url: post.imageUrl!,
                width: double.infinity,
                height: 220,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

          Divider(height: 1, color: context.inputColor),
          SizedBox(height: 12),

          // Interactions
          Row(
            children: [
              // Like
              GestureDetector(
                onTap: () => _handleLike(post),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: post.userReaction == 'like' ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(post.userReaction == 'like' ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined, 
                          color: post.userReaction == 'like' ? AppColors.primary : context.textSecColor, size: 20),
                      SizedBox(width: 6),
                      Text('${post.likes}', style: TextStyle(color: post.userReaction == 'like' ? AppColors.primary : context.textSecColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 4),

              // Dislike
              GestureDetector(
                onTap: () => _handleDislike(post),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: post.userReaction == 'dislike' ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(post.userReaction == 'dislike' ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined, 
                          color: post.userReaction == 'dislike' ? context.textColor : context.textSecColor, size: 20),
                      SizedBox(width: 6),
                      Text('${post.dislikes}', style: TextStyle(color: post.userReaction == 'dislike' ? context.textColor : context.textSecColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Spacer(),

              // Comments
              GestureDetector(
                onTap: () => _showCommentsModal(post),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: context.textSecColor, size: 20),
                    SizedBox(width: 6),
                    Text('${post.commentsCount}', style: TextStyle(color: context.textSecColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(width: 16),

              // Share
              GestureDetector(
                onTap: () => _showShareModal(post),
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: context.textSecColor, size: 20),
                    SizedBox(width: 6),
                    Text('${post.sharesCount}', style: TextStyle(color: context.textSecColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}