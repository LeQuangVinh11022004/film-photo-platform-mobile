
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'expert_home_screen.dart';

class ExpertNavigationScreen extends StatefulWidget {
  const ExpertNavigationScreen({super.key});

  @override
  State<ExpertNavigationScreen> createState() =>
      _ExpertNavigationScreenState();
}

class _ExpertNavigationScreenState
    extends State<ExpertNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const ExpertHomeScreen(),
    const _ExpertPlaceholderScreen(
      title: 'Lịch trình',
      description: 'Quản lý lịch tư vấn và các lịch hẹn của bạn.',
      icon: Icons.calendar_month_rounded,
    ),
    const _ExpertPlaceholderScreen(
      title: 'Bài viết',
      description: 'Tạo và quản lý các bài chia sẻ kiến thức nhiếp ảnh film.',
      icon: Icons.article_outlined,
    ),
    const _ExpertPlaceholderScreen(
      title: 'Hỏi đáp',
      description: 'Xem câu hỏi và chia sẻ kiến thức chuyên môn.',
      icon: Icons.forum_outlined,
    ),
    const _ExpertPlaceholderScreen(
      title: 'Hồ sơ',
      description: 'Quản lý hồ sơ và thông tin chuyên gia của bạn.',
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch trình',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'Bài viết',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Hỏi đáp',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

class _ExpertPlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _ExpertPlaceholderScreen({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
