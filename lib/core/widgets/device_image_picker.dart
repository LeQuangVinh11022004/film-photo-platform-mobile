import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

class DeviceImagePicker {
  /// Opens the actual REAL device photo gallery using image_picker package
  static Future<String?> pickImageFromDevice(BuildContext context, {required String title}) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        return image.path; // Returns the local device file path (e.g. /data/user/0/.../image_picker_xxx.jpg)
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi mở thư viện ảnh. Vui lòng cấp quyền truy cập.'), backgroundColor: Colors.red),
        );
      }
    }
    
    return null;
  }
}
