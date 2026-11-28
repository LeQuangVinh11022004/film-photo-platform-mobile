import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';

class StudioComparisonScreen extends StatefulWidget {
  const StudioComparisonScreen({super.key});

  @override
  State<StudioComparisonScreen> createState() => _StudioComparisonScreenState();
}

class _StudioComparisonScreenState extends State<StudioComparisonScreen> {
  final BookingApiService _bookingApiService = BookingApiService();

  /// 0 = So sánh 2 Studio, 1 = So sánh 2 Phòng Tối (Darkroom)
  int _selectedSpaceTab = 0;

  List<BookingItem> _studios = [];
  List<BookingItem> _darkrooms = [];

  BookingItem? _studio1;
  BookingItem? _studio2;
  BookingItem? _darkroom1;
  BookingItem? _darkroom2;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveSpaces();
  }

  Future<void> _loadLiveSpaces() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<List<ResourceItemResponseDTO>>([
        _bookingApiService.getStudios(),
        _bookingApiService.getDarkrooms(),
      ]);
      if (!mounted) return;
      final rawStudios = results[0].map((e) => e.toBookingItem()).toList();
      final rawDarkrooms = results[1].map((e) => e.toBookingItem()).toList();
      final enriched = await Future.wait([
        _bookingApiService.enrichSpaceRatings(rawStudios),
        _bookingApiService.enrichSpaceRatings(rawDarkrooms),
      ]);
      if (!mounted) return;
      final studios = enriched[0];
      final darkrooms = enriched[1];

      setState(() {
        _studios = studios;
        _darkrooms = darkrooms;
        _studio1 = studios.isNotEmpty ? studios[0] : null;
        _studio2 = studios.length > 1 ? studios[1] : _studio1;
        _darkroom1 = darkrooms.isNotEmpty ? darkrooms[0] : null;
        _darkroom2 = darkrooms.length > 1 ? darkrooms[1] : _darkroom1;

        // Nếu Studio < 2 nhưng Darkroom >= 2 thì tự chuyển sang tab Phòng Tối
        if (studios.length < 2 && darkrooms.length >= 2) {
          _selectedSpaceTab = 1;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<BookingItem> get _currentList =>
      _selectedSpaceTab == 0 ? _studios : _darkrooms;

  BookingItem? get _currentItem1 =>
      _selectedSpaceTab == 0 ? _studio1 : _darkroom1;

  BookingItem? get _currentItem2 =>
      _selectedSpaceTab == 0 ? _studio2 : _darkroom2;

  String get _currentSpaceLabel =>
      _selectedSpaceTab == 0 ? 'Studio' : 'Phòng Tối';

  String _formatDimensions(BookingItem item) {
    if (item.lengthM > 0 && item.widthM > 0) {
      final area = (item.lengthM * item.widthM).toStringAsFixed(0);
      final heightPart = item.heightM > 0 ? ' × ${item.heightM}m' : '';
      return '${item.lengthM}m × ${item.widthM}m$heightPart (~${area}m²)';
    }
    return 'Đang cập nhật';
  }

  String _formatPrice(double price) {
    final formatted = price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formattedđ / giờ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('So Sánh Không Gian'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  // Thanh chọn loại không gian: chỉ so sánh Studio vs Studio hoặc Phòng Tối vs Phòng Tối
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSpaceTab = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: _selectedSpaceTab == 0
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 16,
                                      color: _selectedSpaceTab == 0
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Studio (${_studios.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _selectedSpaceTab == 0
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSpaceTab = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: _selectedSpaceTab == 1
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wb_twilight_rounded,
                                      size: 16,
                                      color: _selectedSpaceTab == 1
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Phòng Tối (${_darkrooms.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _selectedSpaceTab == 1
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: _buildComparisonBody(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComparisonBody() {
    final list = _currentList;
    final item1 = _currentItem1;
    final item2 = _currentItem2;

    if (list.length < 2 || item1 == null || item2 == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedSpaceTab == 0
                    ? Icons.camera_alt_outlined
                    : Icons.wb_twilight_rounded,
                size: 56,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 14),
              Text(
                'Cần ít nhất 2 $_currentSpaceLabel để so sánh cùng loại',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hiện có ${list.length} $_currentSpaceLabel khả dụng.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadLiveSpaces,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại dữ liệu'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So Sánh Trực Quan 2 $_currentSpaceLabel',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedSpaceTab == 0
                ? 'Đối chiếu mức giá, diện tích, ánh sáng & phong cách giữa 2 Studio'
                : 'Đối chiếu mức giá, quy trình tráng rọi, thông gió & tiện ích giữa 2 Phòng Tối',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Item Pickers Row (cùng loại Studio hoặc cùng loại Darkroom)
          Row(
            children: [
              Expanded(child: _buildItemPicker(1, item1, list)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildItemPicker(2, item2, list)),
            ],
          ),
          const SizedBox(height: 24),

          // Specs Comparison Table Card
          Container(
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
              children: [
                _buildCompHeader(),
                _buildCompRow(
                  'Đơn giá thuê',
                  _formatPrice(item1.pricePerHour),
                  _formatPrice(item2.pricePerHour),
                ),
                _buildCompRow(
                  'Đánh giá ⭐',
                  item1.ratingLabel,
                  item2.ratingLabel,
                ),
                _buildCompRow('Vị trí', item1.location, item2.location),
                _buildCompRow(
                  'Sức chứa',
                  'Tối đa ${item1.capacity} người',
                  'Tối đa ${item2.capacity} người',
                ),
                if (_selectedSpaceTab == 0) ...[
                  _buildCompRow(
                    'Kích thước',
                    _formatDimensions(item1),
                    _formatDimensions(item2),
                  ),
                  _buildCompRow(
                    'Phong cách',
                    item1.artisticStyle.isNotEmpty
                        ? item1.artisticStyle
                        : 'Tiêu chuẩn Film',
                    item2.artisticStyle.isNotEmpty
                        ? item2.artisticStyle
                        : 'Tiêu chuẩn Film',
                  ),
                  _buildCompRow(
                    'Ánh sáng',
                    item1.lightingConditions.isNotEmpty
                        ? item1.lightingConditions
                        : 'Đang cập nhật',
                    item2.lightingConditions.isNotEmpty
                        ? item2.lightingConditions
                        : 'Đang cập nhật',
                  ),
                ] else ...[
                  _buildCompRow(
                    'Quy trình tráng',
                    item1.supportedProcesses.isNotEmpty
                        ? item1.supportedProcesses
                        : 'B&W / C-41',
                    item2.supportedProcesses.isNotEmpty
                        ? item2.supportedProcesses
                        : 'B&W / C-41',
                  ),
                  _buildCompRow(
                    'Thông gió',
                    item1.ventilationDetails.isNotEmpty
                        ? item1.ventilationDetails
                        : 'Tiêu chuẩn phòng tối',
                    item2.ventilationDetails.isNotEmpty
                        ? item2.ventilationDetails
                        : 'Tiêu chuẩn phòng tối',
                  ),
                ],
                _buildCompRow(
                  'Giờ hoạt động',
                  item1.operatingHours.isNotEmpty
                      ? item1.operatingHours
                      : 'Theo lịch mở',
                  item2.operatingHours.isNotEmpty
                      ? item2.operatingHours
                      : 'Theo lịch mở',
                ),
                _buildCompRow(
                  'Số tiện ích',
                  '${item1.amenities.length} trang bị',
                  '${item2.amenities.length} trang bị',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Booking Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/detail', arguments: item1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đặt $_currentSpaceLabel 1',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/detail', arguments: item2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đặt $_currentSpaceLabel 2',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemPicker(int slot, BookingItem selected, List<BookingItem> options) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          SafeNetworkImage(
            url: selected.imageUrl,
            height: 90,
            width: double.infinity,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          Text(
            selected.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButton<BookingItem>(
            value: selected,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            items: options.map((item) {
              return DropdownMenuItem<BookingItem>(
                value: item,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                if (_selectedSpaceTab == 0) {
                  if (slot == 1) {
                    _studio1 = val;
                  } else {
                    _studio2 = val;
                  }
                } else {
                  if (slot == 1) {
                    _darkroom1 = val;
                  } else {
                    _darkroom2 = val;
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 90,
            child: Text(
              'Tiêu chí',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$_currentSpaceLabel 1',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$_currentSpaceLabel 2',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompRow(String label, String val1, String val2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
