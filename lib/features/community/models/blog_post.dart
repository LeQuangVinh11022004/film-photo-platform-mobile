class BlogPost {
  final String id;
  final String? authorUserId;
  final String authorName;
  final String authorRole; // e.g., 'Chuyên gia Film', 'Photographer'
  final String authorAvatar;
  final String timeAgo;
  final String title;
  final String content;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final String status; // 'PUBLISHED' or 'DRAFT'
  final bool isCommunityPost;
  int likes;
  int dislikes;
  int commentsCount;
  int sharesCount;
  String? userReaction; // 'like', 'dislike', or null

  BlogPost({
    required this.id,
    this.authorUserId,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.timeAgo,
    required this.title,
    required this.content,
    this.imageUrl,
    this.images = const [],
    this.category = 'Kỹ thuật Film',
    this.status = 'PUBLISHED',
    this.isCommunityPost = false,
    this.likes = 0,
    this.dislikes = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.userReaction,
  });
}
