import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../models/review_api_models.dart';
import '../services/booking_api_service.dart';
import '../services/review_api_service.dart';
import 'item_detail_screen.dart';
import 'payment_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  final BookingApiService _bookingApiService = BookingApiService();
  final ReviewApiService _reviewApiService = ReviewApiService();

  /// Cho phép làm mới lịch đặt mà không cần hủy/tạo lại toàn bộ State của tab.
  Future<void> refreshBookings() => _fetchBookings();

  DateTime _currentMonth = DateTime(2026, 11, 1);
  DateTime _selectedDate = DateTime(2026, 11, 20);
  int _statusFilterIndex = 0; // 0: All, 1: Confirmed, 2: Pending/Awaiting Deposit, 3: Cancelled

  List<BookingResponseDTO> _bookings = [];
  Map<String, String> _spaceImageMap = {};
  Map<String, String> _spaceTypeMap = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCancelling = false;
  bool _hasAutoSelectedInitialDate = false;

  final List<String> _months = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _bookingApiService.getMyBookings(page: 1, pageSize: 50),
        _bookingApiService.getStudios(),
        _bookingApiService.getDarkrooms(),
      ]);
      if (!mounted) return;

      final result = results[0] as PagedResponseDTO<BookingResponseDTO>?;
      final studios = results[1] as List<ResourceItemResponseDTO>;
      final darkrooms = results[2] as List<ResourceItemResponseDTO>;

      final imgMap = <String, String>{};
      final typeMap = <String, String>{};
      for (final r in studios) {
        if (r.resourceId.isNotEmpty) {
          typeMap[r.resourceId.toLowerCase()] = 'STUDIO';
          if (r.images.isNotEmpty) {
            imgMap[r.resourceId.toLowerCase()] = r.images.first.imageUrl;
          }
        }
      }
      for (final r in darkrooms) {
        if (r.resourceId.isNotEmpty) {
          typeMap[r.resourceId.toLowerCase()] = 'DARKROOM';
          if (r.images.isNotEmpty) {
            imgMap[r.resourceId.toLowerCase()] = r.images.first.imageUrl;
          }
        }
      }

      if (result != null) {
        final loaded = result.items;
        DateTime nextSelected = _selectedDate;
        DateTime nextMonth = _currentMonth;

        if (!_hasAutoSelectedInitialDate && loaded.isNotEmpty) {
          _hasAutoSelectedInitialDate = true;
          final hasToday = loaded.any(
            (b) => _isSameDay(_parseBookingDate(b.bookingDate), _selectedDate),
          );
          if (!hasToday) {
            final parsedDates = loaded
                .map((b) => _parseBookingDate(b.bookingDate))
                .whereType<DateTime>()
                .toList()
              ..sort();
            if (parsedDates.isNotEmpty) {
              final nowDay = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );
              final upcoming = parsedDates.firstWhere(
                (d) => !d.isBefore(nowDay),
                orElse: () => parsedDates.last,
              );
              nextSelected = upcoming;
              nextMonth = DateTime(upcoming.year, upcoming.month, 1);
            }
          }
        }

        setState(() {
          _bookings = loaded;
          _spaceImageMap = imgMap;
          _spaceTypeMap = typeMap;
          _selectedDate = nextSelected;
          _currentMonth = nextMonth;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookings = [];
          _spaceImageMap = imgMap;
          _spaceTypeMap = typeMap;
          _isLoading = false;
          _errorMessage = 'Không thể tải danh sách lịch đặt.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookings = [];
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi khi tải lịch đặt.';
      });
    }
  }

  String _resolveSpaceImage(BookingResponseDTO booking) {
    final key = booking.spaceId.toLowerCase();
    final mapped = _spaceImageMap[key];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    final isDarkroom = booking.spaceName.toLowerCase().contains('darkroom') ||
        booking.spaceName.toLowerCase().contains('phòng tối');
    return isDarkroom
        ? 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80'
        : 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80';
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      final clampedDay = _selectedDate.day.clamp(1, daysInMonth);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, clampedDay);
    });
  }

  DateTime? _parseBookingDate(String rawDate) {
    final clean = rawDate.trim().split('T').first;
    final parts = clean.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<BookingResponseDTO> get _bookingsForSelectedDate {
    return _bookings.where((b) {
      final parsed = _parseBookingDate(b.bookingDate);
      return _isSameDay(parsed, _selectedDate);
    }).toList();
  }

  String _formatTimeSlot(BookingResponseDTO booking) {
    String trimSec(String t) {
      final parts = t.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return t;
    }

    final start = trimSec(booking.startTime);
    final end = trimSec(booking.endTime);

    final startParts = booking.startTime.split(':');
    final endParts = booking.endTime.split(':');
    if (startParts.length >= 2 && endParts.length >= 2) {
      final startHour = int.tryParse(startParts[0]) ?? 0;
      final startMin = int.tryParse(startParts[1]) ?? 0;
      final endHour = int.tryParse(endParts[0]) ?? 0;
      final endMin = int.tryParse(endParts[1]) ?? 0;

      final diffMinutes = (endHour * 60 + endMin) - (startHour * 60 + startMin);
      if (diffMinutes > 0) {
        final hoursStr = diffMinutes % 60 == 0
            ? '${diffMinutes ~/ 60}'
            : (diffMinutes / 60).toStringAsFixed(1);
        return '$start - $end ($hoursStr giờ)';
      }
    }
    return '$start - $end';
  }

  String _formatDateDisplay(String rawDate) {
    final dt = _parseBookingDate(rawDate);
    if (dt == null) return rawDate;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(num amount) {
    final intVal = amount.round().toString();
    final formatted = intVal.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'AWAITING_DEPOSIT':
        return 'Chờ đặt cọc';
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'COMPLETED':
        return Colors.green.shade50;
      case 'CANCELLED':
        return Colors.red.shade50;
      case 'AWAITING_DEPOSIT':
      case 'PENDING':
      default:
        return AppColors.primary.withValues(alpha: 0.12);
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      case 'AWAITING_DEPOSIT':
      case 'PENDING':
      default:
        return AppColors.primary;
    }
  }

  bool _canCancelBooking(BookingResponseDTO booking) {
    final s = booking.status.toUpperCase();
    return s == 'AWAITING_DEPOSIT' || s == 'CONFIRMED';
  }

  Future<void> _handleCancelBooking(BuildContext sheetContext, BookingResponseDTO booking) async {
    if (_isCancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch đặt?'),
        content: const Text(
          'Bạn chỉ có thể hủy trước khi bắt đầu và check-in. '
          'Tiền cọc đã thanh toán được hoàn 100% trước ít nhất 48 giờ, '
          '50% từ 24 đến dưới 48 giờ, và không hoàn dưới 24 giờ. '
          'Với đơn dùng gói, lượt sử dụng có thể được hoàn lại.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Quay lại')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận hủy')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isCancelling = true);

    final result = await _bookingApiService.cancelBooking(booking.bookingId);

    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    if (result['success'] == true) {
      final cancellation = result['cancellation'] as BookingCancellationResponseDTO;
      await _fetchBookings();
      if (!mounted) return;
      final refundMessage = cancellation.packageUseRestored
          ? ' Lượt sử dụng gói đã được hoàn lại.'
          : cancellation.refundAmount > 0
              ? ' Tiền hoàn: ${_formatCurrency(cancellation.refundAmount)} '
                  '(${cancellation.refundStatus == 'PENDING_MANUAL' ? 'chờ xử lý thủ công' : cancellation.refundStatus}).'
              : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hủy lịch đặt thành công!$refundMessage'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Không thể hủy lịch đặt.'),
        ),
      );
    }
  }

  Future<void> _showBookingDetailModal(BookingResponseDTO initialBooking) async {
    BookingResponseDTO booking = initialBooking;
    // Gọi API GET /api/photographer/bookings/{bookingId} để lấy chi tiết mới nhất
    final fresh = await _bookingApiService.getBookingDetail(initialBooking.bookingId);
    if (fresh != null) {
      booking = fresh;
    }
    if (!mounted) return;

    final shortId = booking.bookingId.length > 8
        ? booking.bookingId.substring(0, 8).toUpperCase()
        : booking.bookingId.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chi Tiết Đơn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor(booking.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _statusTextColor(booking.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mã đơn: #$shortId',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.textSecColor,
              ),
            ),
            const SizedBox(height: 16),

            // Space & Provider Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.inputColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SafeNetworkImage(
                    url: _resolveSpaceImage(booking),
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.spaceName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.providerName,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecColor,
                          ),
                        ),
                        if (booking.packageName != null && booking.packageName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking.packageName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Time & Price Info
            Text(
              'THÔNG TIN ĐẶT CHỖ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Ngày đặt:', _formatDateDisplay(booking.bookingDate)),
            _buildDetailRow('Khung giờ:', _formatTimeSlot(booking)),
            _buildDetailRow('Photographer:', booking.photographerName),
            _buildDetailRow(
              'Tiền cọc (${booking.depositStatus}):',
              _formatCurrency(booking.depositAmount),
            ),
            if (booking.qrCode.isNotEmpty)
              _buildDetailRow('Mã QR check-in:', booking.qrCode),
            if (booking.equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Thiết bị đi kèm:',
                booking.equipment
                    .map((e) => '${e.name} (x${e.quantity})')
                    .join(', '),
              ),
            ],

            Divider(height: 24, color: context.inputColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng thanh toán:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
                Text(
                  _formatCurrency(booking.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (booking.status.toUpperCase() == 'AWAITING_DEPOSIT') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              bookingId: booking.bookingId,
                              totalAmount: booking.depositAmount > 0 ? booking.depositAmount : booking.totalAmount,
                              timeSlot: _formatTimeSlot(booking),
                              bookingDate: _parseBookingDate(booking.bookingDate),
                            ),
                          ),
                        ).then((_) => _fetchBookings());
                      },
                      icon: const Icon(Icons.payment_rounded, size: 20),
                      label: const Text('Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (booking.status.toUpperCase() == 'CONFIRMED' ||
                    booking.status.toUpperCase() == 'COMPLETED') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showReviewBookingModal(booking);
                      },
                      icon: const Icon(Icons.star_rate_rounded, size: 20),
                      label: const Text(
                        'Đánh Giá Không Gian',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đang kết nối tới ${booking.providerName}...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_in_talk, size: 18),
                        label: const Text('Liên Hệ Host'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: context.borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    if (_canCancelBooking(booking)) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCancelling
                              ? null
                              : () => _handleCancelBooking(sheetContext, booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text(
                            'Hủy Lịch Đặt',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _resolveSpaceType(BookingResponseDTO booking) {
    final mapped = _spaceTypeMap[booking.spaceId.toLowerCase()];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    final lowerName = booking.spaceName.toLowerCase();
    if (lowerName.contains('darkroom') || lowerName.contains('phòng tối')) {
      return 'DARKROOM';
    }
    return 'STUDIO';
  }

  /// POST /api/photographer/bookings/{bookingId}/review
  void _showReviewBookingModal(BookingResponseDTO booking) {
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
                const SizedBox(height: 18),
                Text(
                  'Đánh Giá Không Gian Đặt Chỗ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${booking.spaceName} • ${_formatDateDisplay(booking.bookingDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 40,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setModalState(() => selectedRating = star);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText:
                        'Chia sẻ nhận xét về không gian, thiết bị và chất lượng phục vụ...',
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
                            setModalState(() => isSubmitting = true);
                            final res =
                                await _reviewApiService.createBookingReview(
                              bookingId: booking.bookingId,
                              request: SpaceReviewWriteRequestDTO(
                                spaceType: _resolveSpaceType(booking),
                                spaceId: booking.spaceId,
                                rating: selectedRating,
                                comment: commentController.text.trim(),
                              ),
                            );
                            if (!modalCtx.mounted) return;
                            setModalState(() => isSubmitting = false);

                            if (res['success'] == true) {
                              Navigator.pop(modalCtx);
                              if (!mounted) return;
                              toastification.show(
                                context: context,
                                type: ToastificationType.success,
                                style: ToastificationStyle.flatColored,
                                title: const Text('Đã gửi đánh giá!'),
                                description: Text(
                                  'Cảm ơn bạn đã đánh giá ${booking.spaceName}.',
                                ),
                                alignment: Alignment.topCenter,
                                autoCloseDuration: const Duration(seconds: 4),
                                showProgressBar: false,
                              );
                              final spaceItem = BookingItem.fromJson({
                                'resourceId': booking.spaceId,
                                'name': booking.spaceName,
                                'resourceType': _resolveSpaceType(booking),
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  settings: RouteSettings(arguments: spaceItem),
                                  builder: (_) => const ItemDetailScreen(),
                                ),
                              );
                            } else {
                              toastification.show(
                                context: modalCtx,
                                type: ToastificationType.warning,
                                style: ToastificationStyle.flatColored,
                                title: const Text('Chưa thể gửi đánh giá'),
                                description: Text(
                                  res['message']?.toString() ??
                                      'Vui lòng thử lại sau khi kết thúc buổi chụp.',
                                ),
                                alignment: Alignment.topCenter,
                                autoCloseDuration: const Duration(seconds: 4),
                                showProgressBar: false,
                              );
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecColor, fontSize: 14)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSchedulesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<BookingResponseDTO> list = List.from(_bookings);
          if (_statusFilterIndex == 1) {
            list = list.where((s) => s.status.toUpperCase() == 'CONFIRMED').toList();
          } else if (_statusFilterIndex == 2) {
            list = list.where((s) {
              final st = s.status.toUpperCase();
              return st == 'AWAITING_DEPOSIT' || st == 'PENDING';
            }).toList();
          } else if (_statusFilterIndex == 3) {
            list = list.where((s) => s.status.toUpperCase() == 'CANCELLED').toList();
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 20),
                Text(
                  'Tất Cả Lịch Đặt Chỗ (${list.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Status filter row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 0, setModalState),
                      const SizedBox(width: 8),
                      _buildFilterChip('Đã xác nhận', 1, setModalState),
                      const SizedBox(width: 8),
                      _buildFilterChip('Chờ cọc / Xác nhận', 2, setModalState),
                      const SizedBox(width: 8),
                      _buildFilterChip('Đã hủy', 3, setModalState),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: list.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 56, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'Không có lịch đặt nào',
                          style: TextStyle(
                            color: context.textSecColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final booking = list[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showBookingDetailModal(booking);
                        },
                        child: _buildScheduleCard(booking, showDate: true),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, StateSetter setModalState) {
    final isSelected = _statusFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: context.inputColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: isSelected ? context.cardColor : context.textColor,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _statusFilterIndex = index);
          setState(() => _statusFilterIndex = index);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekdayOffset = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final totalCells = daysInMonth + firstWeekdayOffset;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayBookings = _bookingsForSelectedDate;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Quản Lý Lịch Đặt Chỗ'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBookings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Card Container
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 0) {
                        _changeMonth(-1);
                      } else if (details.primaryVelocity! < 0) {
                        _changeMonth(1);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(24),
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
                        // Month Selector Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_months[_currentMonth.month - 1]}, ${_currentMonth.year}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: context.inputColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.chevron_left, color: context.textColor, size: 20),
                                    onPressed: () => _changeMonth(-1),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: context.inputColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.chevron_right, color: context.textColor, size: 20),
                                    onPressed: () => _changeMonth(1),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Calendar Days Header
                        const Row(
                          children: [
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'CN'))),
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'T2'))),
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'T3'))),
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'T4'))),
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'T5'))),
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'T6'))),
                            Expanded(child: Center(child: _CalendarDayHeader(day: 'T7'))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Days Numbers Grid
                        GridView.builder(
                          key: ValueKey('month_${_currentMonth.year}_${_currentMonth.month}'),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            if (index < firstWeekdayOffset) {
                              return const SizedBox.shrink();
                            }

                            final dayNumber = index - firstWeekdayOffset + 1;
                            final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                            final isSelected = _isSameDay(_selectedDate, cellDate);
                            final isPast = cellDate.isBefore(today);

                            final hasBooking = _bookings.any((b) {
                              final parsed = _parseBookingDate(b.bookingDate);
                              return _isSameDay(parsed, cellDate);
                            });

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = cellDate;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (hasBooking
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : Colors.transparent),
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayNumber.toString(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected || hasBooking ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? context.cardColor
                                            : (isPast
                                            ? AppColors.textHint.withValues(alpha: 0.65)
                                            : (hasBooking ? AppColors.primaryDark : context.textColor)),
                                      ),
                                    ),
                                    if (hasBooking) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ).animate(key: ValueKey('month_${_currentMonth.year}_${_currentMonth.month}')).fadeIn(duration: 300.ms).slideX(begin: 0.05),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Section Header: My Schedule
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lịch đặt ngày ${_selectedDate.day}/${_selectedDate.month}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAllSchedulesModal,
                      child: Text(
                        'Xem tất cả (${_bookings.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Schedules Cards List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.textHint),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: context.textSecColor, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _fetchBookings,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else if (dayBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text(
                            'Ngày này chưa có lịch đặt',
                            style: TextStyle(
                              color: context.textSecColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      key: ValueKey('day_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayBookings.length,
                      itemBuilder: (context, index) {
                        final booking = dayBookings[index];
                        return GestureDetector(
                          onTap: () => _showBookingDetailModal(booking),
                          child: _buildScheduleCard(booking),
                        );
                      },
                    ).animate(key: ValueKey('day_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}')).fadeIn(duration: 300.ms).slideY(begin: 0.08),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BookingResponseDTO booking, {bool showDate = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeNetworkImage(
            url: _resolveSpaceImage(booking),
            width: 84,
            height: 84,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.spaceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.providerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: context.textSecColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        showDate
                            ? '${_formatDateDisplay(booking.bookingDate)} • ${_formatTimeSlot(booking)}'
                            : _formatTimeSlot(booking),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textSecColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCurrency(booking.totalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBgColor(booking.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(booking.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusTextColor(booking.status),
                        ),
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
  }
}

class _CalendarDayHeader extends StatelessWidget {
  final String day;
  const _CalendarDayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Text(
      day,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.textSecColor,
      ),
    );
  }
}