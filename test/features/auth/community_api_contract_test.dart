import 'dart:convert';
import 'dart:io';

import 'package:film_photography_platform/core/network/api_client.dart';
import 'package:film_photography_platform/features/auth/models/auth_models.dart';
import 'package:film_photography_platform/features/auth/services/auth_service.dart';
import 'package:film_photography_platform/features/community/models/community_post_api_models.dart';
import 'package:film_photography_platform/features/community/services/community_post_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late HttpServer server;
  late String originalBaseUrl;
  final requests = <({String method, String path, Map<String, dynamic> body})>[];
  var failUpdates = false;
  var failLogin = false;
  var emptyPostResponse = false;
  const postId = '12345678-1234-1234-1234-123456789abc';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    originalBaseUrl = ApiClient().baseUrl;
    ApiClient().baseUrl = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      requests.add((
        method: request.method,
        path: request.uri.path,
        body: raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw),
      ));
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/auth/login' && failLogin) {
        request.response.statusCode = 401;
        request.response.write(jsonEncode({'message': 'Invalid credentials'}));
      } else if (request.uri.path == '/api/auth/login') {
        request.response.write(jsonEncode({
          'success': true,
          'message': 'ok',
          'token': 'test-token',
          'user': {
            'userId': 'user-id',
            'fullName': 'User',
            'username': 'film_user',
            'email': 'film@example.test',
            'role': 'EXPERT',
            'status': 'Active',
          },
        }));
      } else if (request.uri.path == '/api/auth/register/photographer') {
        request.response.statusCode = 201;
        request.response.write(jsonEncode({'username': 'film_user'}));
      } else if (request.uri.path == '/api/community/posts/$postId' &&
          request.method == 'PUT' &&
          failUpdates) {
        request.response.statusCode = 500;
        request.response.write(jsonEncode({'message': 'update failed'}));
      } else if (emptyPostResponse && request.method == 'POST') {
        request.response.statusCode = 201;
      } else {
        final post = {
          'postId': postId,
          'userId': 'user-id',
          'authorName': 'User',
          'authorRole': 'EXPERT',
          'title': 'Test post',
          'content': 'Content',
          'status': 'PUBLISHED',
          'createdAt': '2026-01-01T00:00:00Z',
          'images': [],
        };
        if (request.method == 'GET') {
          request.response.write(jsonEncode({
            'items': [post],
            'totalItems': 1,
            'page': 1,
            'pageSize': 20,
          }));
        } else {
          request.response.statusCode = request.method == 'POST' ? 201 : 200;
          request.response.write(jsonEncode(post));
        }
      }
      await request.response.close();
    });
  });

  tearDownAll(() async {
    await AuthService().logout();
    ApiClient().baseUrl = originalBaseUrl;
    await server.close(force: true);
  });

  setUp(() {
    requests.clear();
    failUpdates = false;
    failLogin = false;
    emptyPostResponse = false;
  });

  test('login failure does not create an offline session', () async {
    await AuthService().logout();
    failLogin = true;
    final response = await AuthService().login('film_user', 'wrongpass');
    expect(response.success, isFalse);
    expect(AuthService().currentUser, isNull);
    expect(ApiClient().authToken, isNull);
  });

  test('legacy offline token does not restore an authenticated session', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_jwt_token_123',
      'current_user': '{}',
    });
    expect(await AuthService().tryAutoLogin(), isFalse);
    expect(ApiClient().authToken, isNull);
    expect(AuthService().currentUser, isNull);
  });

  test('login and registration send username and preserve returned username',
      () async {
    final login = await AuthService().login('film_user', 'password');
    expect(login.success, isTrue);
    expect(requests.single.body, {'username': 'film_user', 'password': 'password'});
    expect(login.user?.username, 'film_user');
    expect(UserDTO.fromJson(login.user!.toJson()).username, 'film_user');

    final registration = await AuthService().register(
      name: 'User',
      username: 'film_user',
      email: 'film@example.test',
      password: 'password',
    );
    expect(registration.success, isTrue);
    expect(requests.last.body, {
      'fullName': 'User',
      'username': 'film_user',
      'email': 'film@example.test',
      'password': 'password',
    });
    expect(validateUsername('film_user'), isNull);
    expect(validateUsername('email@example.test'), isNotNull);
    expect(validateUsername('ab'), isNotNull);
    expect(validateUsername('a' * 51), isNotNull);
  });

  test('community feed and post creation use community API', () async {
    final service = CommunityPostApiService();
    final feed = await service.getFeed();
    final mine = await service.getMyPosts();
    expect(feed?.items.single.toBlogPost().authorRole, contains('Chuyên gia'));
    expect(mine?.totalCount, 1);
    final result = await service.createPost(
      const CommunityPostWriteRequestDTO(
        title: 'Test post',
        content: 'Content',
        images: [CommunityPostImageWriteRequestDTO(imageUrl: 'https://example.test/a.jpg')],
      ),
    );
    expect(result['success'], isTrue);
    expect(requests.map((request) => request.path), [
      '/api/community/posts',
      '/api/community/posts/mine',
      '/api/community/posts',
    ]);
    expect(requests.last.body['images'], [
      {'imageUrl': 'https://example.test/a.jpg', 'displayOrder': 0},
    ]);
  });

  test('failed post update does not retry by deleting images', () async {
    failUpdates = true;
    final result = await CommunityPostApiService().updatePost(
      postId: postId,
      request: const CommunityPostWriteRequestDTO(
        title: 'Test post',
        content: 'Content',
        images: [CommunityPostImageWriteRequestDTO(imageUrl: 'https://example.test/a.jpg')],
      ),
    );
    expect(result['success'], isFalse);
    expect(requests, hasLength(1));
    expect(requests.single.body['images'], isNotEmpty);
  });

  test('post creation requires a returned post', () async {
    emptyPostResponse = true;
    final result = await CommunityPostApiService().createPost(
      const CommunityPostWriteRequestDTO(title: 'Title', content: 'Content'),
    );
    expect(result['success'], isFalse);
  });

}
