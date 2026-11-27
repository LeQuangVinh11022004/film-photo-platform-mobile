import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../booking/models/booking_api_models.dart';
import '../models/community_post_api_models.dart';

class CommunityPostApiService {
  static final CommunityPostApiService _instance =
      CommunityPostApiService._internal();
  factory CommunityPostApiService() => _instance;
  CommunityPostApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// GET /api/community/posts
  /// Lấy danh sách bài đăng cộng đồng (dành cho PHOTOGRAPHER và EXPERT)
  Future<PagedResponseDTO<CommunityPostResponseDTO>?> getFeed({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String query = '?page=$page&pageSize=$pageSize';
      if (category != null && category.trim().isNotEmpty) {
        query += '&category=${Uri.encodeQueryComponent(category.trim())}';
      }

      final response = await _apiClient.get('/api/community/posts$query');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResponseDTO<CommunityPostResponseDTO>.fromJson(
          json,
          (item) => CommunityPostResponseDTO.fromJson(item),
        );
      }
      if (kDebugMode) {
        print('getFeed failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getFeed error: $e');
      return null;
    }
  }

  /// GET /api/community/posts/mine
  /// Lấy danh sách bài đăng cộng đồng của chính user hiện tại
  Future<PagedResponseDTO<CommunityPostResponseDTO>?> getMyPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/community/posts/mine?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResponseDTO<CommunityPostResponseDTO>.fromJson(
          json,
          (item) => CommunityPostResponseDTO.fromJson(item),
        );
      }
      if (kDebugMode) {
        print('getMyPosts failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getMyPosts error: $e');
      return null;
    }
  }

  /// GET /api/community/posts/{postId}
  /// Xem chi tiết một bài đăng cộng đồng
  Future<CommunityPostResponseDTO?> getPostDetail(String postId) async {
    try {
      final response = await _apiClient.get('/api/community/posts/$postId');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CommunityPostResponseDTO.fromJson(json);
      }
      if (kDebugMode) {
        print('getPostDetail failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getPostDetail error: $e');
      return null;
    }
  }

  /// POST /api/community/posts
  /// Tạo bài đăng cộng đồng mới (dành cho PHOTOGRAPHER và EXPERT)
  Future<Map<String, dynamic>> createPost(
    CommunityPostWriteRequestDTO request,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/community/posts',
        body: request.toJson(),
      );

      Map<String, dynamic> json = {};
      if (response.body.isNotEmpty) {
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (json['postId'] == null || json['postId'].toString().isEmpty) {
          return {
            'success': false,
            'message': 'Máy chủ không trả về thông tin bài đăng hợp lệ.',
          };
        }
        final created = CommunityPostResponseDTO.fromJson(json);
        return {
          'success': true,
          'post': created,
        };
      }
      return {
        'success': false,
        'message': json['message'] ??
            'Không thể đăng bài viết cộng đồng (Mã lỗi: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) print('createPost error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối khi đăng bài viết: $e',
      };
    }
  }

  /// PUT /api/community/posts/{postId}
  /// Cập nhật bài đăng cộng đồng của chính mình
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required CommunityPostWriteRequestDTO request,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/community/posts/$postId',
        body: request.toJson(),
      );

      Map<String, dynamic> json = {};
      if (response.body.isNotEmpty) {
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        if (json['postId'] == null || json['postId'].toString().isEmpty) {
          return {
            'success': false,
            'message': 'Máy chủ không trả về thông tin bài đăng hợp lệ.',
          };
        }
        final updated = CommunityPostResponseDTO.fromJson(json);
        return {
          'success': true,
          'post': updated,
        };
      }
      return {
        'success': false,
        'message': json['message'] ??
            'Không thể cập nhật bài đăng (Mã lỗi: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) print('updatePost error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối khi cập nhật bài đăng: $e',
      };
    }
  }

  /// DELETE /api/community/posts/{postId}
  /// Xóa bài đăng cộng đồng của chính mình
  Future<bool> deletePost(String postId) async {
    try {
      final response = await _apiClient.delete('/api/community/posts/$postId');
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('deletePost error: $e');
      return false;
    }
  }

  /// PUT /api/community/posts/{postId}/like
  /// Thích bài đăng cộng đồng
  Future<bool> likePost(String postId) async {
    try {
      final response =
          await _apiClient.put('/api/community/posts/$postId/like');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('likePost error: $e');
      return false;
    }
  }

  /// DELETE /api/community/posts/{postId}/like
  /// Bỏ thích bài đăng cộng đồng
  Future<bool> unlikePost(String postId) async {
    try {
      final response =
          await _apiClient.delete('/api/community/posts/$postId/like');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('unlikePost error: $e');
      return false;
    }
  }

  /// GET /api/community/posts/{postId}/comments
  /// Lấy danh sách bình luận của một bài đăng cộng đồng
  Future<PagedResponseDTO<CommunityCommentResponseDTO>?> getComments({
    required String postId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/community/posts/$postId/comments?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResponseDTO<CommunityCommentResponseDTO>.fromJson(
          json,
          (item) => CommunityCommentResponseDTO.fromJson(item),
        );
      }
      if (kDebugMode) {
        print('getComments failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getComments error: $e');
      return null;
    }
  }

  /// POST /api/community/posts/{postId}/comments
  /// Tạo bình luận mới cho bài đăng cộng đồng
  Future<Map<String, dynamic>> createComment({
    required String postId,
    required CommunityCommentWriteRequestDTO request,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/community/posts/$postId/comments',
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
          'comment': json.isNotEmpty
              ? CommunityCommentResponseDTO.fromJson(json)
              : null,
        };
      }
      return {
        'success': false,
        'message': json['message'] ??
            'Không thể gửi bình luận (Mã lỗi: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) print('createComment error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối khi gửi bình luận: $e',
      };
    }
  }

  /// PUT /api/community/posts/{postId}/comments/{commentId}
  /// Cập nhật nội dung bình luận của chính mình
  Future<Map<String, dynamic>> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/community/posts/$postId/comments/$commentId',
        body: {'content': content.trim()},
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
          'comment': json.isNotEmpty
              ? CommunityCommentResponseDTO.fromJson(json)
              : null,
        };
      }
      return {
        'success': false,
        'message': json['message'] ??
            'Không thể sửa bình luận (Mã lỗi: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) print('updateComment error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối khi sửa bình luận: $e',
      };
    }
  }

  /// DELETE /api/community/posts/{postId}/comments/{commentId}
  /// Xóa bình luận của chính mình
  Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/api/community/posts/$postId/comments/$commentId',
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('deleteComment error: $e');
      return false;
    }
  }
}
