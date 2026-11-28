import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/blog_post.dart';
import '../models/community_post_api_models.dart';
import 'community_post_card.dart';

Future<void> showCommunityPostDetailSheet({
  required BuildContext context,
  BlogPost? post,
  CommunityPostResponseDTO? loadedCommunityPost,
  required bool isMyOwnCommPost,
  required ValueChanged<BlogPost> onOpenComments,
  required ValueChanged<CommunityPostResponseDTO> onEdit,
  required ValueChanged<CommunityPostResponseDTO> onDelete,
}) {
  final displayTitle = loadedCommunityPost?.title ?? post?.title ?? '';
  final displayContent = loadedCommunityPost?.content ?? post?.content ?? '';
  final displayAuthor =
      loadedCommunityPost?.authorName ?? post?.authorName ?? 'Thành viên Film';
  final displayCategory =
      loadedCommunityPost?.category ?? post?.category ?? 'Kỹ thuật Film';
  final displayStatus =
      loadedCommunityPost?.status ?? post?.status ?? 'PUBLISHED';
  final displayTime = loadedCommunityPost != null
      ? CommunityPostResponseDTO.formatTimeAgo(
          loadedCommunityPost.updatedAt ?? loadedCommunityPost.createdAt,
        )
      : (post?.timeAgo ?? 'Vừa xong');

  final List<String> displayImages =
      loadedCommunityPost != null && loadedCommunityPost.images.isNotEmpty
          ? loadedCommunityPost.images.map((e) => e.imageUrl).toList()
          : (post?.imageUrl != null ? [post!.imageUrl!] : []);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final bottomInset = math.max(
        MediaQuery.paddingOf(ctx).bottom,
        MediaQuery.viewPaddingOf(ctx).bottom,
      );
      return DraggableScrollableSheet(
        initialChildSize: 0.80,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomInset),
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
              const SizedBox(height: 18),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            displayCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        CommunityArticleStatusBadge(status: displayStatus),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayTime,
                    style: TextStyle(fontSize: 12, color: context.textSecColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tác giả: $displayAuthor',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              if (displayImages.isNotEmpty) ...[
                ...displayImages.map(
                  (imgUrl) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SafeNetworkImage(
                      url: imgUrl,
                      width: double.infinity,
                      height: 210,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                displayContent,
                style: TextStyle(
                  fontSize: 15,
                  color: context.textColor,
                  height: 1.65,
                ),
              ),
              if (loadedCommunityPost != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                loadedCommunityPost.isLiked
                                    ? Icons.thumb_up_rounded
                                    : Icons.thumb_up_alt_outlined,
                                size: 18,
                                color: loadedCommunityPost.isLiked
                                    ? AppColors.primary
                                    : context.textSecColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${loadedCommunityPost.likeCount} lượt thích',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: context.textSecColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${loadedCommunityPost.commentCount} bình luận',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onOpenComments(
                          post ?? loadedCommunityPost.toBlogPost(),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.forum_outlined, size: 17),
                      label: const Text('Mở Bình Luận'),
                    ),
                  ],
                ),
              ],
              if (isMyOwnCommPost && loadedCommunityPost != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onEdit(loadedCommunityPost);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sửa bài đăng',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete(loadedCommunityPost);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Xóa bài đăng',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
