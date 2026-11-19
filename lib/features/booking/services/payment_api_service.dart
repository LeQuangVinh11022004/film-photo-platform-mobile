import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class PaymentApiService {
  static final PaymentApiService _instance = PaymentApiService._internal();
  factory PaymentApiService() => _instance;
  PaymentApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// 1. Gọi BE để tạo URL thanh toán VNPay hoặc MoMo
  Future<String?> createPaymentUrl({
    required String bookingId,
    required double amount,
    required String paymentMethod, // 'vnpay' hoặc 'momo'
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/payments/$paymentMethod/create',
        body: {
          'bookingId': bookingId,
          'amount': amount,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['paymentUrl'] ?? data['url'];
      }
    } catch (e) {
      if (kDebugMode) print('createPaymentUrl error: $e');
    }
    return null;
  }

  /// 2. Xác thực kết quả VNPay qua API GET /api/payments/vnpay/return
  Future<Map<String, dynamic>> verifyVnpayReturn(Map<String, String> queryParams) async {
    try {
      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiClient.get('/api/payments/vnpay/return?$queryString');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Giao dịch VNPay thành công!'};
      } else {
        return {
          'success': false,
          'message': 'Xác thực VNPay thất bại (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối verify VNPay: $e'};
    }
  }

  /// 3. Xác thực kết quả MoMo qua API GET /api/payments/momo/return
  Future<Map<String, dynamic>> verifyMomoReturn(Map<String, String> queryParams) async {
    try {
      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiClient.get('/api/payments/momo/return?$queryString');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Giao dịch MoMo thành công!'};
      } else {
        return {
          'success': false,
          'message': 'Xác thực MoMo thất bại (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối verify MoMo: $e'};
    }
  }
}