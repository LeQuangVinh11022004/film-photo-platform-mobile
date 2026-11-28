import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/models/community_post_api_models.dart';

Future<void> showProfileMyPostsSheet({
  required BuildContext context,
  required List<CommunityPostResponseDTO> posts,
  required VoidCallback onOpenCommunity,
}) {
  final int totalCount = posts.length;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => Container(
      height: MediaQuery.of(sheetCtx).size.height * 0.72,
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Bài Đăng Cộng Đồng ($totalCount)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  onOpenCommunity();
                },
                child: const Text(
                  'Mở Diễn đàn',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: totalCount > 0
                ? ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...posts.map(
                        (post) => InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            onOpenCommunity();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              border: Border.all(color: context.borderColor),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: context.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${post.category ?? 'Cộng đồng Film'} • ${post.likeCount} thích • ${post.commentCount} bình luận',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.textSecColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: context.textSecColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text('Chưa có bài đăng cộng đồng.')),
          ),
        ],
      ),
    ),
  );
}
