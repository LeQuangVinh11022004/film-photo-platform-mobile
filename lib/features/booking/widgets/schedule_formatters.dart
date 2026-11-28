import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';

class ScheduleHelpers {
  static const List<String> months = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  static DateTime? parseBookingDate(String rawDate) {
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

  static bool isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String formatTimeSlot(BookingResponseDTO booking) {
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

  static String formatDateDisplay(String rawDate) {
    final dt = parseBookingDate(rawDate);
    if (dt == null) return rawDate;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String formatCurrency(num amount) {
    final intVal = amount.round().toString();
    final formatted = intVal.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }

  static String statusLabel(String status) {
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

  static Color statusBgColor(String status) {
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

  static Color statusTextColor(String status) {
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

  static bool canCancelBooking(BookingResponseDTO booking) {
    final s = booking.status.toUpperCase();
    return s == 'AWAITING_DEPOSIT' || s == 'CONFIRMED';
  }

  static String resolveSpaceImage(
    BookingResponseDTO booking,
    Map<String, String> spaceImageMap,
  ) {
    final key = booking.spaceId.toLowerCase();
    final mapped = spaceImageMap[key];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    final isDarkroom = booking.spaceName.toLowerCase().contains('darkroom') ||
        booking.spaceName.toLowerCase().contains('phòng tối');
    return isDarkroom
        ? 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80'
        : 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80';
  }

  static String resolveSpaceType(
    BookingResponseDTO booking,
    Map<String, String> spaceTypeMap,
  ) {
    final mapped = spaceTypeMap[booking.spaceId.toLowerCase()];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    final lowerName = booking.spaceName.toLowerCase();
    if (lowerName.contains('darkroom') || lowerName.contains('phòng tối')) {
      return 'DARKROOM';
    }
    return 'STUDIO';
  }
}
