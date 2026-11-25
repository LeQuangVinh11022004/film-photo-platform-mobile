import 'blog_post.dart';

class ArticleResponseDTO {
  final String articleId;
  final String expertName;
  final String title;
  final String content;
  final String category;
  final String status; // 'DRAFT' or 'PUBLISHED'
  final DateTime createdAt;
  final DateTime? updatedAt;

  ArticleResponseDTO({
    required this.articleId,
    required this.expertName,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ArticleResponseDTO.fromJson(Map<String, dynamic> json) {
    return ArticleResponseDTO(
      articleId: json['articleId']?.toString() ?? '',
      expertName: json['expertName']?.toString() ?? 'Chuyên gia Film',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Nhiếp ảnh Film',
      status: json['status']?.toString() ?? 'PUBLISHED',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  static String formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  BlogPost toBlogPost() {
    final lowerCat = category.toLowerCase();
    String defaultImg =
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&auto=format&fit=crop&q=80';
    if (lowerCat.contains('darkroom') ||
        lowerCat.contains('phòng tối') ||
        lowerCat.contains('tráng')) {
      defaultImg =
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80';
    } else if (lowerCat.contains('studio') || lowerCat.contains('ánh sáng')) {
      defaultImg =
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80';
    }

    return BlogPost(
      id: articleId,
      authorName: expertName.isNotEmpty ? expertName : 'Chuyên gia Film',
      authorRole: 'Chuyên gia Film • $category',
      authorAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      timeAgo: formatTimeAgo(updatedAt ?? createdAt),
      title: title,
      content: content,
      imageUrl: defaultImg,
      category: category,
      status: status,
      isApiArticle: true,
      likes: 18,
      dislikes: 0,
      commentsCount: 2,
      sharesCount: 3,
    );
  }
}

class ArticleWriteRequestDTO {
  final String title;
  final String content;
  final String category;

  const ArticleWriteRequestDTO({
    required this.title,
    required this.content,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'content': content.trim(),
        'category': category.trim(),
      };
}

class ArticleStatusUpdateRequestDTO {
  final String status; // 'DRAFT' or 'PUBLISHED'

  const ArticleStatusUpdateRequestDTO({required this.status});

  Map<String, dynamic> toJson() => {
        'status': status.trim().toUpperCase(),
      };
}
