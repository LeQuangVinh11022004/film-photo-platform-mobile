import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/blog_post.dart';
import '../models/community_post_api_models.dart';

class CommunityArticleStatusBadge extends StatelessWidget {
  final String status;

  const CommunityArticleStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPub = status.toUpperCase() == 'PUBLISHED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPub ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPub ? 'Đã xuất bản' : 'Bản nháp',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPub ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class CommunityPostCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onOpenDetail;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onShareTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onOpenDetail,
    required this.onLikeTap,
    required this.onCommentsTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
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
                      Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                post.authorRole,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              post.timeAgo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: context.textSecColor,
                  ),
                  tooltip: 'Xem chi tiết bài viết',
                  onPressed: onOpenDetail,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 14),
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SafeNetworkImage(
                  url: post.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            Divider(height: 1, color: context.inputColor),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: onLikeTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.userReaction == 'like'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.userReaction == 'like'
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_alt_outlined,
                          color: post.userReaction == 'like'
                              ? AppColors.primary
                              : context.textSecColor,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            color: post.userReaction == 'like'
                                ? AppColors.primary
                                : context.textSecColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCommentsTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: context.textSecColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          color: context.textSecColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onShareTap,
                  child: Icon(
                    Icons.share_outlined,
                    color: context.textSecColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityMyPostCard extends StatelessWidget {
  final CommunityPostResponseDTO post;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenComments;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommunityMyPostCard({
    super.key,
    required this.post,
    required this.onOpenDetail,
    required this.onOpenComments,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.category ?? 'Cộng đồng Film',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      CommunityArticleStatusBadge(status: post.status),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CommunityPostResponseDTO.formatTimeAgo(
                    post.updatedAt ?? post.createdAt,
                  ),
                  style: TextStyle(fontSize: 12, color: context.textSecColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecColor,
                height: 1.45,
              ),
            ),
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SafeNetworkImage(
                url: post.images.first.imageUrl,
                width: double.infinity,
                height: 160,
                borderRadius: BorderRadius.circular(14),
              ),
            ],
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            post.isLiked
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_alt_outlined,
                            size: 16,
                            color: post.isLiked
                                ? AppColors.primary
                                : context.textSecColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likeCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textSecColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onOpenComments,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: context.textSecColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.commentCount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textSecColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Sửa'),
                ),
                IconButton(
                  tooltip: 'Xóa bài đăng',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
