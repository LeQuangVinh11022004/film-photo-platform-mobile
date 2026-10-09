import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/device_image_picker.dart';
import '../../booking/models/booking_item.dart';
import '../../booking/models/booking_schedule.dart';
import '../../../app/main.dart'; // Import themeNotifier

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Lê Hoàng Anh';
  String _phone = '0901 234 567';
  final String _email = 'hoanganh.film@gmail.com';
  String _bio = 'Nhiếp ảnh gia chuyên nghiệp đam mê chất phim Analog 35mm & Medium Format.';
  String _avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80';

  void _showChangeAvatarModal() async {
    final pickedUrl = await DeviceImagePicker.pickImageFromDevice(
      context,
      title: 'Chọn Ảnh Đại Diện Từ Thiết Bị',
    );

    if (!mounted) return;

    if (pickedUrl != null && pickedUrl.isNotEmpty) {
      setState(() {
        _avatarUrl = pickedUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh đại diện mới từ thiết bị!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final bioController = TextEditingController(text: _bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Chỉnh Sửa Thông Tin Cá Nhân',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
              ),
              SizedBox(height: 24),

              _buildInputLabel('Họ và tên'),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập họ tên',
                  filled: true,
                  fillColor: context.inputColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              SizedBox(height: 16),
              
              _buildInputLabel('Số điện thoại'),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  filled: true,
                  fillColor: context.inputColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              SizedBox(height: 16),
              
              _buildInputLabel('Giới thiệu bản thân (Bio)'),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Viết vài dòng giới thiệu...',
                  filled: true,
                  fillColor: context.inputColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _name = nameController.text.trim();
                    _phone = phoneController.text.trim();
                    _bio = bioController.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thông tin thành công!'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Lưu Thay Đổi', style: TextStyle(color: context.cardColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textColor),
      ),
    );
  }

  void _showBookingHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Lịch Sử Đặt Phòng & Thiết Bị',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: BookingSchedule.sampleSchedules.length,
                itemBuilder: (context, index) {
                  final s = BookingSchedule.sampleSchedules[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textColor)),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_rounded, size: 14, color: context.textSecColor),
                                  SizedBox(width: 4),
                                  Text('${s.bookingDate.day}/${s.bookingDate.month}/${s.bookingDate.year} • ${s.timeSlot}', style: TextStyle(fontSize: 13, color: context.textSecColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${s.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                            ),
                            SizedBox(height: 4),
                            Text(s.statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.status == BookingStatus.confirmed ? Colors.green : AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyPostsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Bài Viết Của Tôi (12)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bài viết #${index + 1}: Kỹ thuật chụp film ngoài trời', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textColor)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.favorite_rounded, size: 14, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text('128 lượt thích', style: TextStyle(fontSize: 12, color: context.textSecColor)),
                            SizedBox(width: 16),
                            Icon(Icons.mode_comment_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('24 bình luận', style: TextStyle(fontSize: 12, color: context.textSecColor)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Đánh Giá Nhận Được',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.inputColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text('4.9', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) => Icon(Icons.star_rounded, color: Colors.amber, size: 20)),
                        ),
                        SizedBox(height: 6),
                        Text('Dựa trên 15 lượt đánh giá từ khách hàng & đối tác.', style: TextStyle(fontSize: 13, color: context.textSecColor, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedListModal() {
    final favorites = BookingItem.sampleItems.where((i) => i.isFavorite).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Danh Sách Đã Lưu (${favorites.length})',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            SizedBox(height: 20),
            Expanded(
              child: favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('Chưa có mục nào được lưu', style: TextStyle(color: context.textSecColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final item = favorites[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            border: Border.all(color: context.borderColor),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(item.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textColor)),
                                    SizedBox(height: 4),
                                    Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.textSecColor)),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.favorite_rounded, color: Colors.red),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Cài Đặt Tài Khoản',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            SizedBox(height: 20),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Thông báo ứng dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('Nhận thông báo lịch đặt & bài viết', style: TextStyle(fontSize: 12)),
                        value: true,
                        activeColor: context.cardColor,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {},
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Text('Giao diện tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('Đổi giao diện sang nền đen', style: TextStyle(fontSize: 12)),
                        value: isDark,
                        activeColor: context.cardColor,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text('Đổi mật khẩu bảo mật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                      ),
                    ],
                  ),
                );
              }
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Trang Cá Nhân'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Avatar & Name Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: context.inputColor,
                            backgroundImage: _avatarUrl.startsWith('http') 
                                ? NetworkImage(_avatarUrl) as ImageProvider
                                : FileImage(File(_avatarUrl)),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _showChangeAvatarModal,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.cardColor, width: 3),
                              ),
                              child: Icon(Icons.camera_alt_rounded, size: 16, color: context.cardColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _email,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nhiếp ảnh gia (Photographer)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: context.textSecColor, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 28),

                    // Interactive Stats Row
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            value: '${BookingSchedule.sampleSchedules.length}',
                            label: 'Lịch đặt',
                            onTap: _showBookingHistoryModal,
                          ),
                          Container(width: 1, height: 32, color: context.borderColor),
                          _StatItem(
                            value: '12',
                            label: 'Bài viết',
                            onTap: _showMyPostsModal,
                          ),
                          Container(width: 1, height: 32, color: context.borderColor),
                          _StatItem(
                            value: '4.9',
                            label: 'Đánh giá',
                            isStar: true,
                            onTap: _showMyReviewsModal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Sleek Modern Settings List Card
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                  child: Text('Tùy Chọn & Cài Đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Thông tin cá nhân',
                      onTap: _showEditProfileModal,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 20, color: context.inputColor),
                    _ProfileTile(
                      icon: Icons.history_rounded,
                      title: 'Lịch sử đặt phòng & thiết bị',
                      onTap: _showBookingHistoryModal,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 20, color: context.inputColor),
                    _ProfileTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Danh sách Studio đã lưu',
                      onTap: _showSavedListModal,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 20, color: context.inputColor),
                    _ProfileTile(
                      icon: Icons.photo_album_outlined,
                      title: 'Album ảnh Film số hóa',
                      onTap: () => Navigator.pushNamed(context, '/digital-collections'),
                    ),
                    Divider(height: 1, indent: 60, endIndent: 20, color: context.inputColor),
                    _ProfileTile(
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt ứng dụng',
                      onTap: _showAccountSettingsModal,
                    ),
                    Divider(height: 1, indent: 60, endIndent: 20, color: context.inputColor),

                    // Logout Tile at the bottom of settings list
                    _ProfileTile(
                      icon: Icons.logout_rounded,
                      title: 'Đăng xuất tài khoản',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100), // Spacing for floating navbar
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isStar;
  final VoidCallback onTap;

  const _StatItem({
    required this.value,
    required this.label,
    this.isStar = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
              ),
              if (isStar) ...[
                SizedBox(width: 2),
                Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              ],
            ],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : context.textColor,
        ),
      ),
      trailing: isDestructive ? null : Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 24),
      onTap: onTap,
    );
  }
}


