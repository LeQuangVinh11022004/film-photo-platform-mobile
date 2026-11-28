import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../models/review_api_models.dart';

class ItemDetailReviewsSection extends StatelessWidget {
  final String description;
  final String usagePolicies;
  final SpaceReviewPageResponseDTO? reviewPage;
  final List<Map<String, dynamic>> reviews;
  final bool isLoadingReviews;
  final bool reviewsError;
  final bool hasCurrentUserReviewed;
  final VoidCallback onWriteReviewTap;

  const ItemDetailReviewsSection({
    super.key,
    required this.description,
    required this.usagePolicies,
    required this.reviewPage,
    required this.reviews,
    required this.isLoadingReviews,
    required this.reviewsError,
    required this.hasCurrentUserReviewed,
    required this.onWriteReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(
          'Về Không Gian Này',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 15,
            color: context.textSecColor,
            height: 1.65,
          ),
        ).animate().fadeIn(delay: 500.ms),
        if (usagePolicies.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Quy định & Chính sách sử dụng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ).animate().fadeIn(delay: 550.ms),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usagePolicies,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: context.textColor,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
        const SizedBox(height: 32),
        Divider(color: context.borderColor),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                reviewPage != null && reviewPage!.totalReviews > 0
                    ? 'Đánh giá & Nhận xét (${reviewPage!.totalReviews})'
                    : 'Đánh giá & Nhận xét',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ),
            if (isLoadingReviews)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (hasCurrentUserReviewed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Đã đánh giá',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: onWriteReviewTap,
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text(
                  'Viết đánh giá',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 14),
        if (!isLoadingReviews && reviews.isEmpty)
          Text(
            reviewsError ? 'Không thể tải đánh giá.' : 'Chưa có đánh giá.',
            style: TextStyle(color: context.textSecColor),
          ),
        ...reviews
            .map((rev) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
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
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                NetworkImage(rev['avatar'] as String),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rev['name'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: context.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(
                                      (rev['rating'] as num).toInt(),
                                      (i) => const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      rev['date'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: context.textSecColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rev['comment'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList()
            .animate()
            .fadeIn(delay: 700.ms)
            .slideY(begin: 0.1),
      ],
    );
  }
}
