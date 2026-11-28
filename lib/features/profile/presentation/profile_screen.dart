import 'package:flutter/material.dart';

import 'dart:io';

import '../../../core/services/app_update_service.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/device_image_picker.dart';
import '../../auth/services/auth_service.dart';
import '../../booking/models/booking_api_models.dart';
import '../../booking/models/booking_item.dart';
import '../../booking/models/review_api_models.dart';
import '../../booking/presentation/schedule_screen.dart';
import '../../booking/services/booking_api_service.dart';
import '../../booking/services/review_api_service.dart';
import '../../community/models/community_post_api_models.dart';
import '../../community/presentation/community_screen.dart';
import '../../community/services/community_post_api_service.dart';
import '../../../app/main.dart'; // Import themeNotifier

import '../../expert/models/expert_application_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Lê Hoàng Anh';
  String _phone = '0901 234 567';
  String _email = 'hoanganh.film@gmail.com';
  String _roleLabel = 'Nhiếp ảnh gia (Photographer)';
  bool _isExpertRole = false;
  int _totalBookingsCount = 0;
  int _totalSubscriptionsCount = 0;
  List<BookingResponseDTO> _loadedBookings = [];
  String _bio =
      'Nhiếp ảnh gia chuyên nghiệp đam mê chất phim Analog 35mm & Medium Format.';
  String _avatarUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80';

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      if (user.fullName.trim().isNotEmpty) {
        _name = user.fullName.trim();
      }
      if (user.email.trim().isNotEmpty) {
        _email = user.email.trim();
      }
      final rawRole = user.role.trim().toUpperCase();
      if (rawRole.contains('EXPERT')) {
        _isExpertRole = true;
        _roleLabel = 'Chuyên gia (Film Expert)';
        _bio =
            'Chuyên gia Nhiếp ảnh Film & Phòng tối — hướng dẫn kỹ thuật tráng rọi và đo sáng.';
      } else {
        _roleLabel = 'Nhiếp ảnh gia (Photographer)';
      }
    }
    _loadProfileApiStats();
  }

  List<CommunityPostResponseDTO> _loadedMyCommunityPosts = [];
  List<SpaceReviewResponseDTO> _loadedSpaceReviews = [];
  Map<String, BookingItem> _loadedSpacesById = {};

  Future<void> _loadProfileApiStats() async {
    try {
      if (_isExpertRole) {
        final myPostsPage =
            await CommunityPostApiService().getMyPosts(page: 1, pageSize: 50);
        if (!mounted) return;
        setState(() {
          if (myPostsPage != null) {
            _loadedMyCommunityPosts = myPostsPage.items;
          }
        });
        return;
      }

      final results = await Future.wait([
        BookingApiService().getMyBookings(page: 1, pageSize: 50),
        BookingApiService().getPackageSubscriptions(),
        CommunityPostApiService().getMyPosts(page: 1, pageSize: 50),
        BookingApiService().getStudios(),
        BookingApiService().getDarkrooms(),
      ]);
      if (!mounted) return;
      final page = results[0] as PagedResponseDTO<BookingResponseDTO>?;
      final subs =
          results[1] as List<PhotographerPackageSubscriptionResponseDTO>;
      final myPostsPage =
          results[2] as PagedResponseDTO<CommunityPostResponseDTO>?;
      final studios = results[3] as List<ResourceItemResponseDTO>;
      final darkrooms = results[4] as List<ResourceItemResponseDTO>;

      final List<SpaceReviewResponseDTO> collectedReviews = [];
      final reviewFutures = <Future<SpaceReviewPageResponseDTO?>>[
        ...studios.take(5).map((s) => ReviewApiService().getStudioReviews(
              studioId: s.resourceId,
              page: 1,
              pageSize: 20,
            )),
        ...darkrooms.take(5).map((d) => ReviewApiService().getDarkroomReviews(
              darkroomId: d.resourceId,
              page: 1,
              pageSize: 20,
            )),
      ];
      final reviewPages = await Future.wait(reviewFutures);
      for (final revPage in reviewPages) {
        if (revPage != null) {
          collectedReviews.addAll(revPage.items);
        }
      }

      final Map<String, BookingItem> spacesMap = {
        for (final s in studios) s.resourceId.toLowerCase(): s.toBookingItem(),
        for (final d in darkrooms) d.resourceId.toLowerCase(): d.toBookingItem(),
      };

      if (!mounted) return;
      setState(() {
        _loadedSpacesById = spacesMap;
        if (page != null) {
          _loadedBookings = page.items;
          _totalBookingsCount = page.totalCount > 0
              ? page.totalCount
              : page.items.length;
        }
        _totalSubscriptionsCount = subs.length;
        if (myPostsPage != null) {
          _loadedMyCommunityPosts = myPostsPage.items;
        }
        final userId = AuthService().currentUser?.userId.toLowerCase();
        _loadedSpaceReviews = userId == null || userId.isEmpty
            ? []
            : collectedReviews
                .where((review) => review.customerUserId.toLowerCase() == userId)
                .toList();
      });
    } catch (e) {
      debugPrint('Không thể tải thông tin hồ sơ: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải đầy đủ thông tin hồ sơ.')),
      );
    }
  }

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
        const SnackBar(
          content: Text('Đã cập nhật ảnh đại diện mới từ thiết bị!'),
          backgroundColor: Colors.green,
        ),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 24),

              _buildInputLabel('Họ và tên'),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập họ tên',
                  filled: true,
                  fillColor: context.inputColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
                    const SnackBar(
                      content: Text('Đã cập nhật thông tin thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Lưu Thay Đổi',
                  style: TextStyle(
                    color: context.cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: context.textColor,
        ),
      ),
    );
  }

  void _showBookingHistoryModal() async {
    List<BookingResponseDTO> apiBookings = List.from(_loadedBookings);
    final role = (AuthService().currentUser?.role ?? '').toUpperCase();
    if (!role.contains('EXPERT') && !role.contains('PROVIDER')) {
      final page = await BookingApiService().getMyBookings(page: 1, pageSize: 50);
      if (!mounted) return;
      if (page == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải lịch sử đặt chỗ.')),
        );
        return;
      }
      if (page.items.isNotEmpty || apiBookings.isNotEmpty) {
        apiBookings = page.items;
        if (mounted) {
          setState(() {
            _loadedBookings = page.items;
            _totalBookingsCount =
                page.totalCount > 0 ? page.totalCount : page.items.length;
          });
        }
      }
    }

    if (!mounted) return;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Lịch Sử Đặt Phòng & Thiết Bị',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const ScheduleScreen(),
                      ),
                    ).then((_) => _loadProfileApiStats());
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: apiBookings.isNotEmpty
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: apiBookings.length,
                      itemBuilder: (context, index) {
                        final b = apiBookings[index];
                        final priceFormatted =
                            '${b.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) => const ScheduleScreen(),
                              ),
                            ).then((_) => _loadProfileApiStats());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              border: Border.all(color: context.borderColor),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.spaceName.isNotEmpty
                                            ? b.spaceName
                                            : 'Đơn đặt chỗ #${b.bookingId.substring(0, 6)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: context.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${b.bookingDate} • ${b.startTime} - ${b.endTime}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.textSecColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      priceFormatted,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      b.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: b.status.toUpperCase() ==
                                                'CONFIRMED'
                                            ? Colors.green
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: context.textSecColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('Chưa có lịch sử đặt chỗ.')),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyPostsModal() async {
    final myPostsPage =
        await CommunityPostApiService().getMyPosts(page: 1, pageSize: 50);
    if (!mounted) return;
    if (myPostsPage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải bài đăng của bạn.')),
      );
      return;
    }
    setState(() => _loadedMyCommunityPosts = myPostsPage.items);

    final int totalCount = _loadedMyCommunityPosts.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Bài Đăng Cộng Đồng ($totalCount)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityScreen(initialViewMode: 1),
                      ),
                    ).then((_) => _loadProfileApiStats());
                  },
                  child: const Text(
                    'Mở Diễn đàn',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: totalCount > 0
                  ? ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ..._loadedMyCommunityPosts.map(
                          (post) => InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CommunityScreen(initialViewMode: 1),
                                ),
                              ).then((_) => _loadProfileApiStats());
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                border: Border.all(color: context.borderColor),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: context.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${post.category ?? 'Cộng đồng Film'} • ${post.likeCount} thích • ${post.commentCount} bình luận',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: context.textSecColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: Text('Chưa có bài đăng cộng đồng.')),
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
        height: MediaQuery.of(context).size.height * 0.65,
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
              'Đánh Giá Không Gian (${_loadedSpaceReviews.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
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
                    child: Text(
                      _loadedSpaceReviews.isEmpty
                          ? '—'
                          : (_loadedSpaceReviews
                                      .map((review) => review.rating)
                                      .reduce((a, b) => a + b) /
                                  _loadedSpaceReviews.length)
                              .toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Chỉ hiển thị đánh giá của bạn trong các không gian đã tải, không phải toàn bộ lịch sử.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loadedSpaceReviews.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _loadedSpaceReviews.length,
                  itemBuilder: (context, index) {
                    final r = _loadedSpaceReviews[index];
                    final spaceItem =
                        _loadedSpacesById[r.spaceId.toLowerCase()];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (spaceItem == null) return;
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          this.context,
                          '/detail',
                          arguments: spaceItem,
                        ).then((_) => _loadProfileApiStats());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          spaceItem?.name ?? r.customerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: context.textColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${r.rating} ⭐ • ${r.spaceType}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (r.comment != null &&
                                      r.comment!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      r.comment!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.textSecColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (spaceItem != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: context.textSecColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSavedListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return ValueListenableBuilder<List<BookingItem>>(
            valueListenable: FavoriteService().favorites,
            builder: (context, favoriteItems, _) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.78,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Studio & Phòng Tối Đã Lưu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${favoriteItems.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: favoriteItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      color: context.inputColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.borderColor),
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border_rounded,
                                      size: 40,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có Studio nào được lưu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nhấn vào biểu tượng ♡ trên bất kỳ Studio hoặc Phòng Tối nào để lưu lại.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: favoriteItems.length,
                              itemBuilder: (context, index) {
                                final item = favoriteItems[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: context.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Thumbnail
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                        ),
                                        child: SafeNetworkImage(
                                          url: item.imageUrl,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Category badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: item.category ==
                                                          BookingCategory.darkroom
                                                      ? const Color(0xFF1A237E)
                                                          .withValues(alpha: 0.1)
                                                      : AppColors.primarySoft,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.category ==
                                                          BookingCategory.darkroom
                                                      ? '🎞️ Phòng Tối'
                                                      : '📸 Studio',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: item.category ==
                                                            BookingCategory.darkroom
                                                        ? const Color(0xFF3949AB)
                                                        : AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: context.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 12,
                                                    color: context.textSecColor,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      item.location,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: context.textSecColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star_rounded,
                                                      color: Colors.amber, size: 13),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    item.ratingLabel,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: context.textColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${(item.pricePerHour / 1000).toStringAsFixed(0)}k/h',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Remove button
                                      Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: GestureDetector(
                                          onTap: () {
                                            FavoriteService().remove(item.id);
                                            // ValueListenableBuilder tự rebuild
                                          },
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.favorite_rounded,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    if (favoriteItems.isNotEmpty) ...[  
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Xóa tất cả
                            for (final item in List.from(favoriteItems)) {
                              FavoriteService().remove(item.id);
                            }
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: const Text('Xóa tất cả danh sách đã lưu'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(0, 46),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
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
                        title: Text(
                          'Thông báo ứng dụng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Nhận thông báo lịch đặt & bài viết',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: true,
                        activeThumbColor: context.cardColor,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {},
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Text(
                          'Giao diện tối (Dark Mode)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Đổi giao diện sang nền đen',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: isDark,
                        activeThumbColor: context.cardColor,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          themeNotifier.value = val
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text(
                          'Đổi mật khẩu bảo mật',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: const Text(
                          'Kiểm tra cập nhật ứng dụng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Phiên bản hiện tại: v${AppUpdateService.currentAppVersion}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.system_update_rounded, color: AppColors.primary),
                        onTap: () {
                          final rootCtx = this.context;
                          Navigator.pop(context);
                          AppUpdateService().checkAndPromptUpdate(rootCtx, force: true);
                        },
                      ),
                    ],
                  ),
                );
              },
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
      appBar: AppBar(title: Text('Trang Cá Nhân')),
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
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: context.inputColor,
                            backgroundImage: (_avatarUrl.startsWith('http://') ||
                                    _avatarUrl.startsWith('https://'))
                                ? NetworkImage(_avatarUrl) as ImageProvider
                                : FileImage(
                                    File(
                                      _avatarUrl.startsWith('file://')
                                          ? Uri.parse(_avatarUrl).toFilePath()
                                          : _avatarUrl,
                                    ),
                                  ),
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
                                border: Border.all(
                                  color: context.cardColor,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: context.cardColor,
                              ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel,
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
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecColor,
                          height: 1.4,
                        ),
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
                          if (!_isExpertRole) ...[
                            _StatItem(
                              value: '$_totalBookingsCount',
                              label: 'Lịch đặt',
                              onTap: _showBookingHistoryModal,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: context.borderColor,
                            ),
                            _StatItem(
                              value: '$_totalSubscriptionsCount',
                              label: 'Gói đã mua',
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/service-packages',
                              ).then((_) => _loadProfileApiStats()),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: context.borderColor,
                            ),
                          ],
                          _StatItem(
                            value: '${_loadedMyCommunityPosts.length}',
                            label: 'Bài đăng',
                            onTap: _showMyPostsModal,
                          ),
                          if (!_isExpertRole) ...[
                            Container(
                              width: 1,
                              height: 32,
                              color: context.borderColor,
                            ),
                            _StatItem(
                              value: _loadedSpaceReviews.isEmpty
                                  ? '0'
                                  : (_loadedSpaceReviews
                                              .map((r) => r.rating)
                                              .reduce((a, b) => a + b) /
                                          _loadedSpaceReviews.length)
                                      .toStringAsFixed(1),
                              label: 'Đánh giá',
                              isStar: true,
                              onTap: _showMyReviewsModal,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Become an Expert / Expert Workspace CTA
              ValueListenableBuilder<ExpertApplicationStatus>(
                valueListenable: ExpertApplicationState.instance.status,
                builder: (context, status, child) {
                  final isApproved =
                      _isExpertRole || status == ExpertApplicationStatus.approved;

                  final isPending =
                      !_isExpertRole && status == ExpertApplicationStatus.pending;

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
                            Navigator.pushNamed(context, '/expert-workspace');
                          } else if (!isPending) {
                            Navigator.pushNamed(context, '/expert-application');
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
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
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
              ),

              // Sleek Modern Settings List Card
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                  child: Text(
                    'Tùy Chọn & Cài Đặt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
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
                    if (!_isExpertRole) ...[
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: context.inputColor,
                      ),
                      _ProfileTile(
                        icon: Icons.history_rounded,
                        title: 'Lịch sử đặt phòng & thiết bị',
                        onTap: _showBookingHistoryModal,
                      ),
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: context.inputColor,
                      ),
                      _ProfileTile(
                        icon: Icons.card_membership_rounded,
                        title: 'Gói dịch vụ & Subscription của tôi',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/service-packages',
                        ).then((_) => _loadProfileApiStats()),
                      ),
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: context.inputColor,
                      ),
                      _ProfileTile(
                        icon: Icons.favorite_border_rounded,
                        title: 'Danh sách Studio đã lưu',
                        onTap: _showSavedListModal,
                      ),
                    ],
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: context.inputColor,
                    ),
                    _ProfileTile(
                      icon: Icons.history_rounded,
                      title: 'Lịch sử bài đăng',
                      onTap: _showMyPostsModal,
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: context.inputColor,
                    ),
                    _ProfileTile(
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt ứng dụng',
                      onTap: _showAccountSettingsModal,
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: context.inputColor,
                    ),

                    // Logout Tile at the bottom of settings list
                    _ProfileTile(
                      icon: Icons.logout_rounded,
                      title: 'Đăng xuất tài khoản',
                      isDestructive: true,
                      onTap: () {
                        AuthService().logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
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
          color: isDestructive
              ? Colors.red.shade50
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : context.textColor,
        ),
      ),
      trailing: isDestructive
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 24,
            ),
      onTap: onTap,
    );
  }
}
