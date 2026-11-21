import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_item.dart';
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

  // Booking Modal State
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedTimeSlotIndex = 0;
  final List<Map<String, dynamic>> _timeSlots = [
  {'slot': '08:00 - 10:00', 'hours': 2},
  {'slot': '10:00 - 12:00', 'hours': 2},
  {'slot': '13:00 - 16:00', 'hours': 3},
  {'slot': '16:00 - 19:00', 'hours': 3},
  {'slot': '19:00 - 22:00', 'hours': 3},
  ];

  final List<Map<String, dynamic>> _reviews = [
  {
  'name': 'Nguyễn Văn Minh',
  'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80',
  'rating': 5.0,
  'date': '2 ngày trước',
  'comment': 'Studio trang bị ánh sáng cực đỉnh! Đèn Profoto hoạt động rất ổn định, phông nền film vintage chụp portrait lên màu rất mịn. Rất đáng tiền!',
  },
  {
  'name': 'Trần Thị Thu Hà',
  'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80',
  'rating': 5.0,
  'date': '1 tuần trước',
  'comment': 'Không gian sạch sẽ, yên tĩnh, chủ studio thân thiện và nhiệt tình hỗ trợ kê đặt thiết bị. Chắc chắn sẽ quay lại đặt thường xuyên!',
  },
  {
  'name': 'Lê Quốc Bảo',
  'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
  'rating': 4.8,
  'date': '2 tuần trước',
  'comment': 'Thiết bị rất mới, có sẵn nước uống và wifi nhanh. Trải nghiệm tuyệt vời cho nhiếp ảnh gia tự do.',
  },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BookingItem) {
        _item = args;
      } else {
        _item = BookingItem.sampleItems[0];
      }
      _isInitialized = true;
    }
  }

  void _showBookingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingFlowScreen(item: _item)),
    );
  }

  void _showWriteReviewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
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
              'Viết đánh giá của bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (index) => IconButton(
                  icon: const Icon(Icons.star_border_rounded, size: 40, color: Colors.amber),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn tại đây...',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                toastification.show(
                  context: context,
                  type: ToastificationType.success,
                  style: ToastificationStyle.flatColored,
                  title: const Text('Cảm ơn bạn!'),
                  description: const Text('Đánh giá của bạn đã được gửi thành công.'),
                  alignment: Alignment.topCenter,
                  autoCloseDuration: const Duration(seconds: 4),
                  icon: const Icon(Icons.star_rounded),
                  showProgressBar: false,
                );
              },
              child: const Text('Gửi đánh giá'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: Icon(
                      _item.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _item.isFavorite ? Colors.red : context.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _item.isFavorite = !_item.isFavorite;
                      });
                      if (_item.isFavorite) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.info,
                          style: ToastificationStyle.flatColored,
                          title: const Text('Đã lưu'),
                          description: const Text('Đã thêm vào danh sách yêu thích.'),
                          alignment: Alignment.bottomCenter,
                          autoCloseDuration: const Duration(seconds: 2),
                          showProgressBar: false,
                        );
                      }
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
                                '${_item.rating}',
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
                            'Đánh giá & Nhận xét',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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