import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/review_api_models.dart';

class ReviewApiService {
  static final ReviewApiService _instance = ReviewApiService._internal();
  factory ReviewApiService() => _instance;
  ReviewApiService._internal();

  final ApiClient _apiClient = ApiClient();

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
        return SpaceReviewPageResponseDTO.fromJson(json);
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
        return SpaceReviewPageResponseDTO.fromJson(json);
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
  /// Gửi đánh giá cho Studio/Darkroom sau khi đơn đặt chỗ đã thanh toán và hoàn tất
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
      }

      String message = json['message']?.toString() ??
          'Không thể gửi đánh giá (Mã lỗi: ${response.statusCode})';

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
