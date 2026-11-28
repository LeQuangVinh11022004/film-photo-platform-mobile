import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String email;
  final String roleLabel;
  final String bio;
  final bool isExpertRole;
  final int totalBookingsCount;
  final int totalSubscriptionsCount;
  final int totalPostsCount;
  final String averageReviewLabel;
  final VoidCallback onChangeAvatarTap;
  final VoidCallback onBookingsTap;
  final VoidCallback onSubscriptionsTap;
  final VoidCallback onPostsTap;
  final VoidCallback onReviewsTap;

  const ProfileHeaderCard({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.bio,
    required this.isExpertRole,
    required this.totalBookingsCount,
    required this.totalSubscriptionsCount,
    required this.totalPostsCount,
    required this.averageReviewLabel,
    required this.onChangeAvatarTap,
    required this.onBookingsTap,
    required this.onSubscriptionsTap,
    required this.onPostsTap,
    required this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarProvider = (avatarUrl.startsWith('http://') ||
            avatarUrl.startsWith('https://'))
        ? NetworkImage(avatarUrl)
        : FileImage(
            File(
              avatarUrl.startsWith('file://')
                  ? Uri.parse(avatarUrl).toFilePath()
                  : avatarUrl,
            ),
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: context.inputColor,
                  backgroundImage: avatarProvider,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onChangeAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.cardColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: context.cardColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.inputColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isExpertRole) ...[
                  _StatItem(
                    value: '$totalBookingsCount',
                    label: 'Lịch đặt',
                    onTap: onBookingsTap,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: context.borderColor,
                  ),
                  _StatItem(
                    value: '$totalSubscriptionsCount',
                    label: 'Gói đã mua',
                    onTap: onSubscriptionsTap,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: context.borderColor,
                  ),
                ],
                _StatItem(
                  value: '$totalPostsCount',
                  label: 'Bài đăng',
                  onTap: onPostsTap,
                ),
                if (!isExpertRole) ...[
                  Container(
                    width: 1,
                    height: 32,
                    color: context.borderColor,
                  ),
                  _StatItem(
                    value: averageReviewLabel,
                    label: 'Đánh giá',
                    isStar: true,
                    onTap: onReviewsTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isStar;
  final VoidCallback onTap;

  const _StatItem({
    required this.value,
    required this.label,
    this.isStar = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
              ),
              if (isStar) ...[
                const SizedBox(width: 2),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecColor,
            ),
          ),
        ],
      ),
    );
  }
}
