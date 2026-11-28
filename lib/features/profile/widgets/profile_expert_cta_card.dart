import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../expert/models/expert_application_state.dart';

class ProfileExpertCtaCard extends StatelessWidget {
  final bool isExpertRole;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onOpenApplication;

  const ProfileExpertCtaCard({
    super.key,
    required this.isExpertRole,
    required this.onOpenWorkspace,
    required this.onOpenApplication,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExpertApplicationStatus>(
      valueListenable: ExpertApplicationState.instance.status,
      builder: (context, status, child) {
        final isApproved =
            isExpertRole || status == ExpertApplicationStatus.approved;

        final isPending =
            !isExpertRole && status == ExpertApplicationStatus.pending;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                if (isApproved) {
                  onOpenWorkspace();
                } else if (!isPending) {
                  onOpenApplication();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isApproved
                            ? Icons.workspace_premium_rounded
                            : isPending
                                ? Icons.hourglass_top_rounded
                                : Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproved
                                ? 'Expert Workspace'
                                : isPending
                                    ? 'Application Pending'
                                    : 'Become an Expert',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isApproved
                                ? 'Mở không gian làm việc chuyên gia'
                                : isPending
                                    ? 'Đơn đăng ký của bạn đang được xét duyệt'
                                    : 'Chia sẻ kiến thức và đóng góp cho cộng đồng',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
