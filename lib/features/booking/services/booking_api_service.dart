import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../models/review_api_models.dart';

class BookingApiService {
  // Singleton pattern
  static final BookingApiService _instance = BookingApiService._internal();
  factory BookingApiService() => _instance;
  BookingApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách Studios (/api/photographer/studios)
  Future<List<ResourceItemResponseDTO>> getStudios({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String queryParams = '';
      if (fromDate != null && toDate != null) {
        queryParams = '?fromDate=$fromDate&toDate=$toDate';
      }

      final response = await _apiClient.get('/api/photographer/studios$queryParams');
      if (kDebugMode) {
        print('getStudios status: ${response.statusCode}');
        print('getStudios body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final jsonList = _extractJsonList(decoded);
        return jsonList
            .map((e) =>
            ResourceItemResponseDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) print('Failed to get studios (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e, stack) {
      if (kDebugMode) print('getStudios API Error: $e\n$stack');
      return [];
    }
  }

  /// Lấy danh sách Darkrooms (/api/photographer/darkrooms)
  Future<List<ResourceItemResponseDTO>> getDarkrooms({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String queryParams = '';
      if (fromDate != null && toDate != null) {
        queryParams = '?fromDate=$fromDate&toDate=$toDate';
      }

      final response = await _apiClient.get('/api/photographer/darkrooms$queryParams');
      if (kDebugMode) {
        print('getDarkrooms status: ${response.statusCode}');
        print('getDarkrooms body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final jsonList = _extractJsonList(decoded);
        return jsonList
            .map((e) =>
            ResourceItemResponseDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) print('Failed to get darkrooms (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e, stack) {
      if (kDebugMode) print('getDarkrooms API Error: $e\n$stack');
      return [];
    }
  }

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
        final decoded = jsonDecode(response.body);
        final jsonList = _extractJsonList(decoded);
        return jsonList
            .map((e) => ProviderSpaceAvailabilityResponseDTO.fromJson(
            e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) print('Failed to get slots: ${response.body}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('getAvailableSlots API Error: $e');
      return [];
    }
  }

  /// Lấy danh sách Thiết bị của một Space (/api/photographer/spaces/{spaceId}/equipment)
  Future<PagedResponseDTO<PhotographerEquipmentResponseDTO>?> getEquipmentForSpace({
    required String spaceId,
    String? availabilityId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String queryParams = '?page=$page&pageSize=$pageSize';
      if (availabilityId != null && availabilityId.trim().isNotEmpty) {
        queryParams += '&availabilityId=${availabilityId.trim()}';
      }

      final response = await _apiClient.get(
        '/api/photographer/spaces/$spaceId/equipment$queryParams',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResponseDTO<PhotographerEquipmentResponseDTO>.fromJson(
          json,
          (item) => PhotographerEquipmentResponseDTO.fromJson(item),
        );
      }
      if (kDebugMode) {
        print(
          'Failed to get space equipment (${response.statusCode}): ${response.body}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getEquipmentForSpace API Error: $e');
      return null;
    }
  }

  /// Gom toàn bộ thiết bị từ các Studio/Darkroom đã tải (gọi /spaces/{id}/equipment, đọc hết các trang).
  /// Thiết bị trùng equipmentId giữa các không gian chỉ xuất hiện một lần.
  Future<List<BookingItem>> getAllEquipmentItems(List<BookingItem> spaces) async {
    final results = await Future.wait(spaces.map((space) => _getAllEquipmentForSpace(space)));
    final seen = <String>{};
    final items = <BookingItem>[];
    for (final list in results) {
      for (final item in list) {
        if (seen.add(item.id)) items.add(item);
      }
    }
    return items;
  }

  Future<List<BookingItem>> _getAllEquipmentForSpace(BookingItem space) async {
    const pageSize = 50;
    final items = <BookingItem>[];
    var page = 1;
    while (true) {
      final result = await getEquipmentForSpace(spaceId: space.id, page: page, pageSize: pageSize);
      if (result == null || result.items.isEmpty) break;
      items.addAll(result.items.map((dto) => BookingItem.fromEquipmentDto(dto, spaceName: space.name)));
      if (items.length >= result.totalCount || result.items.length < pageSize) break;
      page++;
    }
    return items;
  }

  /// Lấy danh sách khung giờ trống của một Thiết bị (/api/photographer/equipment/{equipmentId}/availability)
  /// `fromDate` và `toDate` có định dạng 'YYYY-MM-DD'
  Future<List<PhotographerEquipmentAvailabilityResponseDTO>> getEquipmentAvailability({
    required String equipmentId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String queryParams = '';
      if (fromDate != null && toDate != null) {
        queryParams = '?fromDate=$fromDate&toDate=$toDate';
      }

      final response = await _apiClient.get(
        '/api/photographer/equipment/$equipmentId/availability$queryParams',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final jsonList = _extractJsonList(decoded);
        return jsonList
            .map((e) => PhotographerEquipmentAvailabilityResponseDTO.fromJson(
                e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print('Failed to get equipment slots (${response.statusCode}): ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('getEquipmentAvailability API Error: $e');
      return [];
    }
  }

  /// Lấy danh sách các Gói dịch vụ Combo đang hoạt động (/api/photographer/service-packages)
  Future<List<PhotographerServicePackageResponseDTO>> getServicePackages() async {
    try {
      final response = await _apiClient.get('/api/photographer/service-packages');
      if (kDebugMode) {
        print('getServicePackages status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final jsonList = _extractJsonList(decoded);
        return jsonList
            .map((e) => PhotographerServicePackageResponseDTO.fromJson(
                e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print('Failed to get service packages (${response.statusCode}): ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('getServicePackages API Error: $e');
      return [];
    }
  }

  /// Khởi tạo giao dịch mua Gói dịch vụ qua VNPay (/api/photographer/service-packages/{packageId}/purchase)
  Future<Map<String, dynamic>> purchaseServicePackage(String packageId) async {
    try {
      final response = await _apiClient.post(
        '/api/photographer/service-packages/$packageId/purchase',
      );

      Map<String, dynamic> json = {};
      if (response.body.isNotEmpty) {
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.isNotEmpty
              ? PackagePurchasePaymentResponseDTO.fromJson(json)
              : null,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn hoặc bạn không có quyền thực hiện. Vui lòng đăng nhập lại.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Chỉ tài khoản Photographer mới có thể mua gói dịch vụ.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': json['message'] ?? 'Gói dịch vụ không khả dụng hoặc không thể mua.',
        };
      } else if (response.statusCode == 503) {
        return {
          'success': false,
          'message': json['message'] ?? 'Cổng thanh toán VNPay hiện đang tạm ngưng (503).',
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ??
              json['detail'] ??
              json['title'] ??
              'Không thể khởi tạo mua gói dịch vụ (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('purchaseServicePackage API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gọi API mua gói dịch vụ: $e',
      };
    }
  }

  /// Lấy danh sách các Gói dịch vụ đã đăng ký của Photographer (/api/photographer/package-subscriptions)
  Future<List<PhotographerPackageSubscriptionResponseDTO>> getPackageSubscriptions() async {
    try {
      final response = await _apiClient.get('/api/photographer/package-subscriptions');
      if (kDebugMode) {
        print('getPackageSubscriptions status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final jsonList = _extractJsonList(decoded);
        return jsonList
            .map((e) => PhotographerPackageSubscriptionResponseDTO.fromJson(
                e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print('Failed to get package subscriptions (${response.statusCode}): ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('getPackageSubscriptions API Error: $e');
      return [];
    }
  }

  /// Lấy thông tin chi tiết một Gói dịch vụ đã đăng ký (/api/photographer/package-subscriptions/{subscriptionId})
  Future<PhotographerPackageSubscriptionResponseDTO?> getPackageSubscriptionDetail(
      String subscriptionId) async {
    try {
      final response = await _apiClient.get(
        '/api/photographer/package-subscriptions/$subscriptionId',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PhotographerPackageSubscriptionResponseDTO.fromJson(json);
      } else {
        if (kDebugMode) {
          print('Failed to get subscription detail (${response.statusCode}): ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getPackageSubscriptionDetail API Error: $e');
      return null;
    }
  }

  /// Tạo đơn đặt lịch sử dụng Gói Subscription đã mua (/api/photographer/bookings)
  Future<Map<String, dynamic>> createPackageBooking({
    required String subscriptionId,
    required List<PackageBookingSegmentRequestDTO> segments,
  }) async {
    final request = BookingCreateRequestDTO.fromSubscription(
      subscriptionId: subscriptionId,
      segments: segments,
    );
    return createBooking(request);
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

  /// Thanh toán tiền cọc cho đơn đặt phòng (/api/photographer/bookings/{bookingId}/deposit-payment)
  Future<Map<String, dynamic>> payDeposit({
    required String bookingId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/photographer/bookings/$bookingId/deposit-payment',
        body: {
          'paymentMethod': paymentMethod,
        },
      );

      Map<String, dynamic> json = {};
      if (response.body.isNotEmpty) {
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.isNotEmpty ? DepositPaymentResponseDTO.fromJson(json) : null,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn hoặc bạn không có quyền thực hiện. Vui lòng đăng nhập lại.',
        };
      } else if (response.statusCode == 503) {
        return {
          'success': false,
          'message': 'Cổng thanh toán hiện đang tạm ngưng (503). Vui lòng thử lại sau.',
        };
      } else {
        return {
          'success': false,
          'message': json['detail'] ??
              json['title'] ??
              json['message'] ??
              'Khởi tạo thanh toán cọc thất bại (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('payDeposit API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gọi API thanh toán cọc: $e',
      };
    }
  }

  //
  List<dynamic> _extractJsonList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final candidate = decoded['value'] ?? decoded['items'] ?? decoded['data'];
      if (candidate is List) {
        return candidate;
      }
    }
    return [];
  }

  /// Hủy đơn đặt phòng (Photographer)
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await _apiClient.patch(
        '/api/photographer/bookings/$bookingId/cancel',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final cancellation = BookingCancellationResponseDTO.fromJson(json);
        if (cancellation.bookingId.toLowerCase() != bookingId.toLowerCase() ||
            cancellation.status.toUpperCase() != 'CANCELLED' ||
            json['refundAmount'] is! num ||
            json['refundStatus'] is! String ||
            json['packageUseRestored'] is! bool) {
          return {
            'success': false,
            'message': 'Máy chủ trả về thông tin hủy lịch không hợp lệ. Vui lòng kiểm tra lại lịch đặt.',
          };
        }
        return {'success': true, 'cancellation': cancellation};
      }
      var message = 'Không thể hủy lịch đặt (Mã lỗi: ${response.statusCode}).';
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      }
      return {'success': false, 'message': message};
    } catch (e) {
      if (kDebugMode) print('cancelBooking API Error: $e');
      return {'success': false, 'message': 'Không thể kết nối để hủy lịch đặt.'};
    }
  }

  /// GET /api/photographer/studios/{studioId}/reviews
  /// Lấy danh sách đánh giá của Studio
  Future<SpaceReviewPageResponseDTO?> getStudioReviews({
    required String studioId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/photographer/studios/$studioId/reviews?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SpaceReviewPageResponseDTO.fromJson(json);
      }
      if (kDebugMode) {
        print(
            'getStudioReviews failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getStudioReviews API Error: $e');
      return null;
    }
  }

  /// GET /api/photographer/darkrooms/{darkroomId}/reviews
  /// Lấy danh sách đánh giá của Phòng tối (Darkroom)
  Future<SpaceReviewPageResponseDTO?> getDarkroomReviews({
    required String darkroomId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/photographer/darkrooms/$darkroomId/reviews?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SpaceReviewPageResponseDTO.fromJson(json);
      }
      if (kDebugMode) {
        print(
            'getDarkroomReviews failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getDarkroomReviews API Error: $e');
      return null;
    }
  }

  /// POST /api/photographer/bookings/{bookingId}/review
  /// Gửi đánh giá cho một đơn đặt chỗ đã thanh toán và hoàn thành
  Future<Map<String, dynamic>> createBookingReview({
    required String bookingId,
    required SpaceReviewWriteRequestDTO request,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/photographer/bookings/$bookingId/review',
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
          'review': json.isNotEmpty
              ? SpaceReviewResponseDTO.fromJson(json)
              : null,
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': json['message'] ??
              'Thông tin đánh giá không hợp lệ (Rating từ 1 đến 5 sao, tối đa 2000 ký tự).',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': json['message'] ??
              'Không tìm thấy đơn đặt chỗ hoặc không gian cần đánh giá.',
        };
      } else if (response.statusCode == 409) {
        final rawMsg = json['message']?.toString() ?? '';
        String viMsg =
            'Chỉ có thể đánh giá sau khi đơn đặt chỗ đã thanh toán và kết thúc.';
        if (rawMsg.toLowerCase().contains('already has a review')) {
          viMsg = 'Đơn đặt chỗ này đã được đánh giá trước đó.';
        } else if (rawMsg.toLowerCase().contains('not part of this booking')) {
          viMsg = 'Không gian đã chọn không thuộc đơn đặt chỗ này.';
        } else if (rawMsg.isNotEmpty) {
          viMsg = '$viMsg ($rawMsg)';
        }
        return {
          'success': false,
          'message': viMsg,
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ??
              'Không thể gửi đánh giá (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('createBookingReview API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gửi đánh giá: $e',
      };
    }
  }
}