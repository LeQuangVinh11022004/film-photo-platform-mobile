import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DeviceImagePicker {
  /// Mở thư viện ảnh trên thiết bị bằng image_picker.
  /// Trả về chuỗi `file:///...` để Backend ImageUrlResolver không ghép nhầm domain https:// vào đường dẫn file cục bộ.
  static Future<String?> pickImageFromDevice(
    BuildContext context, {
    required String title,
  }) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image != null && image.path.trim().isNotEmpty) {
        final rawPath = image.path.trim();
        final file = File(rawPath);
        if (file.existsSync()) {
          // Chuyển thành file:// URI để khi gửi lên Backend:
          // ImageUrlResolver.Resolve() thấy không bắt đầu bằng '/' nên giữ nguyên đường dẫn file cục bộ
          return Uri.file(file.path).toString();
        }
        return rawPath;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lỗi khi mở thư viện ảnh. Vui lòng cấp quyền truy cập.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return null;
  }
}
