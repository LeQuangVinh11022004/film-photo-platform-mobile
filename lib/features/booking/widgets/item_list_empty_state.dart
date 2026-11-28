import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ItemListEmptyState extends StatelessWidget {
  final String categoryLabel;
  final IconData emptyIcon;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const ItemListEmptyState({
    super.key,
    required this.categoryLabel,
    required this.emptyIcon,
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: context.inputColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(
                emptyIcon,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Không tìm thấy $categoryLabel nào',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa hoặc chọn khoảng ngày khác xem sao nhé!',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Xóa bộ lọc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  minimumSize: const Size(0, 42),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
