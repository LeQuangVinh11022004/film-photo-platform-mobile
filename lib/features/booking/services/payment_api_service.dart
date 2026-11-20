import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/booking_api_models.dart';
import 'booking_api_service.dart';

void _paymentApiLog(String message) {
  if (kDebugMode) {
    debugPrint('[PAYMENT_API] $message');
  }
}

class PaymentConfirmationResult {
  final bool isConfirmed;
  final String status;
  final String message;
  final String? transactionId;

  const PaymentConfirmationResult({
    required this.isConfirmed,
    required this.status,
    required this.message,
    this.transactionId,
  });

  factory PaymentConfirmationResult.fromJson(Map<String, dynamic> json) {
    _paymentApiLog('PaymentConfirmationResult.fromJson raw: $json');
    final rawStatus = (json['status'] ?? '').toString().trim();
    final rawMessage = (json['message'] ?? '').toString().trim();
    final rawTxId = json['transactionId']?.toString().trim();

    final normalizedStatus = rawStatus.toLowerCase();
    final confirmed = normalizedStatus == 'confirmed' ||
        normalizedStatus == 'paid' ||
        normalizedStatus == 'success' ||
        normalizedStatus == 'completed';

    final res = PaymentConfirmationResult(
      isConfirmed: confirmed,
      status: rawStatus.isEmpty ? (confirmed ? 'Confirmed' : 'Pending') : rawStatus,
      message: rawMessage.isEmpty
          ? (confirmed ? 'Thanh toán thành công.' : 'Giao dịch chưa được xác nhận.')
          : rawMessage,
      transactionId: (rawTxId != null && rawTxId.isNotEmpty) ? rawTxId : null,
    );
    _paymentApiLog(
      'PaymentConfirmationResult parsed -> isConfirmed=${res.isConfirmed}, '
          'status=${res.status}, message=${res.message}, transactionId=${res.transactionId}',
    );
    return res;
  }
}

class PaymentApiService {
  static final PaymentApiService _instance = PaymentApiService._internal();
  factory PaymentApiService() => _instance;
  PaymentApiService._internal();

  final BookingApiService _bookingApiService = BookingApiService();

  /// Khởi tạo giao dịch đặt cọc và lấy `paymentUrl` từ BE
  Future<Map<String, dynamic>> initiateDepositPayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    _paymentApiLog(
      'initiateDepositPayment start | bookingId=$bookingId | paymentMethod=$paymentMethod',
    );
    try {
      final result = await _bookingApiService.payDeposit(
        bookingId: bookingId,
        paymentMethod: paymentMethod,
      );
      _paymentApiLog('payDeposit raw response: $result');

      if (result['success'] != true) {
        final msg = result['message'] ?? 'Không thể khởi tạo thanh toán';
        _paymentApiLog('initiateDepositPayment failed: $msg');
        return {
          'success': false,
          'message': msg,
        };
      }

      final DepositPaymentResponseDTO? dto =
      result['data'] as DepositPaymentResponseDTO?;
      final paymentUrl = dto?.paymentUrl?.trim();
      _paymentApiLog('initiateDepositPayment dto=$dto | paymentUrl=$paymentUrl');

      if (paymentUrl == null || paymentUrl.isEmpty) {
        _paymentApiLog('initiateDepositPayment error: paymentUrl is null or empty');
        return {
          'success': false,
          'message': 'Backend không trả về paymentUrl hợp lệ.',
          'data': dto,
        };
      }

      return {
        'success': true,
        'paymentUrl': paymentUrl,
        'data': dto,
      };
    } catch (e, stackTrace) {
      _paymentApiLog('initiateDepositPayment exception: $e\n$stackTrace');
      return {
        'success': false,
        'message': 'Lỗi khi khởi tạo thanh toán: $e',
      };
    }
  }

  /// Gọi callback/return URL (nếu URL trả về là endpoint JSON của BE) để lấy status, message, transactionId
  Future<PaymentConfirmationResult?> verifyReturnEndpoint(Uri returnUri) async {
    _paymentApiLog('verifyReturnEndpoint GET: $returnUri');
    try {
      final response = await http.get(returnUri);
      _paymentApiLog(
        'verifyReturnEndpoint response | statusCode=${response.statusCode} | '
            'body=${response.body}',
      );
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PaymentConfirmationResult.fromJson(decoded);
        } else {
          _paymentApiLog('verifyReturnEndpoint body is not a JSON object: ${decoded.runtimeType}');
        }
      }
    } catch (e, stackTrace) {
      _paymentApiLog('verifyReturnEndpoint error: $e\n$stackTrace');
    }
    return null;
  }

  /// Helper parse nhanh chuỗi JSON trả về trực tiếp từ web/callback
  PaymentConfirmationResult parsePaymentJson(String rawJson) {
    _paymentApiLog('parsePaymentJson input: $rawJson');
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return PaymentConfirmationResult.fromJson(decoded);
  }

  /// Fallback kiểm tra trạng thái booking từ BE
  Future<BookingResponseDTO?> refreshBookingStatus(String bookingId) async {
    _paymentApiLog('refreshBookingStatus start | bookingId=$bookingId');
    try {
      final dto = await _bookingApiService.getBookingDetail(bookingId);
      _paymentApiLog(
        'refreshBookingStatus result | bookingId=${dto?.bookingId} | status=${dto?.status} | '
            'depositStatus=${dto?.depositStatus}',
      );
      return dto;
    } catch (e, stackTrace) {
      _paymentApiLog('refreshBookingStatus error: $e\n$stackTrace');
      rethrow;
    }
  }
}