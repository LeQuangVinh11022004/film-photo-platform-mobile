import 'dart:convert';
import 'dart:async';
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

  /// Khởi tạo giao dịch đặt cọc qua POST /api/photographer/bookings/{bookingId}/deposit-payment
  Future<Map<String, dynamic>> initiateDepositPayment({
    required String bookingId,
    String paymentMethod = 'VNPAY',
  }) async {
    final normalizedMethod = paymentMethod.trim().toUpperCase();
    _paymentApiLog(
      'initiateDepositPayment start | bookingId=$bookingId | paymentMethod=$normalizedMethod',
    );

    if (normalizedMethod != 'VNPAY') {
      return {
        'success': false,
        'message': 'Hiện tại hệ thống chỉ hỗ trợ thanh toán qua VNPAY.',
      };
    }

    try {
      final result = await _bookingApiService.payDeposit(
        bookingId: bookingId,
        paymentMethod: normalizedMethod,
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

  /// Chỉ gọi khi URL redirect trả về endpoint JSON hợp lệ của BE (không gọi với tham số tự tạo)
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
        }
      }
    } catch (e, stackTrace) {
      _paymentApiLog('verifyReturnEndpoint error: $e\n$stackTrace');
    }
    return null;
  }

  PaymentConfirmationResult parsePaymentJson(String rawJson) {
    _paymentApiLog('parsePaymentJson input: $rawJson');
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return PaymentConfirmationResult.fromJson(decoded);
  }

  /// Kiểm tra lại trạng thái booking từ GET /api/photographer/bookings/{bookingId}
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

  /// Khởi tạo giao dịch mua Gói Dịch Vụ qua POST /api/photographer/service-packages/{packageId}/purchase
  Future<Map<String, dynamic>> initiatePackagePurchasePayment({
    required String packageId,
  }) async {
    _paymentApiLog('initiatePackagePurchasePayment start | packageId=$packageId');
    try {
      final result = await _bookingApiService.purchaseServicePackage(packageId);
      _paymentApiLog('purchaseServicePackage raw response: $result');

      if (result['success'] != true) {
        final msg = result['message'] ?? 'Không thể khởi tạo thanh toán gói dịch vụ.';
        return {
          'success': false,
          'message': msg,
        };
      }

      final PackagePurchasePaymentResponseDTO? dto =
          result['data'] as PackagePurchasePaymentResponseDTO?;
      final paymentUrl = dto?.paymentUrl.trim();

      if (paymentUrl == null || paymentUrl.isEmpty) {
        return {
          'success': false,
          'message': 'Backend không trả về paymentUrl hợp lệ cho gói dịch vụ.',
          'data': dto,
        };
      }

      return {
        'success': true,
        'paymentUrl': paymentUrl,
        'data': dto,
      };
    } catch (e, stackTrace) {
      _paymentApiLog('initiatePackagePurchasePayment exception: $e\n$stackTrace');
      return {
        'success': false,
        'message': 'Lỗi khi khởi tạo mua gói dịch vụ: $e',
      };
    }
  }

  /// Kiểm tra lại trạng thái gói đăng ký sau khi thanh toán VNPay
  Future<PhotographerPackageSubscriptionResponseDTO?> refreshPackageSubscriptionStatus(
      String packageId) async {
    _paymentApiLog('refreshPackageSubscriptionStatus start | packageId=$packageId');
    try {
      final subs = await _bookingApiService.getPackageSubscriptions();
      for (final sub in subs) {
        if (sub.packageId.toLowerCase() == packageId.toLowerCase() &&
            sub.status.toUpperCase() == 'ACTIVE') {
          return sub;
        }
      }
      return null;
    } catch (e, stackTrace) {
      _paymentApiLog('refreshPackageSubscriptionStatus error: $e\n$stackTrace');
      return null;
    }
  }
}