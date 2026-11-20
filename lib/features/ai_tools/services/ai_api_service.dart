import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class AiApiService {
  static final AiApiService _instance = AiApiService._internal();
  factory AiApiService() => _instance;
  AiApiService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getPhotographyGuide({
    required String theme,
    required String location,
    required String availableLight,
    required String equipment,
    required String experienceLevel,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ai/photography-guide',
        body: {
          'theme': theme,
          'location': location,
          'availableLight': availableLight,
          'equipment': equipment,
          'experienceLevel': experienceLevel,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get guide. Status Code: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (kDebugMode) print('AiApiService getPhotographyGuide error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ.',
      };
    }
  }
}
