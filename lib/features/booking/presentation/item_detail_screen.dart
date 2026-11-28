import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../models/review_api_models.dart';
import '../services/booking_api_service.dart';
import '../services/review_api_service.dart';
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
    final apiMapped = _apiReviews
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
    return apiMapped;
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

      final results = await Future.wait([
        reviewFuture,
        _bookingApiService.getMyBookings(page: 1, pageSize: 50),
        _bookingApiService.getEquipmentForSpace(
          spaceId: spaceId,
          page: 1,
          pageSize: 20,
        ),
      ]);

      if (!mounted) return;

      final page = results[0] as SpaceReviewPageResponseDTO?;
      final bookingsPage = results[1] as PagedResponseDTO<BookingResponseDTO>?;
      final equipPage =
          results[2] as PagedResponseDTO<PhotographerEquipmentResponseDTO>?;

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
        if (page != null && page.totalReviews > 0 && page.averageRating > 0) {
          _item = BookingItem(
            id: _item.id,
            name: _item.name,
            category: _item.category,
            location: _item.location,
            pricePerHour: _item.pricePerHour,
            rating: page.averageRating,
            imageUrl: _item.imageUrl,
            description: _item.description,
            amenities: _item.amenities,
            previewImages: _item.previewImages,
            isFavorite: _item.isFavorite,
            capacity: _item.capacity,
            providerName: _item.providerName,
            lengthM: _item.lengthM,
            widthM: _item.widthM,
            heightM: _item.heightM,
            artisticStyle: _item.artisticStyle,
            supportedProcesses: _item.supportedProcesses,
            lightingConditions: _item.lightingConditions,
            ventilationDetails: _item.ventilationDetails,
            acousticDetails: _item.acousticDetails,
            operatingHours: _item.operatingHours,
            usagePolicies: _item.usagePolicies,
            availableSlots: _item.availableSlots,
            parentSpaceId: _item.parentSpaceId,
            parentSpaceType: _item.parentSpaceType,
            parentSpaceName: _item.parentSpaceName,
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

  void _showBookingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingFlowScreen(item: _item)),
    );
  }

  /// POST /api/photographer/bookings/{bookingId}/review
  /// Tự động kiểm tra khách hàng đã có đơn đặt chỗ CONFIRMED (hoặc COMPLETED) tại không gian này chưa
  /// mà không bắt khách hàng phải tự chọn đơn đặt chỗ.
  void _showWriteReviewModal(BuildContext context) {
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

    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
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
                const SizedBox(height: 20),
                Text(
                  'Đánh Giá ${_item.name}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đơn cần được thanh toán hoặc dùng lượt gói, lịch đã kết thúc và chưa được đánh giá.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 40,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() => selectedRating = starValue);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ trải nghiệm thực tế của bạn tại đây...',
                    filled: true,
                    fillColor: context.inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final comment = commentController.text.trim();
                            if (confirmedBooking != null &&
                                _resolvedSpaceId.length >= 32) {
                              setModalState(() => isSubmitting = true);
                              final res = await _reviewApiService
                                  .createBookingReview(
                                bookingId: confirmedBooking.bookingId,
                                request: SpaceReviewWriteRequestDTO(
                                  spaceType: _resolvedSpaceType,
                                  spaceId: _resolvedSpaceId,
                                  rating: selectedRating,
                                  comment: comment,
                                ),
                              );
                              if (!modalCtx.mounted) return;
                              setModalState(() => isSubmitting = false);

                              if (res['success'] == true) {
                                Navigator.pop(modalCtx);
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
                                  autoCloseDuration:
                                      const Duration(seconds: 4),
                                  icon: const Icon(Icons.star_rounded),
                                  showProgressBar: false,
                                );
                              } else {
                                toastification.show(
                                  context: modalCtx,
                                  type: ToastificationType.warning,
                                  style: ToastificationStyle.flatColored,
                                  title: const Text('Chưa thể gửi đánh giá'),
                                  description: Text(
                                    res['message']?.toString() ??
                                        'Vui lòng thử lại sau.',
                                  ),
                                  alignment: Alignment.topCenter,
                                  autoCloseDuration:
                                      const Duration(seconds: 4),
                                  showProgressBar: false,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Gửi Đánh Giá',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
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

    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 370,
            pinned: true,
            stretch: true,
            backgroundColor: context.bgColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardColor.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: context.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardColor.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: ValueListenableBuilder<List<BookingItem>>(
                      valueListenable: FavoriteService().favorites,
                      builder: (context, _, _) {
                        final isFav = FavoriteService().isFavorite(_item.id);
                        return Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : context.textColor,
                        );
                      },
                    ),
                    onPressed: () {
                      final nowFav = FavoriteService().toggle(_item);
                      setState(() {
                        _item.isFavorite = nowFav;
                      });
                      toastification.show(
                        context: context,
                        type: nowFav
                            ? ToastificationType.success
                            : ToastificationType.warning,
                        style: ToastificationStyle.flatColored,
                        title: Text(nowFav ? 'Đã lưu' : 'Đã bỏ lưu'),
                        description: Text(
                          nowFav
                              ? 'Đã thêm vào danh sách yêu thích.'
                              : 'Đã xóa khỏi danh sách yêu thích.',
                        ),
                        alignment: Alignment.bottomCenter,
                        autoCloseDuration: const Duration(seconds: 2),
                        showProgressBar: false,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                    items: allImages.map((img) {
                      return Hero(
                        tag: img == _item.imageUrl ? 'image_${_item.id}' : 'img_${img.hashCode}',
                        child: SafeNetworkImage(
                          url: img,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
                  // Bottom gradient for indicator legibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 96,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pagination dots positioned clear of the overlapping sheet curve
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: allImages.asMap().entries.map((entry) {
                        final bool isActive = _currentImageIndex == entry.key;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isActive ? 24.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.65),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -28, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 124),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.textColor,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _item.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_item.providerName.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _item.providerName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textColor,
                                    height: 1.35,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${_item.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '/ giờ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),

                    const SizedBox(height: 18),

                    // Rating & Capacity Row (Provider moved below location)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _item.ratingLabel,
                                style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 17, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Tối đa ${_item.capacity} người',
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.textSecColor),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),

                    const SizedBox(height: 28),

                    // Technical Specifications Grid
                    if (_item.lengthM > 0 || _item.operatingHours.isNotEmpty || _item.artisticStyle.isNotEmpty) ...[
                      Text(
                        'Thông số & Đặc điểm không gian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          children: [
                            if (_item.lengthM > 0 && _item.widthM > 0) ...[
                              _buildSpecRow(
                                context,
                                icon: Icons.straighten_rounded,
                                label: 'Kích thước',
                                value: '${_item.lengthM}m × ${_item.widthM}m (Trần cao ${_item.heightM}m)',
                              ),
                              const Divider(height: 22),
                            ],
                            if (_item.operatingHours.isNotEmpty) ...[
                              _buildSpecRow(
                                context,
                                icon: Icons.schedule_rounded,
                                label: 'Giờ hoạt động',
                                value: _item.operatingHours,
                              ),
                              const Divider(height: 22),
                            ],
                            if (_item.artisticStyle.isNotEmpty) ...[
                              _buildSpecRow(
                                context,
                                icon: Icons.palette_outlined,
                                label: 'Phong cách',
                                value: _item.artisticStyle,
                              ),
                              if (_item.supportedProcesses.isNotEmpty || _item.lightingConditions.isNotEmpty)
                                const Divider(height: 22),
                            ],
                            if (_item.supportedProcesses.isNotEmpty) ...[
                              _buildSpecRow(
                                context,
                                icon: Icons.science_outlined,
                                label: 'Quy trình tráng rọi',
                                value: _item.supportedProcesses,
                              ),
                              if (_item.lightingConditions.isNotEmpty) const Divider(height: 22),
                            ],
                            if (_item.lightingConditions.isNotEmpty) ...[
                              _buildSpecRow(
                                context,
                                icon: Icons.lightbulb_outline_rounded,
                                label: 'Ánh sáng',
                                value: _item.lightingConditions,
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
                      const SizedBox(height: 28),
                    ],

                    // Amenities / Facilities
                    Text(
                      'Tiện ích cung cấp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _item.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                amenity,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                    if (_spaceEquipment.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Thiết bị cho thuê tại không gian (${_spaceEquipment.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ).animate().fadeIn(delay: 340.ms),
                      const SizedBox(height: 12),
                      ..._spaceEquipment.map((eq) {
                        final price =
                            (eq.priceForSelectedSlot ?? eq.rentalPrice ?? 0)
                                .round();
                        final priceFormatted = price.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eq.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: context.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${eq.category}${eq.variant != null && eq.variant!.isNotEmpty ? " • ${eq.variant}" : ""} • SL: ${eq.quantityTotal}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSecColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (price > 0)
                                Text(
                                  '+$priceFormattedđ/h',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 28),

                    // Description Section
                    Text(
                      'Về Không Gian Này',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 12),
                    Text(
                      _item.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textSecColor,
                        height: 1.65,
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    // Usage Policies Section
                    if (_item.usagePolicies.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Quy định & Chính sách sử dụng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ).animate().fadeIn(delay: 550.ms),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _item.usagePolicies,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: context.textColor,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],

                    const SizedBox(height: 32),
                    Divider(color: context.borderColor),
                    const SizedBox(height: 24),

                    // Reviews Section
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _reviewPage != null && _reviewPage!.totalReviews > 0
                                ? 'Đánh giá & Nhận xét (${_reviewPage!.totalReviews})'
                                : 'Đánh giá & Nhận xét',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        if (_isLoadingReviews)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (_hasCurrentUserReviewed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đã đánh giá',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: () => _showWriteReviewModal(context),
                            icon: const Icon(Icons.edit_rounded, size: 15),
                            label: const Text(
                              'Viết đánh giá',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 14),

                    // Review List Cards
                    if (!_isLoadingReviews && _reviews.isEmpty)
                      Text(
                        _reviewsError
                            ? 'Không thể tải đánh giá.'
                            : 'Chưa có đánh giá.',
                        style: TextStyle(color: context.textSecColor),
                      ),
                    ..._reviews.map((rev) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(rev['avatar'] as String),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rev['name'] as String,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          (rev['rating'] as num).toInt(),
                                              (i) => const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          rev['date'] as String,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textSecColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rev['comment'] as String,
                            style: TextStyle(fontSize: 14, color: context.textColor, height: 1.55),
                          ),
                        ],
                      ),
                    )).toList().animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Bottom Bar for Booking
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá chỉ từ', style: TextStyle(fontSize: 12, color: context.textSecColor)),
                    const SizedBox(height: 2),
                    Text(
                      '${_item.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.textColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: PrimaryButton(
                    text: 'Đặt Ngay',
                    onPressed: _showBookingDialog,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: context.textSecColor, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}