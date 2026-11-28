import 'booking_item.dart';

enum BookingStatus { confirmed, pending, completed, cancelled }

class BookingSchedule {
  final String id;
  final BookingItem item;
  final DateTime bookingDate;
  final String timeSlot;
  final double totalPrice;
  final BookingStatus status;

  BookingSchedule({
    required this.id,
    required this.item,
    required this.bookingDate,
    required this.timeSlot,
    required this.totalPrice,
    required this.status,
  });

  String get statusText {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.completed:
        return 'Đã hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
