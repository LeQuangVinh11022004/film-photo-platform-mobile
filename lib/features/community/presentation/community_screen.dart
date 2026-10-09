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
  String _searchQuery = '';

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
    final imageController = TextEditingController();
    String selectedRole = 'Nhiếp ảnh gia';

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
                  SizedBox(height: 16),
                  Text(
                    'Đăng Bài Viết Mới Trên Diễn Đàn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
                  ),
                  SizedBox(height: 24),

                  // Role selector
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Vai trò của bạn',
                      filled: true,
                      fillColor: context.inputColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Nhiếp ảnh gia', child: Text('Nhiếp ảnh gia')),
                      DropdownMenuItem(value: 'Chuyên gia Nhiếp ảnh Film', child: Text('Chuyên gia Film')),
                      DropdownMenuItem(value: 'Nhà cung cấp Studio & Lab', child: Text('Nhà cung cấp')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề bài viết',
                      filled: true,
                      fillColor: context.inputColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 16),

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
                  SizedBox(height: 16),

                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      labelText: 'URL hình ảnh (Tùy chọn)',
                      hintText: 'https://images.unsplash.com/...',
                      filled: true,
                      fillColor: context.inputColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = await DeviceImagePicker.pickImageFromDevice(
                        context,
                        title: 'Chọn Ảnh Bài Viết Từ Thiết Bị',
                      );
                      if (url != null) {
                        imageController.text = url;
                      }
                    },
                    icon: Icon(Icons.photo_library_outlined, size: 20),
                    label: Text('Chọn Ảnh Từ Thư Viện Máy', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      if (title.isNotEmpty && content.isNotEmpty) {
                        final newPost = BlogPost(
                          id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                          authorName: 'Lê Hoàng Anh',
                          authorRole: selectedRole,
                          authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                          timeAgo: 'Vừa xong',
                          title: title,
                          content: content,
                          imageUrl: imageController.text.trim().isNotEmpty ? imageController.text.trim() : null,
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
                    child: Text('Đăng Bài Viết', style: TextStyle(color: context.cardColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm bài viết, chuyên gia, thảo luận...',
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: context.textSecColor, size: 22),
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
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: context.cardColor,
                      side: BorderSide(color: isSelected ? Colors.transparent : context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      labelStyle: TextStyle(
                        color: isSelected ? context.cardColor : context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        }
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
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
    );
  }

  Widget _buildPostCard(BlogPost post) {
    final isLiked = post.userReaction == 'like';
    final isDisliked = post.userReaction == 'dislike';

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                radius: 24,
                backgroundImage: NetworkImage(post.authorAvatar),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post.authorRole,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          post.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          // Post Title
          Text(
            post.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.textColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: 10),

          // Post Content
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
          SizedBox(height: 16),

          // Optional Image
          if (post.imageUrl != null) ...[
            SafeNetworkImage(
              url: post.imageUrl!,
              width: double.infinity,
              height: 220,
              borderRadius: BorderRadius.circular(16),
            ),
            SizedBox(height: 20),
          ],

          Divider(height: 1, color: context.inputColor),
          SizedBox(height: 12),

          // Interaction Toolbar (+ Like, - Dislike, Comment, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Like Button (Dấu +)
              InkWell(
                onTap: () => _handleLike(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLiked ? AppColors.primary : context.inputColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: isLiked ? context.cardColor : context.textColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${post.likes}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLiked ? AppColors.primary : context.textSecColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dislike Button (Dấu -)
              InkWell(
                onTap: () => _handleDislike(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDisliked ? Colors.redAccent : context.inputColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: isDisliked ? context.cardColor : context.textColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${post.dislikes}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDisliked ? Colors.redAccent : context.textSecColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comment Button
              InkWell(
                onTap: () => _showCommentsModal(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.mode_comment_outlined, size: 20, color: context.textSecColor),
                      SizedBox(width: 8),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textSecColor),
                      ),
                    ],
                  ),
                ),
              ),

              // Share Button
              InkWell(
                onTap: () => _showShareModal(post),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 20, color: context.textSecColor),
                      SizedBox(width: 8),
                      Text(
                        '${post.sharesCount}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textSecColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


