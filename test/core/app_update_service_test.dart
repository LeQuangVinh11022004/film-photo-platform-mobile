import 'dart:convert';
import 'package:film_photography_platform/core/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('compareVersions compares semantic version strings accurately', () {
    expect(AppUpdateService.compareVersions('1.0.19', '1.0.18'), greaterThan(0));
    expect(AppUpdateService.compareVersions('v1.1.0', '1.0.99'), greaterThan(0));
    expect(AppUpdateService.compareVersions('1.0.19', 'v1.0.19'), equals(0));
    expect(AppUpdateService.compareVersions('1.0.18', '1.0.19'), lessThan(0));
  });

  test('checkForUpdate returns AppUpdateInfo with APK URL when newer release exists', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'tag_name': 'v1.0.19',
          'name': 'Release v1.0.19',
          'body': 'Toi uu hieu nang va cap nhat API.',
          'html_url': 'https://github.com/LeQuangVinh11022004/film-photo-platform-mobile/releases/tag/v1.0.19',
          'assets': [
            {
              'name': 'app-release.apk',
              'browser_download_url':
                  'https://github.com/LeQuangVinh11022004/film-photo-platform-mobile/releases/download/v1.0.19/app-release.apk',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final info = await AppUpdateService().checkForUpdate(
      client: mockClient,
      currentVersionOverride: '1.0.18',
    );
    expect(info, isNotNull);
    expect(info!.latestVersion, '1.0.19');
    expect(info.downloadUrl, endsWith('app-release.apk'));

    final upToDate = await AppUpdateService().checkForUpdate(
      client: mockClient,
      currentVersionOverride: '1.0.19',
    );
    expect(upToDate, isNull);
  });
}
