import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../models/review_api_models.dart';
import '../services/booking_api_service.dart';
import '../services/review_api_service.dart';
import '../widgets/item_detail_bottom_bar.dart';
import '../widgets/item_detail_rentals_section.dart';
import '../widgets/item_detail_reviews_section.dart';
import '../widgets/item_detail_sliver_app_bar.dart';
import '../widgets/item_detail_specs_section.dart';
import '../widgets/item_detail_write_review_sheet.dart';
import 'booking_flow_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late BookingItem _item;
  bool _isInitialized = false;
  int _currentImageIndex = 0;

  final ReviewApiService _reviewApiService = ReviewApiService();
  final BookingApiService _bookingApiService = BookingApiService();

  SpaceReviewPageResponseDTO? _reviewPage;
  List<SpaceReviewResponseDTO> _apiReviews = [];
  List<BookingResponseDTO> _mySpaceBookings = [];
  List<PhotographerEquipmentResponseDTO> _spaceEquipment = [];
  List<DarkroomChemicalResponseDTO> _darkroomChemicals = [];
  bool _isLoadingReviews = false;
  bool _reviewsError = false;

  bool get _hasCurrentUserReviewed {
    final currentUserId =
        AuthService().currentUser?.userId.trim().toLowerCase() ?? '';
    if (currentUserId.isEmpty) return false;
    return _apiReviews.any(
      (r) => r.customerUserId.trim().toLowerCase() == currentUserId,
    );
  }

  String get _resolvedSpaceType {
    if (_item.category == BookingCategory.equipment) {
      return (_item.parentSpaceType?.toUpperCase() == 'DARKROOM')
          ? 'DARKROOM'
          : 'STUDIO';
    }
    return _item.category == BookingCategory.darkroom ? 'DARKROOM' : 'STUDIO';
  }

  String get _resolvedSpaceId {
    if (_item.category == BookingCategory.equipment) {
      return (_item.parentSpaceId ?? '').trim();
    }
    return _item.id.trim();
  }

  List<Map<String, dynamic>> get _reviews {
    return _apiReviews
        .map((r) => <String, dynamic>{
              'name': r.customerName.isNotEmpty
                  ? r.customerName
                  : 'Nhiếp ảnh gia',
              'avatar':
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80',
              'rating': r.rating.toDouble(),
              'date': SpaceReviewResponseDTO.formatTimeAgo(r.createdAt),
              'comment': (r.comment != null && r.comment!.trim().isNotEmpty)
                  ? r.comment!.trim()
                  : '',
              'isApi': true,
            })
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BookingItem) {
        _item = args;
        _isInitialized = true;
        _loadSpaceReviewsAndBookings();
      }
    }
  }

  /// Gọi GET /api/photographer/studios/{studioId}/reviews
  /// hoặc GET /api/photographer/darkrooms/{darkroomId}/reviews
  Future<void> _loadSpaceReviewsAndBookings() async {
    final spaceId = _resolvedSpaceId;
    if (spaceId.length < 32) return;

    setState(() => _isLoadingReviews = true);
    try {
      final Future<SpaceReviewPageResponseDTO?> reviewFuture =
          _resolvedSpaceType == 'DARKROOM'
              ? _reviewApiService.getDarkroomReviews(
                  darkroomId: spaceId,
                  page: 1,
                  pageSize: 100,
                )
              : _reviewApiService.getStudioReviews(
                  studioId: spaceId,
                  page: 1,
                  pageSize: 100,
                );

      final Future<List<DarkroomChemicalResponseDTO>> chemicalsFuture =
          _resolvedSpaceType == 'DARKROOM'
              ? _bookingApiService.getDarkroomChemicals(spaceId)
              : Future.value(<DarkroomChemicalResponseDTO>[]);

      final results = await Future.wait([
        reviewFuture,
        _bookingApiService.getMyBookings(page: 1, pageSize: 50),
        _bookingApiService.getEquipmentForSpace(
          spaceId: spaceId,
          page: 1,
          pageSize: 20,
        ),
        chemicalsFuture,
      ]);

      if (!mounted) return;

      final page = results[0] as SpaceReviewPageResponseDTO?;
      final bookingsPage = results[1] as PagedResponseDTO<BookingResponseDTO>?;
      final equipPage =
          results[2] as PagedResponseDTO<PhotographerEquipmentResponseDTO>?;
      final chemicals = results[3] as List<DarkroomChemicalResponseDTO>;

      final matchingBookings = (bookingsPage?.items ?? [])
          .where((b) =>
              b.spaceId.toLowerCase() == spaceId.toLowerCase() &&
              (b.status.toUpperCase() == 'CONFIRMED' ||
                  b.status.toUpperCase() == 'COMPLETED'))
          .toList();

      setState(() {
        _reviewPage = page;
        _reviewsError = page == null;
        _apiReviews = page?.items ?? [];
        _mySpaceBookings = matchingBookings;
        _spaceEquipment = equipPage?.items ?? [];
        _darkroomChemicals = chemicals;
        if (page != null && page.totalReviews > 0 && page.averageRating > 0) {
          _bookingApiService.updateCachedSpaceRating(
            spaceId,
            page.averageRating,
            reviewCount: page.totalReviews,
          );
          _item = _item.copyWith(
            rating: page.averageRating,
            reviewCount: page.totalReviews,
          );
        }
        _isLoadingReviews = false;
      });
    } catch (e) {
      debugPrint('Không thể tải đánh giá: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
        _reviewsError = true;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final spaceId = _resolvedSpaceId;
    if (spaceId.length < 32) return;

    Future<void> refreshSpaceInfo() async {
      try {
        if (_item.category == BookingCategory.studio) {
          final studios = await _bookingApiService.getStudios();
          final matched = studios.where(
            (s) => s.resourceId.toLowerCase() == spaceId.toLowerCase(),
          );
          if (matched.isNotEmpty && mounted) {
            final updated = matched.first.toBookingItem();
            updated.isFavorite = FavoriteService().isFavorite(updated.id);
            setState(() {
              _item = updated.copyWith(
                rating: _item.rating,
                reviewCount: _item.reviewCount,
              );
            });
          }
        } else if (_item.category == BookingCategory.darkroom) {
          final darkrooms = await _bookingApiService.getDarkrooms();
          final matched = darkrooms.where(
            (d) => d.resourceId.toLowerCase() == spaceId.toLowerCase(),
          );
          if (matched.isNotEmpty && mounted) {
            final updated = matched.first.toBookingItem();
            updated.isFavorite = FavoriteService().isFavorite(updated.id);
            setState(() {
              _item = updated.copyWith(
                rating: _item.rating,
                reviewCount: _item.reviewCount,
              );
            });
          }
        }
      } catch (e) {
        debugPrint('Không thể làm mới thông tin không gian: $e');
      }
    }

    await Future.wait([
      refreshSpaceInfo(),
      _loadSpaceReviewsAndBookings(),
    ]);
  }

  void _showBookingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingFlowScreen(item: _item)),
    );
  }

  /// POST /api/photographer/bookings/{bookingId}/review
  /// Tự động kiểm tra khách hàng đã có đơn đặt chỗ CONFIRMED (hoặc COMPLETED) tại không gian này chưa
  /// mà không bắt khách hàng phải tự chọn đơn đặt chỗ.
  Future<void> _showWriteReviewModal(BuildContext context) async {
    if (_hasCurrentUserReviewed) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flatColored,
        title: const Text('Bạn đã đánh giá rồi'),
        description: Text(
          'Mỗi tài khoản chỉ được gửi 1 đánh giá cho "${_item.name}".',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
      );
      return;
    }

    final BookingResponseDTO? confirmedBooking =
        _mySpaceBookings.isNotEmpty ? _mySpaceBookings.first : null;

    if (confirmedBooking == null && _resolvedSpaceId.length >= 32) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text('Chưa đủ điều kiện đánh giá'),
        description: Text(
          'Bạn cần có đơn đặt chỗ hợp lệ tại "${_item.name}" để gửi đánh giá. '
          'Đơn phải được thanh toán hoặc sử dụng lượt gói, lịch đã kết thúc và chưa được đánh giá.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
      );
      return;
    }

    final submitted = await showItemDetailWriteReviewSheet(
      context: context,
      itemName: _item.name,
      resolvedSpaceType: _resolvedSpaceType,
      resolvedSpaceId: _resolvedSpaceId,
      confirmedBooking: confirmedBooking,
      reviewApiService: _reviewApiService,
    );

    if (submitted == true && mounted) {
      await _loadSpaceReviewsAndBookings();
      if (!mounted) return;
      toastification.show(
        context: this.context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Cảm ơn bạn!'),
        description: const Text(
          'Đánh giá của bạn đã được lưu lên hệ thống.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        icon: const Icon(Icons.star_rounded),
        showProgressBar: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(title: const Text('Chi tiết')),
        body: const Center(
          child: Text('Không tìm thấy thông tin dịch vụ.'),
        ),
      );
    }

    final List<String> allImages = [_item.imageUrl, ..._item.previewImages];
    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Scaffold(
      backgroundColor: context.bgColor,
      extendBody: true,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: context.cardColor,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            ItemDetailSliverAppBar(
              item: _item,
              allImages: allImages,
              currentImageIndex: _currentImageIndex,
              onImageIndexChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              onFavoriteToggled: (nowFav) {
                setState(() => _item.isFavorite = nowFav);
              },
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: context.bgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                transform: Matrix4.translationValues(0, -28, 0),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 124 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ItemDetailSpecsSection(item: _item),
                      ItemDetailRentalsSection(
                        resolvedSpaceType: _resolvedSpaceType,
                        spaceEquipment: _spaceEquipment,
                        darkroomChemicals: _darkroomChemicals,
                      ),
                      ItemDetailReviewsSection(
                        description: _item.description,
                        usagePolicies: _item.usagePolicies,
                        reviewPage: _reviewPage,
                        reviews: _reviews,
                        isLoadingReviews: _isLoadingReviews,
                        reviewsError: _reviewsError,
                        hasCurrentUserReviewed: _hasCurrentUserReviewed,
                        onWriteReviewTap: () => _showWriteReviewModal(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ItemDetailBottomBar(
        pricePerHour: _item.pricePerHour,
        onBookPressed: _showBookingDialog,
      ),
    );
  }
}
