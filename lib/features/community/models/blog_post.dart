class BlogPost {
  final String id;
  final String authorName;
  final String authorRole; // e.g., 'Chuyên gia Film', 'Nhà cung cấp Studio', 'Photographer'
  final String authorAvatar;
  final String timeAgo;
  final String title;
  final String content;
  final String? imageUrl;
  int likes;
  int dislikes;
  int commentsCount;
  int sharesCount;
  String? userReaction; // 'like', 'dislike', or null

  BlogPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.timeAgo,
    required this.title,
    required this.content,
    this.imageUrl,
    this.likes = 0,
    this.dislikes = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.userReaction,
  });

  static List<BlogPost> samplePosts = [
    BlogPost(
      id: 'P1',
      authorName: 'Hoàng Nam Film Lab',
      authorRole: 'Nhà cung cấp Lab & Studio',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      timeAgo: '2 giờ trước',
      title: 'Kỹ thuật đẩy ISO (Push Process) khi chụp film Kodak Tri-X 400 trong phòng tối',
      content: 'Chào anh em nhiếp ảnh film! Khi chụp trong điều kiện ánh sáng yếu hoặc môi trường thiếu sáng, kỹ thuật Push ISO từ 400 lên 1600 là lựa chọn tuyệt vời. Bài viết này hướng dẫn chi tiết thời gian ngâm thuốc Kodak D-76 và nhiệt độ chuẩn 20°C...',
      imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600&auto=format&fit=crop&q=80',
      likes: 128,
      dislikes: 3,
      commentsCount: 24,
      sharesCount: 15,
      userReaction: 'like',
    ),
    BlogPost(
      id: 'P2',
      authorName: 'Master Chuyên Gia Lộc Film',
      authorRole: 'Chuyên gia Nhiếp ảnh Film',
      authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      timeAgo: '5 giờ trước',
      title: 'So sánh chất màu Kodak Portra 400 vs Fuji Pro 400H cho ảnh chân dung',
      content: 'Tone màu ấm áp thiên vàng hồng của Portra 400 luôn là ưu tiên hàng đầu cho ảnh cưới và chân dung ngoài trời. Trong khi Fuji Pro 400H cho tone xanh mát thanh lịch. Cùng mình phân tích ảnh thực tế dưới đây nhé!',
      imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop&q=80',
      likes: 256,
      dislikes: 8,
      commentsCount: 42,
      sharesCount: 30,
    ),
    BlogPost(
      id: 'P3',
      authorName: 'Minh Tuấn Analog',
      authorRole: 'Nhiếp ảnh gia',
      authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      timeAgo: '1 ngày trước',
      title: 'Trải nghiệm phòng chụp Vintage Film Studio tại Quận 1',
      content: 'Vừa hoàn thành buổi chụpLookbook bằng máy Medium Format Hasselblad 500CM tại Studio. Ánh sáng tự nhiên ở đây thực sự đỉnh cao, không cần đánh đèn nhiều!',
      imageUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=600&auto=format&fit=crop&q=80',
      likes: 89,
      dislikes: 1,
      commentsCount: 12,
      sharesCount: 5,
    ),
  ];
}
