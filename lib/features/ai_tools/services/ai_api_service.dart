import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

String formatPhotographyGuide(Map<String, dynamic> guide) {
  final sections = <String>[];
  void addText(String title, Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      sections.add('$title\n${value.trim()}');
    }
  }

  void addList(String title, Object? value) {
    if (value is List) {
      final items = value.whereType<String>().where((item) => item.trim().isNotEmpty);
      if (items.isNotEmpty) {
        sections.add('$title\n${items.map((item) => '• $item').join('\n')}');
      }
    }
  }

  addText('Ý tưởng', guide['concept']);
  addList('Bố cục', guide['compositionTips']);
  addList('Ánh sáng', guide['lightingSetup']);
  final settings = guide['cameraSettings'];
  if (settings is Map<String, dynamic>) {
    final values = <String>[];
    for (final entry in {
      'Khẩu độ': settings['aperture'],
      'Tốc độ màn trập': settings['shutterSpeed'],
      'ISO': settings['iso'],
    }.entries) {
      if (entry.value is String && (entry.value as String).trim().isNotEmpty) {
        values.add('${entry.key}: ${entry.value}');
      }
    }
    if (values.isNotEmpty) sections.add('Thông số máy ảnh\n${values.join('\n')}');
  }
  addList('Danh sách ảnh', guide['shotList']);
  addText('Lưu ý an toàn', guide['safetyNote']);
  return sections.join('\n\n');
}

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
        if (data is! Map<String, dynamic>) {
          return {'success': false, 'message': 'Máy chủ trả về hướng dẫn không hợp lệ.'};
        }
        final guide = formatPhotographyGuide(data);
        if (guide.isEmpty) {
          return {'success': false, 'message': 'Máy chủ không trả về nội dung hướng dẫn.'};
        }
        return {
          'success': true,
          'guide': guide,
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
