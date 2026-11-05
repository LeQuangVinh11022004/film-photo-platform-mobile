import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/booking_api_models.dart';

class BookingApiService {
  // Singleton pattern
  static final BookingApiService _instance = BookingApiService._internal();
  factory BookingApiService() => _instance;
  BookingApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách khung giờ trống của một Space (Studio/Darkroom)
  /// `fromDate` và `toDate` có định dạng 'YYYY-MM-DD'
  Future<List<ProviderSpaceAvailabilityResponseDTO>> getAvailableSlots({
    required String spaceId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String queryParams = '';
      if (fromDate != null && toDate != null) {
        queryParams = '?fromDate=$fromDate&toDate=$toDate';
      }

      final response = await _apiClient.get('/api/photographer/spaces/$spaceId/availability$queryParams');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((e) => ProviderSpaceAvailabilityResponseDTO.fromJson(e)).toList();
      } else {
        if (kDebugMode) print('Failed to get slots: ${response.body}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('getAvailableSlots API Error: $e');
      return [];
    }
  }

  /// Lấy danh sách các đơn đặt phòng của Photographer hiện tại
  Future<PagedResponseDTO<BookingResponseDTO>?> getMyBookings({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String queryParams = '?page=$page&pageSize=$pageSize';
      if (status != null && status.isNotEmpty) {
        queryParams += '&status=$status';
      }

      final response = await _apiClient.get('/api/photographer/bookings$queryParams');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PagedResponseDTO<BookingResponseDTO>.fromJson(
          json,
          (item) => BookingResponseDTO.fromJson(item),
        );
      } else {
        if (kDebugMode) print('Failed to get bookings: ${response.body}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getMyBookings API Error: $e');
      return null;
    }
  }

  /// Lấy thông tin chi tiết một đơn đặt phòng
  Future<BookingResponseDTO?> getBookingDetail(String bookingId) async {
    try {
      final response = await _apiClient.get('/api/photographer/bookings/$bookingId');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BookingResponseDTO.fromJson(json);
      } else {
        if (kDebugMode) print('Failed to get booking detail: ${response.body}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getBookingDetail API Error: $e');
      return null;
    }
  }

  /// Tạo đơn đặt phòng mới (Photographer)
  Future<Map<String, dynamic>> createBooking(BookingCreateRequestDTO request) async {
    try {
      final response = await _apiClient.post(
        '/api/photographer/bookings',
        body: request.toJson(),
      );

      Map<String, dynamic> json = {};
      if (response.body.isNotEmpty) {
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'booking': json.isNotEmpty ? BookingResponseDTO.fromJson(json) : null,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn hoặc bạn không có quyền thực hiện. Vui lòng đăng nhập lại.',
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ?? 'Đặt lịch thất bại (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('createBooking API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gọi API: $e',
      };
    }
  }

  /// Hủy đơn đặt phòng (Photographer)
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await _apiClient.patch(
        '/api/photographer/bookings/$bookingId/cancel', // Using generic PATCH method (need to implement patch in ApiClient, or fallback to put/post if patch isn't there)
      );

      return response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('cancelBooking API Error: $e');
      return false;
    }
  }
}
