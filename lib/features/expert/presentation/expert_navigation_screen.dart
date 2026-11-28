import 'package:flutter/material.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/presentation/community_screen.dart';
import './schedules/expert_schedule_screen.dart';
import './qa/expert_qa_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'expert_home_screen.dart';

class ExpertNavigationScreen extends StatefulWidget {
  const ExpertNavigationScreen({super.key});

  @override
  State<ExpertNavigationScreen> createState() => _ExpertNavigationScreenState();
}

class _ExpertNavigationScreenState extends State<ExpertNavigationScreen> {
  int _currentIndex = 0;

  // Màu nhận diện riêng của Expert.
  static const Color _expertAccent = Color(0xFF7C5CFC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService().checkAndPromptUpdate(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        // Nội dung có thể chạy phía dưới thanh điều hướng nổi.
        extendBody: true,

        body: IndexedStack(
          index: _currentIndex,
          children: const [
            ExpertHomeScreen(),
            ExpertScheduleScreen(),
            CommunityScreen(),
            ExpertQaScreen(),
            ProfileScreen(),
          ],
        ),

        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Lịch trình',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.article_outlined,
                  activeIcon: Icons.article_rounded,
                  label: 'Bài viết',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum_rounded,
                  label: 'Hỏi đáp',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Hồ sơ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _expertAccent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? _expertAccent : context.textSecColor,
              size: 24,
            ),

            // Mở rộng nhãn bằng animation khi chọn tab.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuint,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: _expertAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
