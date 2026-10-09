import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/device_image_picker.dart';
import '../../../core/services/notification_service.dart';

class AIRestorationScreen extends StatefulWidget {
  const AIRestorationScreen({super.key});

  @override
  State<AIRestorationScreen> createState() => _AIRestorationScreenState();
}

class _AIRestorationScreenState extends State<AIRestorationScreen> {
  double _sliderValue = 0.5; // Before/After split position
  bool _isProcessing = false;
  bool _scratchRemoval = true;
  bool _colorEnhance = true;
  bool _superResolution = true;

  String _beforeImage = 'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=800&auto=format&fit=crop&q=80';
  String _afterImage = 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&auto=format&fit=crop&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: context.cardColor, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Film Image Enhancer',
                          style: TextStyle(color: context.cardColor, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Khử nhiễu xước, làm nét hạt film 4K & phục hồi màu phim cổ',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // Interactive Before/After Split Viewer
            Text('So Sánh Ảnh Gốc vs Ảnh AI Khôi Phục', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor)),
            SizedBox(height: 14),

            Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                children: [
                  // After Image (Base)
                  Positioned.fill(
                    child: SafeNetworkImage(
                      url: _afterImage,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),

                  // Before Image (Clipped)
                  Positioned.fill(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _sliderValue,
                        child: SafeNetworkImage(
                          url: _beforeImage,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  // Labels
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                      child: Text('GỐC (BEFORE)', style: TextStyle(color: context.cardColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: Text('AI RESTORED', style: TextStyle(color: context.cardColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ),

                  // Slider Line Indicator
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: MediaQuery.of(context).size.width * _sliderValue * 0.84, // Adjust for padding
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
                      ),
                      child: Center(
                        child: CircleAvatar(radius: 12, backgroundColor: context.cardColor, child: Icon(Icons.code_rounded, size: 14, color: AppColors.primary)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Slider Control
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Slider(
                value: _sliderValue,
                activeColor: AppColors.primary,
                inactiveColor: context.borderColor,
                onChanged: (val) => setState(() => _sliderValue = val),
              ),
            ),
            SizedBox(height: 12),

            // AI Enhancements Options Toggles
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.borderColor),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildToggleRow('Khử bụi bẩn & vết xước film', _scratchRemoval, (val) => setState(() => _scratchRemoval = val)),
                  Divider(height: 16, color: context.inputColor),
                  _buildToggleRow('Làm nét chi tiết 4K (Super Resolution)', _superResolution, (val) => setState(() => _superResolution = val)),
                  Divider(height: 16, color: context.inputColor),
                  _buildToggleRow('Cân bằng & phục hồi màu sắc phim', _colorEnhance, (val) => setState(() => _colorEnhance = val)),
                ],
              ),
            ),
            SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = await DeviceImagePicker.pickImageFromDevice(context, title: 'Chọn Ảnh Film Từ Thiết Bị');
                      if (url != null) {
                        setState(() {
                          _beforeImage = url;
                          _afterImage = url;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nạp tệp ảnh film mới từ thiết bị!'), backgroundColor: Colors.green));
                        }
                      }
                    },
                    icon: Icon(Icons.upload_file_rounded),
                    label: Text('Tải Ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            setState(() => _isProcessing = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (!mounted) return;
                              setState(() => _isProcessing = false);
                              NotificationService().triggerLocalNotification(
                                context: context,
                                title: 'Phục Chế Ảnh Film AI Hoàn Tất! 🤖',
                                body: 'Ảnh film của bạn đã được AI xử lý làm nét 4K & khôi phục màu sắc thành công. Bấm để xem Bộ Sưu Tập.',
                                route: '/digital-collections',
                              );
                            });
                          },
                    icon: _isProcessing ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: context.cardColor)) : Icon(Icons.auto_fix_high_rounded, size: 22),
                    label: Text(_isProcessing ? 'Đang Xử Lý AI...' : 'Phục Chế 4K', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: context.cardColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textColor))),
          Switch(
            value: value,
            activeColor: context.cardColor,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: context.inputColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


