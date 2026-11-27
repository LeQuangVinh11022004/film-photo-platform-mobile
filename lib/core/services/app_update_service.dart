import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
  });
}

/// Service kiểm tra phiên bản mới từ GitHub Releases và hiển thị hộp thoại tải APK cập nhật.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Phiên bản ứng dụng hiện tại (được truyền tự động từ GitHub Actions qua --dart-define=APP_VERSION=...)
  static const String currentAppVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String _githubOwner = 'LeQuangVinh11022004';
  static const String _githubRepo = 'film-photo-platform-mobile';

  static Uri get latestReleaseApiUri => Uri.parse(
        'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
      );

  bool _hasCheckedThisSession = false;

  /// So sánh 2 chuỗi semantic version (VD: "1.0.19" > "1.0.18").
  /// Trả về > 0 nếu [latest] mới hơn [current].
  static int compareVersions(String latest, String current) {
    List<int> parse(String raw) {
      final cleaned = raw.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first.split('-').first;
      return cleaned
          .split('.')
          .map((part) => int.tryParse(part.trim()) ?? 0)
          .toList();
    }

    final a = parse(latest);
    final b = parse(current);
    final maxLen = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < maxLen; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  /// Kiểm tra bản phát hành mới nhất từ GitHub Releases API.
  Future<AppUpdateInfo?> checkForUpdate({
    http.Client? client,
    String? currentVersionOverride,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;
    try {
      final response = await httpClient.get(
        latestReleaseApiUri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) return null;

      final rawTag = (json['tag_name'] ?? '').toString().trim();
      if (rawTag.isEmpty) return null;

      final latestVersion = rawTag.replaceFirst(RegExp(r'^[vV]'), '');
      final currentVersion = (currentVersionOverride ?? currentAppVersion)
          .trim()
          .replaceFirst(RegExp(r'^[vV]'), '');

      if (compareVersions(latestVersion, currentVersion) <= 0) {
        return null;
      }

      String downloadUrl = '';
      final assets = json['assets'];
      if (assets is List) {
        for (final item in assets) {
          if (item is Map<String, dynamic>) {
            final name = (item['name'] ?? '').toString().toLowerCase();
            final url = (item['browser_download_url'] ?? '').toString().trim();
            if (name.endsWith('.apk') && url.isNotEmpty) {
              downloadUrl = url;
              break;
            }
          }
        }
      }

      final releasePageUrl = (json['html_url'] ??
              'https://github.com/$_githubOwner/$_githubRepo/releases/latest')
          .toString()
          .trim();

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseTitle: (json['name'] ?? 'Phiên bản v$latestVersion').toString().trim(),
        releaseNotes: (json['body'] ?? '').toString().trim(),
        downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : releasePageUrl,
        releasePageUrl: releasePageUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[APP_UPDATE] Check failed: $e');
      }
      return null;
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }
  }

  /// Tự động kiểm tra (mỗi phiên chạy 1 lần) và hiển thị popup cập nhật nếu có bản mới.
  /// Truyền [force] = true khi người dùng bấm "Kiểm tra cập nhật" thủ công trong Cài đặt.
  Future<void> checkAndPromptUpdate(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!force && _hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    final updateInfo = await checkForUpdate();
    if (!context.mounted) return;

    if (updateInfo == null) {
      if (force) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bạn đang dùng phiên bản mới nhất (v$currentAppVersion).',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    await _showUpdateDialog(context, updateInfo);
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo info,
  ) async {
    final notesPreview = info.releaseNotes.isEmpty
        ? 'Cải thiện hiệu năng, sửa lỗi và đồng bộ API mới nhất.'
        : (info.releaseNotes.length > 350
            ? '${info.releaseNotes.substring(0, 350)}...'
            : info.releaseNotes);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Có phiên bản mới!',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'v${info.currentVersion} → v${info.latestVersion}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notesPreview,
                style: const TextStyle(fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sau khi tải xong file APK, bấm mở file và chọn "Cập nhật" để cài đè giữ nguyên tài khoản & dữ liệu.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Để sau'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final uri = Uri.tryParse(info.downloadUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'Tải & Cập nhật',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
