import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class ItemDetailBottomBar extends StatelessWidget {
  final double pricePerHour;
  final VoidCallback onBookPressed;

  const ItemDetailBottomBar({
    super.key,
    required this.pricePerHour,
    required this.onBookPressed,
  });

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(24, 18, 24, 18 + bottomInset),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá chỉ từ',
                  style: TextStyle(fontSize: 12, color: context.textSecColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatPrice(pricePerHour)}đ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 54,
              child: PrimaryButton(
                text: 'Đặt Ngay',
                onPressed: onBookPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
