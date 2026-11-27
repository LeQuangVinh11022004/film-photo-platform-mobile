import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

void main() async {
  // Config
  const String baseUrl = 'https://filmbooking-api-h7bghwcydwb8eecn.japaneast-01.azurewebsites.net';
  
  // Accept self-signed certificates
  final HttpClient httpClient = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  final client = IOClient(httpClient);
  
  String? token;
  
  print('=============================================');
  print('TESTING ALL APIS - FILM PHOTOGRAPHY PLATFORM');
  print('=============================================\n');

  // 1. Test Login API
  print('[1] POST /api/auth/login');
  try {
    final loginRes = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'photographer.demo@filmbooking.local',
        'password': 'FilmDemo2026!'
      }),
    );
    print('  -> Status: ${loginRes.statusCode}');
    if (loginRes.statusCode == 200) {
      final data = jsonDecode(loginRes.body);
      token = data['token'];
      print('  -> Success! Got token.');
    } else {
      print('  -> Error: ${loginRes.body}');
    }
  } catch (e) {
    print('  -> Exception: $e');
  }
  
  print('\n---------------------------------------------\n');

  // Headers for authenticated requests
  final authHeaders = {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // 2. Test Get Studios
  print('[2] GET /api/photographer/studios');
  try {
    final res = await client.get(
      Uri.parse('$baseUrl/api/photographer/studios?page=1&pageSize=5'),
      headers: authHeaders,
    );
    print('  -> Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('  -> Success! Data length: ${res.body.length} bytes');
    } else {
      print('  -> Error: ${res.body}');
    }
  } catch (e) {
    print('  -> Exception: $e');
  }

  print('\n---------------------------------------------\n');

  // 3. Test Get Darkrooms
  print('[3] GET /api/photographer/darkrooms');
  try {
    final res = await client.get(
      Uri.parse('$baseUrl/api/photographer/darkrooms?page=1&pageSize=5'),
      headers: authHeaders,
    );
    print('  -> Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('  -> Success! Data length: ${res.body.length} bytes');
    } else {
      print('  -> Error: ${res.body}');
    }
  } catch (e) {
    print('  -> Exception: $e');
  }

  print('\n---------------------------------------------\n');

  // 4. Test Get My Bookings
  print('[4] GET /api/photographer/bookings');
  try {
    final res = await client.get(
      Uri.parse('$baseUrl/api/photographer/bookings?page=1&pageSize=5'),
      headers: authHeaders,
    );
    print('  -> Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('  -> Success! Data length: ${res.body.length} bytes');
    } else {
      print('  -> Error: ${res.body}');
    }
  } catch (e) {
    print('  -> Exception: $e');
  }

  print('\n---------------------------------------------\n');

  // 5. Test AI Guide API
  print('[5] POST /api/ai/photography-guide');
  try {
    final res = await client.post(
      Uri.parse('$baseUrl/api/ai/photography-guide'),
      headers: authHeaders,
      body: jsonEncode({
        "theme": "Chân dung vintage",
        "location": "Studio",
        "availableLight": "Ánh sáng cửa sổ chiều",
        "equipment": "Máy film 35mm, lens 50mm",
        "experienceLevel": "Beginner"
      }),
    );
    print('  -> Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('  -> Success!');
      final data = jsonDecode(res.body);
      print('  -> AI Response preview: ${data.toString().length > 100 ? data.toString().substring(0, 100) + '...' : data}');
    } else {
      print('  -> Error: ${res.body}');
    }
  } catch (e) {
    print('  -> Exception: $e');
  }

  print('\n=============================================');
  print('TESTING COMPLETE');
  print('=============================================');
}
