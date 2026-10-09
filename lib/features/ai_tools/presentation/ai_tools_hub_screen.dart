import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'ai_assistant_screen.dart';
import 'ai_restoration_screen.dart';

class AIToolsHubScreen extends StatefulWidget {
  const AIToolsHubScreen({super.key});

  @override
  State<AIToolsHubScreen> createState() => _AIToolsHubScreenState();
}

class _AIToolsHubScreenState extends State<AIToolsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Trung Tâm Công Cụ AI Film'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: context.textSecColor,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_filter_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Phục Chế Ảnh'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Trợ Lý AI'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          AIRestorationScreen(),
          AIAssistantScreen(),
        ],
      ),
    );
  }
}


