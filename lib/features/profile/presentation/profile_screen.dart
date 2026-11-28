import 'package:flutter/material.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_colors.dart';
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
import '../widgets/profile_account_settings_sheet.dart';
import '../widgets/profile_booking_history_sheet.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/profile_expert_cta_card.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_my_posts_sheet.dart';
import '../widgets/profile_my_reviews_sheet.dart';
import '../widgets/profile_saved_list_sheet.dart';
import '../widgets/profile_settings_menu.dart';

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
  List<CommunityPostResponseDTO> _loadedMyCommunityPosts = [];
  List<SpaceReviewResponseDTO> _loadedSpaceReviews = [];
  Map<String, BookingItem> _loadedSpacesById = {};
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
          _totalBookingsCount =
              page.totalCount > 0 ? page.totalCount : page.items.length;
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

  Future<void> _showChangeAvatarModal() async {
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
    showProfileEditSheet(
      context: context,
      initialName: _name,
      initialPhone: _phone,
      initialBio: _bio,
      onSave: (name, phone, bio) {
        setState(() {
          _name = name;
          _phone = phone;
          _bio = bio;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Future<void> _showBookingHistoryModal() async {
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
        setState(() {
          _loadedBookings = page.items;
          _totalBookingsCount =
              page.totalCount > 0 ? page.totalCount : page.items.length;
        });
      }
    }

    if (!mounted) return;
    showProfileBookingHistorySheet(
      context: context,
      bookings: apiBookings,
      onOpenSchedule: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        ).then((_) {
          if (mounted) _loadProfileApiStats();
        });
      },
    );
  }

  Future<void> _showMyPostsModal() async {
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

    showProfileMyPostsSheet(
      context: context,
      posts: _loadedMyCommunityPosts,
      onOpenCommunity: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CommunityScreen(initialViewMode: 1),
          ),
        ).then((_) {
          if (mounted) _loadProfileApiStats();
        });
      },
    );
  }

  void _showMyReviewsModal() {
    showProfileMyReviewsSheet(
      context: context,
      reviews: _loadedSpaceReviews,
      spacesById: _loadedSpacesById,
      onOpenSpaceDetail: (spaceItem) {
        Navigator.pushNamed(
          context,
          '/detail',
          arguments: spaceItem,
        ).then((_) {
          if (mounted) _loadProfileApiStats();
        });
      },
    );
  }

  void _showSavedListModal() {
    showProfileSavedListSheet(
      context: context,
      onOpenItemDetail: (item) {
        Navigator.pushNamed(
          context,
          '/detail',
          arguments: item,
        );
      },
    );
  }

  void _showAccountSettingsModal() {
    showProfileAccountSettingsSheet(
      context: context,
      onOpenForgotPassword: () =>
          Navigator.pushNamed(context, '/forgot-password'),
      onCheckUpdate: () =>
          AppUpdateService().checkAndPromptUpdate(context, force: true),
    );
  }

  void _openServicePackages() {
    Navigator.pushNamed(context, '/service-packages').then((_) {
      if (mounted) _loadProfileApiStats();
    });
  }

  String get _averageReviewLabel => _loadedSpaceReviews.isEmpty
      ? '0'
      : (_loadedSpaceReviews.map((r) => r.rating).reduce((a, b) => a + b) /
              _loadedSpaceReviews.length)
          .toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(title: const Text('Trang Cá Nhân')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ProfileHeaderCard(
                avatarUrl: _avatarUrl,
                name: _name,
                email: _email,
                roleLabel: _roleLabel,
                bio: _bio,
                isExpertRole: _isExpertRole,
                totalBookingsCount: _totalBookingsCount,
                totalSubscriptionsCount: _totalSubscriptionsCount,
                totalPostsCount: _loadedMyCommunityPosts.length,
                averageReviewLabel: _averageReviewLabel,
                onChangeAvatarTap: _showChangeAvatarModal,
                onBookingsTap: _showBookingHistoryModal,
                onSubscriptionsTap: _openServicePackages,
                onPostsTap: _showMyPostsModal,
                onReviewsTap: _showMyReviewsModal,
              ),
              const SizedBox(height: 24),
              ProfileExpertCtaCard(
                isExpertRole: _isExpertRole,
                onOpenWorkspace: () =>
                    Navigator.pushNamed(context, '/expert-workspace'),
                onOpenApplication: () =>
                    Navigator.pushNamed(context, '/expert-application'),
              ),
              ProfileSettingsMenu(
                isExpertRole: _isExpertRole,
                onEditProfile: _showEditProfileModal,
                onBookingHistory: _showBookingHistoryModal,
                onServicePackages: _openServicePackages,
                onSavedList: _showSavedListModal,
                onMyPosts: _showMyPostsModal,
                onAccountSettings: _showAccountSettingsModal,
                onLogout: () {
                  AuthService().logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
