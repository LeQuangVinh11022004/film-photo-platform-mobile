
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ExpertHomeScreen extends StatelessWidget {
  const ExpertHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Expert Workspace'),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng thông báo sẽ được bổ sung sau.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),

              _buildSectionTitle(
                context,
                'Tổng quan hoạt động',
                'Theo dõi hoạt động chuyên môn của bạn',
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: const [
                  _MetricCard(
                    title: 'Bài viết',
                    value: '12',
                    subtitle: 'Đã xuất bản',
                    icon: Icons.article_outlined,
                  ),
                  _MetricCard(
                    title: 'Câu trả lời',
                    value: '28',
                    subtitle: 'Đã đóng góp',
                    icon: Icons.forum_outlined,
                  ),
                  _MetricCard(
                    title: 'Lượt tương tác',
                    value: '356',
                    subtitle: 'Trên các bài viết',
                    icon: Icons.favorite_border_rounded,
                  ),
                  _MetricCard(
                    title: 'Đánh giá',
                    value: '4.8/5',
                    subtitle: 'Từ cộng đồng',
                    icon: Icons.star_outline_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _buildSectionTitle(
                context,
                'Câu hỏi cần chú ý',
                'Một số chủ đề cộng đồng đang thảo luận',
              ),
              const SizedBox(height: 14),

              _QuestionCard(
                category: 'Kỹ thuật chụp ảnh',
                title: 'Vì sao ảnh film của tôi thường bị thiếu sáng?',
                author: 'Nguyễn Minh',
                replies: 3,
              ),
              const SizedBox(height: 12),

              _QuestionCard(
                category: 'Tráng film',
                title: 'Người mới nên bắt đầu tráng film đen trắng thế nào?',
                author: 'Trần Anh',
                replies: 0,
              ),

              const SizedBox(height: 28),

              _buildSectionTitle(
                context,
                'Truy cập nhanh',
                'Tiếp tục công việc của bạn',
              ),
              const SizedBox(height: 14),

              _QuickAction(
                icon: Icons.edit_note_rounded,
                title: 'Viết bài chia sẻ',
                subtitle: 'Chia sẻ kinh nghiệm nhiếp ảnh film',
                onTap: () => _showComingSoon(context),
              ),
              const SizedBox(height: 10),

              _QuickAction(
                icon: Icons.question_answer_outlined,
                title: 'Trả lời câu hỏi',
                subtitle: 'Giúp cộng đồng giải quyết vấn đề',
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'VERIFIED EXPERT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Xin chào, Minh!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chia sẻ kiến thức của bạn và cùng cộng đồng '
            'khám phá thế giới nhiếp ảnh film.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecColor,
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng này sẽ được triển khai ở bước tiếp theo.'),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textSecColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textSecColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String category;
  final String title;
  final String author;
  final int replies;

  const _QuestionCard({
    required this.category,
    required this.title,
    required this.author,
    required this.replies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: context.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: context.textSecColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  author,
                  style: TextStyle(
                    color: context.textSecColor,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: context.textSecColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$replies trả lời',
                style: TextStyle(
                  color: context.textSecColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.textSecColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textSecColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
