import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileSettingsMenu extends StatelessWidget {
  final bool isExpertRole;
  final VoidCallback onEditProfile;
  final VoidCallback onBookingHistory;
  final VoidCallback onServicePackages;
  final VoidCallback onSavedList;
  final VoidCallback onMyPosts;
  final VoidCallback onAccountSettings;
  final VoidCallback onLogout;

  const ProfileSettingsMenu({
    super.key,
    required this.isExpertRole,
    required this.onEditProfile,
    required this.onBookingHistory,
    required this.onServicePackages,
    required this.onSavedList,
    required this.onMyPosts,
    required this.onAccountSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Tùy Chọn & Cài Đặt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _ProfileTile(
                icon: Icons.person_outline_rounded,
                title: 'Thông tin cá nhân',
                onTap: onEditProfile,
              ),
              if (!isExpertRole) ...[
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: context.inputColor,
                ),
                _ProfileTile(
                  icon: Icons.history_rounded,
                  title: 'Lịch sử đặt phòng & thiết bị',
                  onTap: onBookingHistory,
                ),
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: context.inputColor,
                ),
                _ProfileTile(
                  icon: Icons.card_membership_rounded,
                  title: 'Gói dịch vụ & Subscription của tôi',
                  onTap: onServicePackages,
                ),
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: context.inputColor,
                ),
                _ProfileTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Danh sách Studio đã lưu',
                  onTap: onSavedList,
                ),
              ],
              Divider(
                height: 1,
                indent: 60,
                endIndent: 20,
                color: context.inputColor,
              ),
              _ProfileTile(
                icon: Icons.history_rounded,
                title: 'Lịch sử bài đăng',
                onTap: onMyPosts,
              ),
              Divider(
                height: 1,
                indent: 60,
                endIndent: 20,
                color: context.inputColor,
              ),
              _ProfileTile(
                icon: Icons.settings_outlined,
                title: 'Cài đặt ứng dụng',
                onTap: onAccountSettings,
              ),
              Divider(
                height: 1,
                indent: 60,
                endIndent: 20,
                color: context.inputColor,
              ),
              _ProfileTile(
                icon: Icons.logout_rounded,
                title: 'Đăng xuất tài khoản',
                isDestructive: true,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.shade50
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : context.textColor,
        ),
      ),
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 24,
            ),
      onTap: onTap,
    );
  }
}
