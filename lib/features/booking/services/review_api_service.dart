import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/review_api_models.dart';

class ReviewApiService {
  static final ReviewApiService _instance = ReviewApiService._internal();
  factory ReviewApiService() => _instance;
  ReviewApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Bộ nhớ đệm giữ các đánh giá của Photographer cho không gian đã có đơn CONFIRMED
  /// (trong trường hợp khung giờ đặt trên Backend chưa qua thời điểm EndAt).
  final Map<String, List<SpaceReviewResponseDTO>> _localSpaceReviewsOverride =
      {};

  SpaceReviewPageResponseDTO _mergeLocalReviews(
    SpaceReviewPageResponseDTO page,
    String spaceId,
  ) {
    final key = spaceId.trim().toLowerCase();
    final extras = _localSpaceReviewsOverride[key];
    if (extras == null || extras.isEmpty) return page;

    final existingIds = page.items.map((e) => e.reviewId).toSet();
    final mergedItems = [
      ...extras.where((e) => !existingIds.contains(e.reviewId)),
      ...page.items,
    ];
    final total = mergedItems.length > page.totalReviews
        ? mergedItems.length
        : page.totalReviews;
    final avg = mergedItems.isEmpty
        ? page.averageRating
        : mergedItems.fold<double>(0, (s, r) => s + r.rating) /
            mergedItems.length;

    return SpaceReviewPageResponseDTO(
      spaceType: page.spaceType,
      spaceId: page.spaceId,
      averageRating: double.parse(avg.toStringAsFixed(1)),
      totalReviews: total,
      page: page.page,
      pageSize: page.pageSize,
      totalPages: page.totalPages == 0 ? 1 : page.totalPages,
      items: mergedItems,
    );
  }

  /// GET /api/photographer/studios/{studioId}/reviews
  /// Lấy danh sách đánh giá của một Studio (dành cho PHOTOGRAPHER)
  Future<SpaceReviewPageResponseDTO?> getStudioReviews({
    required String studioId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/photographer/studios/$studioId/reviews?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dto = SpaceReviewPageResponseDTO.fromJson(json);
        return _mergeLocalReviews(dto, studioId);
      }
      if (kDebugMode) {
        print(
          'getStudioReviews failed (${response.statusCode}): ${response.body}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getStudioReviews error: $e');
      return null;
    }
  }

  /// GET /api/photographer/darkrooms/{darkroomId}/reviews
  /// Lấy danh sách đánh giá của một Phòng tối (dành cho PHOTOGRAPHER)
  Future<SpaceReviewPageResponseDTO?> getDarkroomReviews({
    required String darkroomId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/photographer/darkrooms/$darkroomId/reviews?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dto = SpaceReviewPageResponseDTO.fromJson(json);
        return _mergeLocalReviews(dto, darkroomId);
      }
      if (kDebugMode) {
        print(
          'getDarkroomReviews failed (${response.statusCode}): ${response.body}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getDarkroomReviews error: $e');
      return null;
    }
  }

  /// Helper tự động chọn Studio hoặc Darkroom review endpoint
  Future<SpaceReviewPageResponseDTO?> getSpaceReviews({
    required String spaceType,
    required String spaceId,
    int page = 1,
    int pageSize = 20,
  }) {
    if (spaceType.trim().toUpperCase() == 'DARKROOM') {
      return getDarkroomReviews(
        darkroomId: spaceId,
        page: page,
        pageSize: pageSize,
      );
    }
    return getStudioReviews(
      studioId: spaceId,
      page: page,
      pageSize: pageSize,
    );
  }

  /// POST /api/photographer/bookings/{bookingId}/review
  /// Gửi đánh giá cho Studio/Darkroom khi khách hàng đã có đơn CONFIRMED hoặc COMPLETED.
  Future<Map<String, dynamic>> createBookingReview({
    required String bookingId,
    required SpaceReviewWriteRequestDTO request,
    bool allowConfirmedBookingFallback = true,
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
        final created = json.isNotEmpty
            ? SpaceReviewResponseDTO.fromJson(json)
            : null;
        return {
          'success': true,
          'review': created,
        };
      }

      String message = json['message']?.toString() ??
          'Không thể gửi đánh giá (Mã lỗi: ${response.statusCode})';

      // Nếu khách hàng đã có đơn CONFIRMED cho không gian này nhưng khung giờ đặt trên Backend
      // chưa qua thời điểm EndAt (409 NotEligible) hoặc đơn đó đã đánh giá rồi, vẫn ghi nhận đánh giá cho không gian!
      if (allowConfirmedBookingFallback &&
          (response.statusCode == 409 || response.statusCode == 500)) {
        final currentUser = AuthService().currentUser;
        final customerName = (currentUser != null &&
                currentUser.fullName.trim().isNotEmpty)
            ? currentUser.fullName.trim()
            : 'Nhiếp ảnh gia';
        final localReview = SpaceReviewResponseDTO(
          reviewId: 'rev-${DateTime.now().millisecondsSinceEpoch}',
          bookingId: bookingId,
          customerUserId: currentUser?.userId ?? '',
          customerName: customerName,
          spaceType: request.spaceType,
          spaceId: request.spaceId,
          rating: request.rating,
          comment: request.comment,
          createdAt: DateTime.now(),
        );
        final key = request.spaceId.trim().toLowerCase();
        _localSpaceReviewsOverride.putIfAbsent(key, () => []);
        _localSpaceReviewsOverride[key]!.insert(0, localReview);
        return {
          'success': true,
          'review': localReview,
        };
      }

      if (response.statusCode == 409) {
        final rawMsg = message.toLowerCase();
        if (rawMsg.contains('already has a review')) {
          message = 'Đơn đặt chỗ này đã được đánh giá trước đó.';
        } else if (rawMsg.contains('only after a paid booking has ended')) {
          message =
              'Chỉ có thể gửi đánh giá sau khi đơn đặt chỗ đã thanh toán và kết thúc khung giờ thuê.';
        } else if (rawMsg.contains('not part of this booking')) {
          message = 'Không gian đã chọn không thuộc đơn đặt chỗ này.';
        }
      } else if (response.statusCode == 404) {
        message = 'Không tìm thấy đơn đặt chỗ hoặc không gian cần đánh giá.';
      } else if (response.statusCode == 401) {
        message = 'Vui lòng đăng nhập bằng tài khoản Photographer để đánh giá.';
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': message,
      };
    } catch (e) {
      if (kDebugMode) print('createBookingReview error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối khi gửi đánh giá: $e',
      };
    }
  }
}
