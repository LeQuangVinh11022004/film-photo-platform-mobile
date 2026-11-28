import 'package:flutter/material.dart';
import '../../../app/main.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_colors.dart';

Future<void> showProfileAccountSettingsSheet({
  required BuildContext context,
  required VoidCallback onOpenForgotPassword,
  required VoidCallback onCheckUpdate,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            'Cài Đặt Tài Khoản',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Thông báo ứng dụng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Nhận thông báo lịch đặt & bài viết',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: true,
                      activeThumbColor: context.cardColor,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text(
                        'Giao diện tối (Dark Mode)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Đổi giao diện sang nền đen',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isDark,
                      activeThumbColor: context.cardColor,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        themeNotifier.value =
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text(
                        'Đổi mật khẩu bảo mật',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        onOpenForgotPassword();
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text(
                        'Kiểm tra cập nhật ứng dụng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Phiên bản hiện tại: v${AppUpdateService.currentAppVersion}',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.system_update_rounded,
                        color: AppColors.primary,
                      ),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        onCheckUpdate();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
