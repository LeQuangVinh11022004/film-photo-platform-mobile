import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

class SafeNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Check if the URL is a local file path (from image_picker) or a network URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColors.inputFill,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      );
    } else if (url.isNotEmpty) {
      // Load local file image (picked from device gallery)
      imageWidget = Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else {
      imageWidget = _buildErrorPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: borderRadius,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_roll_outlined, size: 28, color: AppColors.primary),
          SizedBox(height: 4),
          Text(
            'Film Image',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
