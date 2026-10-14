
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/expert_question.dart';

class QuestionCard extends StatelessWidget {
  final ExpertQuestion question;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const QuestionCard({
    super.key,
    required this.question,
    required this.liked,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C5CFC);

    final elapsed = DateTime.now().difference(question.createdAt);
    final timeLabel = elapsed.inHours < 1
        ? '${elapsed.inMinutes.clamp(1, 59)} phút trước'
        : elapsed.inDays < 1
            ? '${elapsed.inHours} giờ trước'
            : '${elapsed.inDays} ngày trước';

    return Card(
      color: context.cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: context.textSecColor.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    child: Text(
                      question.author.isEmpty
                          ? '?'
                          : question.author[0].toUpperCase(),
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      question.author,
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: context.textSecColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  question.category,
                  style: const TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                question.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                question.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textSecColor,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: context.textSecColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 3,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: liked
                                ? Colors.pinkAccent
                                : context.textSecColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            liked ? 'Đã thích' : 'Yêu thích',
                            style: TextStyle(
                              color: liked
                                  ? Colors.pinkAccent
                                  : context.textSecColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 17,
                    color: context.textSecColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${question.comments.length} bình luận',
                    style: TextStyle(
                      color: context.textSecColor,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.textSecColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
