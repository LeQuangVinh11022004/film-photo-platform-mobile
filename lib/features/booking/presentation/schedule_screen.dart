import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';
import '../services/review_api_service.dart';
import '../widgets/schedule_all_bookings_sheet.dart';
import '../widgets/schedule_booking_card.dart';
import '../widgets/schedule_booking_detail_sheet.dart';
import '../widgets/schedule_calendar_card.dart';
import '../widgets/schedule_formatters.dart';
import '../widgets/schedule_review_sheet.dart';
import 'item_detail_screen.dart';
import 'payment_screen.dart';

void _cancelLog(String message) {
  if (kDebugMode) {
    debugPrint('[CANCEL_BOOKING_UI] $message');
  }
}

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
  int _statusFilterIndex =
      0; // 0: All, 1: Confirmed, 2: Pending/Awaiting Deposit, 3: Cancelled

  List<BookingResponseDTO> _bookings = [];
  Map<String, String> _spaceImageMap = {};
  Map<String, String> _spaceTypeMap = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCancelling = false;
  bool _hasAutoSelectedInitialDate = false;

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
            (b) => ScheduleHelpers.isSameDay(
              ScheduleHelpers.parseBookingDate(b.bookingDate),
              _selectedDate,
            ),
          );
          if (!hasToday) {
            final parsedDates = loaded
                .map((b) => ScheduleHelpers.parseBookingDate(b.bookingDate))
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

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      final daysInMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      final clampedDay = _selectedDate.day.clamp(1, daysInMonth);
      _selectedDate =
          DateTime(_currentMonth.year, _currentMonth.month, clampedDay);
    });
  }

  List<BookingResponseDTO> get _bookingsForSelectedDate {
    return _bookings.where((b) {
      final parsed = ScheduleHelpers.parseBookingDate(b.bookingDate);
      return ScheduleHelpers.isSameDay(parsed, _selectedDate);
    }).toList();
  }

  Future<void> _handleCancelBooking(
    BuildContext sheetContext,
    BookingResponseDTO booking,
  ) async {
    _cancelLog(
      'Tap Hủy Lịch Đặt | bookingId=${booking.bookingId} | '
      'status=${booking.status} | depositStatus=${booking.depositStatus} | '
      'date=${booking.bookingDate} | time=${booking.startTime}-${booking.endTime} | '
      'isCancelling=$_isCancelling',
    );
    if (_isCancelling) return;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hủy lịch đặt?'),
          content: const Text(
            'Bạn chỉ có thể hủy trước khi bắt đầu và check-in. '
            'Tiền cọc đã thanh toán được hoàn 100% trước ít nhất 48 giờ, '
            '50% từ 24 đến dưới 48 giờ, và không hoàn dưới 24 giờ. '
            'Với đơn dùng gói, lượt sử dụng có thể được hoàn lại.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Quay lại'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      );
      _cancelLog('Dialog result: confirmed=$confirmed | mounted=$mounted');
      if (confirmed != true || !mounted) return;

      setState(() => _isCancelling = true);

      final result = await _bookingApiService.cancelBooking(booking.bookingId);
      _cancelLog(
        'API result | success=${result['success']} | source=${result['source']} | '
        'statusCode=${result['statusCode']} | message=${result['message']} | '
        'rawBody=${result['rawBody']} | error=${result['error']}',
      );

      if (!mounted) return;

      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }

      if (result['success'] == true) {
        final cancellation =
            result['cancellation'] as BookingCancellationResponseDTO;
        await _fetchBookings();
        if (!mounted) return;
        final refundMessage = cancellation.packageUseRestored
            ? ' Lượt sử dụng gói đã được hoàn lại.'
            : cancellation.refundAmount > 0
                ? ' Tiền hoàn: ${ScheduleHelpers.formatCurrency(cancellation.refundAmount)} '
                    '(${cancellation.refundStatus == 'PENDING_MANUAL' ? 'chờ xử lý thủ công' : cancellation.refundStatus}).'
                : '';
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: const Text('Đã hủy lịch đặt thành công!'),
          description:
              refundMessage.isNotEmpty ? Text(refundMessage.trim()) : null,
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: false,
        );
      } else {
        final source = result['source']?.toString() ?? 'UNKNOWN';
        final statusCode = result['statusCode']?.toString() ?? '';
        final message =
            result['message']?.toString() ?? 'Không thể hủy lịch đặt.';
        _cancelLog(
          'Cancel failed ($source${statusCode.isNotEmpty ? ' $statusCode' : ''}): $message',
        );
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: Text(
            source == 'BE' && statusCode.isNotEmpty
                ? 'Hủy lịch thất bại (BE $statusCode)'
                : 'Hủy lịch thất bại ($source)',
          ),
          description: Text(message),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 5),
          showProgressBar: false,
        );
      }
    } catch (e, stackTrace) {
      _cancelLog('FE Exception in _handleCancelBooking: $e\n$stackTrace');
      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Lỗi FE khi hủy lịch đặt'),
          description: Text('$e'),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 5),
          showProgressBar: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _showBookingDetailModal(BookingResponseDTO initialBooking) async {
    BookingResponseDTO booking = initialBooking;
    // Gọi API GET /api/photographer/bookings/{bookingId} để lấy chi tiết mới nhất
    final fresh =
        await _bookingApiService.getBookingDetail(initialBooking.bookingId);
    if (fresh != null) {
      booking = fresh;
    }
    if (!mounted) return;

    await showScheduleBookingDetailSheet(
      context: context,
      booking: booking,
      spaceImageUrl:
          ScheduleHelpers.resolveSpaceImage(booking, _spaceImageMap),
      isCancelling: _isCancelling,
      onPayPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId: booking.bookingId,
              totalAmount: booking.depositAmount > 0
                  ? booking.depositAmount
                  : booking.totalAmount,
              timeSlot: ScheduleHelpers.formatTimeSlot(booking),
              bookingDate: ScheduleHelpers.parseBookingDate(booking.bookingDate),
            ),
          ),
        ).then((_) => _fetchBookings());
      },
      onReviewPressed: () => _showReviewBookingModal(booking),
      onContactHostPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đang kết nối tới ${booking.providerName}...'),
          ),
        );
      },
      onCancelPressed: (sheetContext) {
        _cancelLog(
          'Button Hủy Lịch Đặt pressed | bookingId=${booking.bookingId} | sheetMounted=${sheetContext.mounted}',
        );
        _handleCancelBooking(sheetContext, booking);
      },
    );
  }

  /// POST /api/photographer/bookings/{bookingId}/review
  Future<void> _showReviewBookingModal(BookingResponseDTO booking) async {
    final currentUserId =
        AuthService().currentUser?.userId.trim().toLowerCase() ?? '';
    final spaceType = ScheduleHelpers.resolveSpaceType(booking, _spaceTypeMap);

    if (currentUserId.isNotEmpty && booking.spaceId.length >= 32) {
      final existingPage = spaceType == 'DARKROOM'
          ? await _reviewApiService.getDarkroomReviews(
              darkroomId: booking.spaceId,
              page: 1,
              pageSize: 100,
            )
          : await _reviewApiService.getStudioReviews(
              studioId: booking.spaceId,
              page: 1,
              pageSize: 100,
            );
      if (!mounted) return;
      final alreadyReviewed = (existingPage?.items ?? []).any(
        (r) => r.customerUserId.trim().toLowerCase() == currentUserId,
      );
      if (alreadyReviewed) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          title: const Text('Bạn đã đánh giá rồi'),
          description: Text(
            'Mỗi tài khoản chỉ được gửi 1 đánh giá cho "${booking.spaceName}".',
          ),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
          showProgressBar: false,
        );
        return;
      }
    }

    final submitted = await showScheduleReviewSheet(
      context: context,
      booking: booking,
      resolvedSpaceType: spaceType,
      reviewApiService: _reviewApiService,
    );

    if (submitted == true && mounted) {
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
        'resourceType': spaceType,
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(arguments: spaceItem),
          builder: (_) => const ItemDetailScreen(),
        ),
      );
    }
  }

  void _showAllSchedulesModal() {
    showScheduleAllBookingsSheet(
      context: context,
      bookings: _bookings,
      initialFilterIndex: _statusFilterIndex,
      resolveSpaceImage: (booking) =>
          ScheduleHelpers.resolveSpaceImage(booking, _spaceImageMap),
      onFilterChanged: (index) {
        setState(() => _statusFilterIndex = index);
      },
      onSelectBooking: _showBookingDetailModal,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScheduleCalendarCard(
                  currentMonth: _currentMonth,
                  selectedDate: _selectedDate,
                  bookings: _bookings,
                  onChangeMonth: _changeMonth,
                  onSelectDate: (cellDate) {
                    setState(() => _selectedDate = cellDate);
                  },
                ),
                const SizedBox(height: 32),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 44,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: context.textSecColor,
                            fontSize: 14,
                          ),
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
                        const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        ),
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
                    key: ValueKey(
                      'day_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}',
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dayBookings.length,
                    itemBuilder: (context, index) {
                      final booking = dayBookings[index];
                      return ScheduleBookingCard(
                        booking: booking,
                        spaceImageUrl: ScheduleHelpers.resolveSpaceImage(
                          booking,
                          _spaceImageMap,
                        ),
                        onTap: () => _showBookingDetailModal(booking),
                      );
                    },
                  )
                      .animate(
                        key: ValueKey(
                          'day_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}',
                        ),
                      )
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
