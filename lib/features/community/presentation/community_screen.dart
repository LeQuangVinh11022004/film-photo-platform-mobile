import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đăng Bài Viết Mới Mới Trên Diễn Đàn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Role selector
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò của bạn', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Nhiếp ảnh gia', child: Text('Nhiếp ảnh gia')),
                      DropdownMenuItem(value: 'Chuyên gia Nhiếp ảnh Film', child: Text('Chuyên gia Film')),
                      DropdownMenuItem(value: 'Nhà cung cấp Studio & Lab', child: Text('Nhà cung cấp')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề bài viết', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Nội dung chia sẻ...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'URL hình ảnh (Tùy chọn)',
                      hintText: 'https://images.unsplash.com/...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đăng bài viết mới thành công!'), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tiêu đề và nội dung bài viết'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đăng Bài Viết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bình Luận (${comments.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.separated(
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(c['author']![0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(c['author']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(c['time']!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(c['text']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
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
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Viết bình luận...',
                              hintStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: AppColors.inputFill,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                          onPressed: () {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chia Sẻ Bài Viết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.inputFill, child: Icon(Icons.copy_rounded, color: AppColors.primary)),
              title: const Text('Sao chép liên kết', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết bài viết vào khay nhớ tạm!')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF1877F2), child: Icon(Icons.facebook, color: Colors.white)),
              title: const Text('Chia sẻ lên Facebook', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang mở ứng dụng Facebook...')));
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF0088CC), child: Icon(Icons.send, color: Colors.white)),
              title: const Text('Chia sẻ qua Zalo / Telegram', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chọn chia sẻ tin nhắn!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diễn Đàn Cộng Đồng Film'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
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
                    hintText: 'Tìm bài viết, chuyên gia, thảo luận...',
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
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

            // Filter Categories Row
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.inputFill,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
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
            const SizedBox(height: 8),

            // Posts List
            Expanded(
              child: _filteredPosts.isEmpty
                  ? const Center(child: Text('Không tìm thấy bài viết phù hợp'))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            post.authorRole,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Post Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Post Content
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Optional Image
          if (post.imageUrl != null) ...[
            SafeNetworkImage(
              url: post.imageUrl!,
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(14),
            ),
            const SizedBox(height: 14),
          ],

          const Divider(height: 1),
          const SizedBox(height: 10),

          // Interaction Toolbar (+ Like, - Dislike, Comment, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Like Button (Dấu +)
              InkWell(
                onTap: () => _handleLike(post),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isLiked ? AppColors.primary : AppColors.inputFill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: isLiked ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likes}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isLiked ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dislike Button (Dấu -)
              InkWell(
                onTap: () => _handleDislike(post),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDisliked ? Colors.redAccent : AppColors.inputFill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: isDisliked ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.dislikes}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDisliked ? Colors.redAccent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comment Button
              InkWell(
                onTap: () => _showCommentsModal(post),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              // Share Button
              InkWell(
                onTap: () => _showShareModal(post),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.share_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${post.sharesCount}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
