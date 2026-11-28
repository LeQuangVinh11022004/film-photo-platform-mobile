import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CommunityViewModeToggle extends StatelessWidget {
  final int viewMode;
  final int myPostsCount;
  final ValueChanged<int> onModeChanged;

  const CommunityViewModeToggle({
    super.key,
    required this.viewMode,
    required this.myPostsCount,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.inputColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onModeChanged(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        viewMode == 0 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Diễn Đàn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: viewMode == 0 ? Colors.white : context.textColor,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onModeChanged(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        viewMode == 1 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Bài Đăng ($myPostsCount)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: viewMode == 1 ? Colors.white : context.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunitySearchAndFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final int viewMode;
  final List<String> filters;
  final int selectedFilterIndex;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<int> onFilterSelected;

  const CommunitySearchAndFilters({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.viewMode,
    required this.filters,
    required this.selectedFilterIndex,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.inputColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                filled: false,
                hintText: 'Tìm kiếm bài viết, chủ đề, tác giả...',
                hintStyle:
                    const TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.textSecColor,
                  size: 22,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: onClearSearch,
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (viewMode == 0)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final isSelected = selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Center(
                    child: ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(filters[index]),
                      backgroundColor:
                          isSelected ? AppColors.primary : context.cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : context.borderColor,
                        ),
                      ),
                      onPressed: () => onFilterSelected(index),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
