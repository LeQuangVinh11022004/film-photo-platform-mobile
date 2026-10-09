import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai_tools/presentation/ai_tools_hub_screen.dart';
import '../../booking/presentation/schedule_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    ScheduleScreen(),
    AIToolsHubScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Cho phép nội dung trượt luồn dưới Bottom Navigation Bar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Cải tiến Navbar dạng Floating Floating Capsule (Viên nhộng nổi)
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(32), // Bo tròn cực độ dạng viên nhộng
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
              _buildNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Khám phá'),
              _buildNavItem(index: 1, icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Lịch đặt'),
              _buildNavItem(index: 2, icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'AI Tools'),
              _buildNavItem(index: 3, icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Diễn đàn'),
              _buildNavItem(index: 4, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Cá nhân'),
            ],
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
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : context.textSecColor,
              size: 24,
            ),
            // Hiệu ứng mở rộng chữ khi được chọn (rất hiện đại)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuint,
              child: isSelected
                  ? Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.primary,
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


