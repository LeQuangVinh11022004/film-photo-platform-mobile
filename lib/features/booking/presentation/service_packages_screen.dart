import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/service_package.dart';

class ServicePackagesScreen extends StatefulWidget {
  const ServicePackagesScreen({super.key});

  @override
  State<ServicePackagesScreen> createState() => _ServicePackagesScreenState();
}

class _ServicePackagesScreenState extends State<ServicePackagesScreen> {
  final List<ServicePackage> _packages = ServicePackage.samplePackages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gói Dịch Vụ Combo Film All-In-One'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: _packages.length,
          itemBuilder: (context, index) {
            final pkg = _packages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SafeNetworkImage(
                        url: pkg.imageUrl,
                        height: 160,
                        width: double.infinity,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      if (pkg.isPopular)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COMBO BÁN CHẠY NHẤT',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pkg.category, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            Text(pkg.durationText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pkg.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pkg.description,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 14),

                        const Text('Gói dịch vụ bao gồm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        ...pkg.includes.map((inc) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(inc, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                                ],
                              ),
                            )),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${pkg.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                            SizedBox(
                              width: 150,
                              child: PrimaryButton(
                                text: 'ĐẶT COMBO',
                                onPressed: () {
                                  NotificationService().triggerLocalNotification(
                                    context: context,
                                    title: 'Đã Tạo Đơn Đặt Combo! 📦',
                                    body: 'Combo ${pkg.name} đã được chọn. Chuyển sang bước thanh toán.',
                                    route: '/payment',
                                  );
                                  Navigator.pushNamed(context, '/payment');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
