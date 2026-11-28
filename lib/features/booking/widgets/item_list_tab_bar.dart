import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class ItemListTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final int studioCount;
  final int darkroomCount;
  final int equipmentCount;

  const ItemListTabBar({
    super.key,
    required this.tabController,
    required this.studioCount,
    required this.darkroomCount,
    required this.equipmentCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.inputColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: context.textSecColor,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 15),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Studio ($studioCount)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wb_twilight_rounded, size: 15),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Phòng Tối ($darkroomCount)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_back_outlined, size: 15),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Thiết Bị ($equipmentCount)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ItemListFilterHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final DateTime? selectedFromDate;
  final DateTime? selectedToDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;

  const ItemListFilterHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedFromDate,
    required this.selectedToDate,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.inputColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                controller: searchController,
                style: GoogleFonts.inter(fontSize: 13, color: context.textColor),
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm kiếm tên, địa chỉ...',
                  hintStyle:
                      GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: onClearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onPickDateRange,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selectedFromDate != null
                    ? (context.isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.3)
                        : AppColors.primarySoft)
                    : context.inputColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedFromDate != null
                      ? AppColors.primary
                      : context.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: selectedFromDate != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedFromDate != null && selectedToDate != null
                        ? '${DateFormat('dd/MM').format(selectedFromDate!)} - ${DateFormat('dd/MM').format(selectedToDate!)}'
                        : 'Chọn ngày',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selectedFromDate != null
                          ? AppColors.primary
                          : context.textColor,
                    ),
                  ),
                  if (selectedFromDate != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onClearDateRange,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
