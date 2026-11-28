import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Thanh phân trang dùng chung cho các danh sách (Studio, Phòng tối, Thiết bị, Diễn đàn).
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String itemLabel;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.itemLabel = 'mục',
  });

  List<int?> _buildPageNumbers() {
    if (totalPages <= 5) {
      return List<int?>.generate(totalPages, (i) => i + 1);
    }

    final pages = <int?>[1];
    final start = (currentPage - 1).clamp(2, totalPages - 1);
    final end = (currentPage + 1).clamp(2, totalPages - 1);

    if (start > 2) pages.add(null);
    for (int p = start; p <= end; p++) {
      pages.add(p);
    }
    if (end < totalPages - 1) pages.add(null);
    pages.add(totalPages);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) return const SizedBox.shrink();

    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final safeCurrent = currentPage.clamp(1, safeTotalPages);
    final startItem = ((safeCurrent - 1) * pageSize) + 1;
    final endItem = (safeCurrent * pageSize) > totalItems
        ? totalItems
        : (safeCurrent * pageSize);

    final pages = _buildPageNumbers();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hiển thị $startItem–$endItem / $totalItems $itemLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textSecColor,
                ),
              ),
              Text(
                'Trang $safeCurrent / $safeTotalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (safeTotalPages > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: safeCurrent > 1,
                  onTap: () => onPageChanged(safeCurrent - 1),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: pages.map((page) {
                        if (page == null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '…',
                              style: TextStyle(
                                color: context.textSecColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        final isSelected = page == safeCurrent;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: isSelected ? null : () => onPageChanged(page),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : context.inputColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : context.borderColor,
                                ),
                              ),
                              child: Text(
                                '$page',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : context.textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: safeCurrent < safeTotalPages,
                  onTap: () => onPageChanged(safeCurrent + 1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? context.inputColor : context.inputColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? context.textColor : AppColors.textHint.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
