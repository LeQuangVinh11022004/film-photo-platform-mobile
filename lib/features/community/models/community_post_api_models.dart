import 'blog_post.dart';

class CommunityPostImageResponseDTO {
  final String imageId;
  final String imageUrl;
  final String? caption;
  final int displayOrder;

  const CommunityPostImageResponseDTO({
    required this.imageId,
    required this.imageUrl,
    this.caption,
    required this.displayOrder,
  });

  factory CommunityPostImageResponseDTO.fromJson(Map<String, dynamic> json) {
    return CommunityPostImageResponseDTO(
      imageId: json['imageId']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      caption: json['caption']?.toString(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityPostImageWriteRequestDTO {
  final String imageUrl;
  final String? caption;
  final int displayOrder;

  const CommunityPostImageWriteRequestDTO({
    required this.imageUrl,
    this.caption,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'imageUrl': imageUrl.trim(),
      'displayOrder': displayOrder,
    };
    if (caption != null && caption!.trim().isNotEmpty) {
      map['caption'] = caption!.trim();
    }
    return map;
  }
}

class CommunityPostResponseDTO {
  final String postId;
  final String userId;
  final String authorName;
  final String authorRole;
  final String title;
  final String content;
  final String? category;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final List<CommunityPostImageResponseDTO> images;

  const CommunityPostResponseDTO({
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.content,
    this.category,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    this.images = const [],
  });

  factory CommunityPostResponseDTO.fromJson(Map<String, dynamic> json) {
    return CommunityPostResponseDTO(
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Thành viên Cộng đồng',
      authorRole: json['authorRole']?.toString() ?? 'PHOTOGRAPHER',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString(),
      status: json['status']?.toString() ?? 'PUBLISHED',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => CommunityPostImageResponseDTO.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
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
    final cat = (category != null && category!.trim().isNotEmpty)
        ? category!.trim()
        : 'Kỹ thuật Film';
    final isExpert = authorRole.toUpperCase().contains('EXPERT');
    final roleDisplay = isExpert
        ? 'Chuyên gia Film • $cat'
        : 'Nhiếp ảnh gia • $cat';

    final String? mainImg = images.isNotEmpty ? images.first.imageUrl : null;

    return BlogPost(
      id: postId,
      authorUserId: userId,
      authorName:
          authorName.trim().isNotEmpty ? authorName.trim() : 'Thành viên Film',
      authorRole: roleDisplay,
      authorAvatar: isExpert
          ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      timeAgo: formatTimeAgo(updatedAt ?? createdAt),
      title: title,
      content: content,
      imageUrl: mainImg,
      images: images.map((e) => e.imageUrl).toList(),
      category: cat,
      status: status,
      isApiArticle: false,
      isCommunityPost: true,
      likes: likeCount,
      dislikes: 0,
      commentsCount: commentCount,
      sharesCount: 0,
      userReaction: isLiked ? 'like' : null,
    );
  }
}

class CommunityPostWriteRequestDTO {
  final String title;
  final String content;
  final String? category;
  final List<CommunityPostImageWriteRequestDTO> images;

  const CommunityPostWriteRequestDTO({
    required this.title,
    required this.content,
    this.category,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'content': content.trim(),
      'images': images.map((e) => e.toJson()).toList(),
    };
    if (category != null && category!.trim().isNotEmpty) {
      map['category'] = category!.trim();
    }
    return map;
  }
}

class CommunityCommentResponseDTO {
  final String commentId;
  final String postId;
  final String userId;
  final String authorName;
  final String authorRole;
  final String? parentCommentId;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  const CommunityCommentResponseDTO({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorRole,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory CommunityCommentResponseDTO.fromJson(Map<String, dynamic> json) {
    return CommunityCommentResponseDTO(
      commentId: json['commentId']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Thành viên',
      authorRole: json['authorRole']?.toString() ?? 'PHOTOGRAPHER',
      parentCommentId: json['parentCommentId']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isMine: json['isMine'] == true,
    );
  }
}

class CommunityCommentWriteRequestDTO {
  final String content;
  final String? parentCommentId;

  const CommunityCommentWriteRequestDTO({
    required this.content,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'content': content.trim(),
    };
    if (parentCommentId != null && parentCommentId!.trim().isNotEmpty) {
      map['parentCommentId'] = parentCommentId!.trim();
    }
    return map;
  }
}
