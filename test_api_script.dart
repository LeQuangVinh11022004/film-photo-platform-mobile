import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://localhost:7104/api/auth/login');
  final body = jsonEncode({
    'email': 'photographer.demo@filmbooking.local',
    'password': 'FilmDemo2026!'
  });

  print('Testing Login API: $url');
  
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e) {
    print('Error calling API: $e');
  }
}
