import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StudioComparisonTabBar extends StatelessWidget {
  final int selectedTab;
  final int studioCount;
  final int darkroomCount;
  final ValueChanged<int> onTabChanged;

  const StudioComparisonTabBar({
    super.key,
    required this.selectedTab,
    required this.studioCount,
    required this.darkroomCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.inputColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selectedTab == 0
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: selectedTab == 0
                            ? Colors.white
                            : context.textSecColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Studio ($studioCount)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: selectedTab == 0
                              ? Colors.white
                              : context.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selectedTab == 1
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wb_twilight_rounded,
                        size: 16,
                        color: selectedTab == 1
                            ? Colors.white
                            : context.textSecColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Phòng Tối ($darkroomCount)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: selectedTab == 1
                              ? Colors.white
                              : context.textColor,
                        ),
                      ),
                    ],
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
