import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class ServiceSubscriptionEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onExplorePressed;

  const ServiceSubscriptionEmptyState({
    super.key,
    required this.onRefresh,
    required this.onExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.cardColor,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.card_membership_rounded,
            size: 68,
            color: AppColors.textHint.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có gói dịch vụ nào đã đăng ký',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy chọn mua một Gói Combo ở tab bên cạnh để tiết kiệm chi phí thuê Studio, Phòng tối và Thiết bị hàng tháng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'KHÁM PHÁ GÓI COMBO',
            onPressed: onExplorePressed,
          ),
        ],
      ),
    );
  }
}
