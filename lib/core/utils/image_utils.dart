import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';

class _DevFriendlyCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'filmPhotoDevCacheKey';
  static final _DevFriendlyCacheManager _instance =
      _DevFriendlyCacheManager._();

  factory _DevFriendlyCacheManager() => _instance;

  _DevFriendlyCacheManager._()
      : super(
          Config(
            key,
            fileService: HttpFileService(
              httpClient: _createHttpClient(),
            ),
          ),
        );

  static IOClient _createHttpClient() {
    final httpClient = HttpClient();
    if (kDebugMode) {
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return IOClient(httpClient);
  }
}

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

  /// Kiểm tra xem chuỗi có phải đường dẫn file cục bộ trên Android / iOS / Windows không
  static String? extractLocalFilePath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Trường hợp file:// URI (VD: file:///data/user/0/... hoặc file:///C:/Users/...)
    if (trimmed.startsWith('file://')) {
      try {
        return Uri.parse(trimmed).toFilePath();
      } catch (_) {
        return trimmed.replaceFirst(RegExp(r'^file://'), '');
      }
    }

    // 2. Trường hợp Backend ImageUrlResolver ghép nhầm domain https://... vào đường dẫn local (/data/..., /storage/..., /var/..., /Users/...)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final path = Uri.decodeFull(uri.path);
        if (path.startsWith('/data/') ||
            path.startsWith('/storage/') ||
            path.startsWith('/sdcard/') ||
            path.startsWith('/mnt/') ||
            path.startsWith('/var/') ||
            path.startsWith('/private/') ||
            path.startsWith('/Users/') ||
            RegExp(r'^/[a-zA-Z]:[\\/]').hasMatch(path)) {
          final cleanPath = RegExp(r'^/[a-zA-Z]:[\\/]').hasMatch(path)
              ? path.substring(1)
              : path;
          return cleanPath;
        }
      }
      return null;
    }

    // 3. Đường dẫn tuyệt đối trên Android / iOS / macOS / Linux
    if (trimmed.startsWith('/data/') ||
        trimmed.startsWith('/storage/') ||
        trimmed.startsWith('/sdcard/') ||
        trimmed.startsWith('/mnt/') ||
        trimmed.startsWith('/var/') ||
        trimmed.startsWith('/private/') ||
        trimmed.startsWith('/Users/') ||
        trimmed.startsWith('/tmp/')) {
      return trimmed;
    }

    // 4. Đường dẫn Windows (VD: C:\Users\... hoặc D:/...)
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  String _resolveNetworkUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // Thay thế domain demo giả (images.example.com) từ dữ liệu seed của Backend bằng ảnh film thật
    if (trimmed.contains('images.example.com')) {
      if (trimmed.contains('print')) {
        return 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80';
      }
      return 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&auto=format&fit=crop&q=80';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = ApiClient().baseUrl.endsWith('/')
        ? ApiClient().baseUrl.substring(0, ApiClient().baseUrl.length - 1)
        : ApiClient().baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    Widget imageWidget;

    // Hỗ trợ Data URL base64 (data:image/jpeg;base64,...)
    if (trimmed.startsWith('data:image/')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx != -1 && commaIdx + 1 < trimmed.length) {
        try {
          final bytes = base64Decode(trimmed.substring(commaIdx + 1));
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
          );
        } catch (_) {
          imageWidget = _buildErrorPlaceholder();
        }
      } else {
        imageWidget = _buildErrorPlaceholder();
      }
    } else {
      final localPath = extractLocalFilePath(trimmed);
      if (localPath != null && localPath.isNotEmpty) {
        imageWidget = Image.file(
          File(localPath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint('SafeNetworkImage local file error ($localPath): $error');
            }
            return _buildErrorPlaceholder();
          },
        );
      } else {
        final resolved = _resolveNetworkUrl(trimmed);
        if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
          final int? cacheWidth = (width != null && width!.isFinite && width! > 0)
              ? (width! * 2).round()
              : null;
          final int? cacheHeight = (height != null && height!.isFinite && height! > 0)
              ? (height! * 2).round()
              : null;
          imageWidget = CachedNetworkImage(
            imageUrl: resolved,
            cacheManager: kDebugMode
                ? _DevFriendlyCacheManager()
                : DefaultCacheManager(),
            width: width,
            height: height,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            fadeInDuration: const Duration(milliseconds: 180),
            fit: fit,
            placeholder: (context, _) => Container(
              width: width,
              height: height,
              color: AppColors.inputFill,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            errorWidget: (context, _, error) {
              if (kDebugMode) {
                debugPrint('SafeNetworkImage error ($resolved): $error');
              }
              return _buildErrorPlaceholder();
            },
          );
        } else {
          imageWidget = _buildErrorPlaceholder();
        }
      }
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
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
