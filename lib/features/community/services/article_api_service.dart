import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../booking/models/booking_api_models.dart';
import '../models/article_api_models.dart';

class ArticleApiService {
  static final ArticleApiService _instance = ArticleApiService._internal();
  factory ArticleApiService() => _instance;
  ArticleApiService._internal();

  final ApiClient _apiClient = ApiClient();

  // ===========================================================================
  // 1. ENDPOINTS DÀNH CHO PHOTOGRAPHER & CỘNG ĐỒNG (/api/articles)
  // ===========================================================================

  /// GET /api/articles?category=...&page=1&pageSize=20
  Future<PagedResponseDTO<ArticleResponseDTO>?> getPublishedArticles({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String queryParams = '?page=$page&pageSize=$pageSize';
      if (category != null && category.trim().isNotEmpty) {
        queryParams +=
            '&category=${Uri.encodeQueryComponent(category.trim())}';
      }

      final response = await _apiClient.get('/api/articles$queryParams');
      if (kDebugMode) {
        print('getPublishedArticles status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResponseDTO<ArticleResponseDTO>.fromJson(
          json,
          (item) => ArticleResponseDTO.fromJson(item),
        );
      } else {
        if (kDebugMode) {
          print(
              'Failed getPublishedArticles (${response.statusCode}): ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getPublishedArticles API Error: $e');
      return null;
    }
  }

  /// GET /api/articles/{articleId}
  Future<ArticleResponseDTO?> getPublishedArticleDetail(
      String articleId) async {
    try {
      final response = await _apiClient.get('/api/articles/$articleId');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ArticleResponseDTO.fromJson(json);
      } else {
        if (kDebugMode) {
          print(
              'Failed getPublishedArticleDetail (${response.statusCode}): ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getPublishedArticleDetail API Error: $e');
      return null;
    }
  }

  // ===========================================================================
  // 2. ENDPOINTS DÀNH CHO ROLE EXPERT (/api/expert/articles)
  // ===========================================================================

  /// GET /api/expert/articles?status=...&page=1&pageSize=20
  Future<PagedResponseDTO<ArticleResponseDTO>?> getExpertArticles({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String queryParams = '?page=$page&pageSize=$pageSize';
      if (status != null && status.trim().isNotEmpty) {
        queryParams += '&status=${Uri.encodeQueryComponent(status.trim())}';
      }

      final response = await _apiClient.get('/api/expert/articles$queryParams');
      if (kDebugMode) {
        print('getExpertArticles status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PagedResponseDTO<ArticleResponseDTO>.fromJson(
          json,
          (item) => ArticleResponseDTO.fromJson(item),
        );
      } else {
        if (kDebugMode) {
          print(
              'Failed getExpertArticles (${response.statusCode}): ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getExpertArticles API Error: $e');
      return null;
    }
  }

  /// GET /api/expert/articles/{articleId}
  Future<ArticleResponseDTO?> getExpertArticleDetail(String articleId) async {
    try {
      final response = await _apiClient.get('/api/expert/articles/$articleId');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ArticleResponseDTO.fromJson(json);
      } else {
        if (kDebugMode) {
          print(
              'Failed getExpertArticleDetail (${response.statusCode}): ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('getExpertArticleDetail API Error: $e');
      return null;
    }
  }

  /// POST /api/expert/articles
  Future<Map<String, dynamic>> createExpertArticle(
      ArticleWriteRequestDTO request) async {
    try {
      final response = await _apiClient.post(
        '/api/expert/articles',
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
          'article':
              json.isNotEmpty ? ArticleResponseDTO.fromJson(json) : null,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'Chỉ tài khoản Chuyên gia (EXPERT) mới có quyền tạo bài viết chuyên môn.',
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ??
              'Tạo bài viết thất bại (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('createExpertArticle API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi tạo bài viết: $e',
      };
    }
  }

  /// PUT /api/expert/articles/{articleId}
  Future<Map<String, dynamic>> updateExpertArticle({
    required String articleId,
    required ArticleWriteRequestDTO request,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/expert/articles/$articleId',
        body: request.toJson(),
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
          'article':
              json.isNotEmpty ? ArticleResponseDTO.fromJson(json) : null,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Không tìm thấy bài viết hoặc bạn không phải tác giả.',
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ??
              'Cập nhật bài viết thất bại (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('updateExpertArticle API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi cập nhật bài viết: $e',
      };
    }
  }

  /// PATCH /api/expert/articles/{articleId}/status (và fallback /api/expert/articles/{articleId})
  Future<Map<String, dynamic>> updateExpertArticleStatus({
    required String articleId,
    required String status,
  }) async {
    final dto = ArticleStatusUpdateRequestDTO(status: status);
    try {
      var response = await _apiClient.patch(
        '/api/expert/articles/$articleId/status',
        body: dto.toJson(),
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        // Fallback nếu route PATCH không có hậu tố /status
        final fallbackResp = await _apiClient.patch(
          '/api/expert/articles/$articleId',
          body: dto.toJson(),
        );
        if (fallbackResp.statusCode == 200) {
          response = fallbackResp;
        }
      }

      Map<String, dynamic> json = {};
      if (response.body.isNotEmpty) {
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'article':
              json.isNotEmpty ? ArticleResponseDTO.fromJson(json) : null,
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ??
              'Đổi trạng thái bài viết thất bại (Mã lỗi: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) print('updateExpertArticleStatus API Error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi cập nhật trạng thái: $e',
      };
    }
  }

  /// DELETE /api/expert/articles/{articleId}
  Future<bool> deleteExpertArticle(String articleId) async {
    try {
      final response = await _apiClient.delete(
        '/api/expert/articles/$articleId',
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('deleteExpertArticle API Error: $e');
      return false;
    }
  }
}
