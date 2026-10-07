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

  static List<BookingSchedule> sampleSchedules = [
    BookingSchedule(
      id: 'BK-101',
      item: BookingItem.sampleItems[0], // Vintage Film Studio Saigon
      bookingDate: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '09:00 - 12:00 (3 giờ)',
      totalPrice: 750000,
      status: BookingStatus.confirmed,
    ),
    BookingSchedule(
      id: 'BK-102',
      item: BookingItem.sampleItems[1], // Silver Halide Darkroom Studio
      bookingDate: DateTime.now().add(const Duration(days: 3)),
      timeSlot: '14:00 - 17:00 (3 giờ)',
      totalPrice: 540000,
      status: BookingStatus.confirmed,
    ),
    BookingSchedule(
      id: 'BK-103',
      item: BookingItem.sampleItems[2], // Leica M6
      bookingDate: DateTime.now().subtract(const Duration(days: 5)),
      timeSlot: 'Cả ngày (8 giờ)',
      totalPrice: 960000,
      status: BookingStatus.completed,
    ),
  ];
}
