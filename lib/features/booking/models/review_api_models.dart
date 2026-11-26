class SpaceReviewResponseDTO {
  final String reviewId;
  final String bookingId;
  final String customerUserId;
  final String customerName;
  final String? providerUserId;
  final String spaceType; // 'STUDIO' or 'DARKROOM'
  final String spaceId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const SpaceReviewResponseDTO({
    required this.reviewId,
    required this.bookingId,
    required this.customerUserId,
    required this.customerName,
    this.providerUserId,
    required this.spaceType,
    required this.spaceId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory SpaceReviewResponseDTO.fromJson(Map<String, dynamic> json) {
    return SpaceReviewResponseDTO(
      reviewId: json['reviewId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      customerUserId: json['customerUserId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Nhiếp ảnh gia',
      providerUserId: json['providerUserId']?.toString(),
      spaceType: json['spaceType']?.toString() ?? 'STUDIO',
      spaceId: json['spaceId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
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
}

class SpaceReviewPageResponseDTO {
  final String spaceType;
  final String spaceId;
  final double averageRating;
  final int totalReviews;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<SpaceReviewResponseDTO> items;

  const SpaceReviewPageResponseDTO({
    required this.spaceType,
    required this.spaceId,
    required this.averageRating,
    required this.totalReviews,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    this.items = const [],
  });

  factory SpaceReviewPageResponseDTO.fromJson(Map<String, dynamic> json) {
    return SpaceReviewPageResponseDTO(
      spaceType: json['spaceType']?.toString() ?? 'STUDIO',
      spaceId: json['spaceId']?.toString() ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  SpaceReviewResponseDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SpaceReviewWriteRequestDTO {
  final String spaceType; // 'STUDIO' or 'DARKROOM'
  final String spaceId;
  final int rating; // 1 to 5
  final String? comment;

  const SpaceReviewWriteRequestDTO({
    required this.spaceType,
    required this.spaceId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'spaceType': spaceType.trim().toUpperCase(),
      'spaceId': spaceId.trim(),
      'rating': rating,
    };
    if (comment != null && comment!.trim().isNotEmpty) {
      map['comment'] = comment!.trim();
    }
    return map;
  }
}
