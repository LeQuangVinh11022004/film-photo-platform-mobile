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
  static final _DevFriendlyCacheManager _instance = _DevFriendlyCacheManager._();

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

  String _resolveUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/data/') || trimmed.startsWith('/storage/')) {
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
    final resolved = _resolveUrl(url);
    Widget imageWidget;

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: resolved,
        cacheManager: kDebugMode ? _DevFriendlyCacheManager() : DefaultCacheManager(),
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => Container(
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
        errorWidget: (context, _, error) {
          if (kDebugMode) {
            debugPrint('SafeNetworkImage error ($resolved): $error');
          }
          return _buildErrorPlaceholder();
        },
      );
    } else if (resolved.isNotEmpty) {
      imageWidget = Image.file(
        File(resolved),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            debugPrint('SafeNetworkImage local file error ($resolved): $error');
          }
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