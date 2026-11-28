import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class BookingFlowStepHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final int currentStep;

  const BookingFlowStepHeader({
    super.key,
    required this.currentStep,
  });

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          _StepIndicator(
            step: 0,
            label: 'Ngày & Giờ',
            isActive: currentStep >= 0,
          ),
          const _StepDivider(),
          _StepIndicator(
            step: 1,
            label: 'Dịch vụ thêm',
            isActive: currentStep >= 1,
          ),
          const _StepDivider(),
          _StepIndicator(
            step: 2,
            label: 'Thanh toán',
            isActive: currentStep >= 2,
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;

  const _StepIndicator({
    required this.step,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : context.inputColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHint,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? context.textColor : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 2,
      color: context.inputColor,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }
}

class BookingFlowBottomBar extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final VoidCallback onNextPressed;

  const BookingFlowBottomBar({
    super.key,
    required this.currentStep,
    required this.isSubmitting,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: PrimaryButton(
          text: currentStep < 2 ? 'Tiếp tục' : 'Xác nhận & Sang thanh toán',
          isLoading: isSubmitting,
          onPressed: onNextPressed,
        ),
      ),
    );
  }
}
