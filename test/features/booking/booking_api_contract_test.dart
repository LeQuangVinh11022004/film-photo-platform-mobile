import 'dart:convert';
import 'dart:io';

import 'package:film_photography_platform/core/network/api_client.dart';
import 'package:film_photography_platform/features/ai_tools/services/ai_api_service.dart';
import 'package:film_photography_platform/features/booking/models/booking_api_models.dart';
import 'package:film_photography_platform/features/booking/models/review_api_models.dart';
import 'package:film_photography_platform/features/booking/services/booking_api_service.dart';
import 'package:film_photography_platform/features/booking/services/payment_api_service.dart';
import 'package:film_photography_platform/features/booking/services/review_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late String originalBaseUrl;
  final paths = <String>[];
  var statusCode = 200;
  Object responseBody = {};

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    originalBaseUrl = ApiClient().baseUrl;
    ApiClient().baseUrl = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      paths.add(request.uri.path);
      await request.drain<void>();
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(responseBody));
      await request.response.close();
    });
  });

  setUp(() {
    paths.clear();
    statusCode = 200;
    responseBody = {};
  });

  tearDownAll(() async {
    ApiClient().baseUrl = originalBaseUrl;
    await server.close(force: true);
  });

  test('cancellation accepts backend refund response and surfaces errors',
      () async {
    responseBody = {
      'bookingId': 'booking-id',
      'status': 'CANCELLED',
      'refundAmount': 150000,
      'refundStatus': 'PENDING_MANUAL',
      'packageUseRestored': false,
    };
    final success = await BookingApiService().cancelBooking('booking-id');
    expect(success['success'], isTrue);
    final cancellation = success['cancellation'] as BookingCancellationResponseDTO;
    expect(cancellation.refundAmount, 150000);
    expect(cancellation.refundStatus, 'PENDING_MANUAL');

    responseBody = {'bookingId': 'booking-id', 'status': 'CANCELLED'};
    final incomplete = await BookingApiService().cancelBooking('booking-id');
    expect(incomplete['success'], isFalse);

    statusCode = 409;
    responseBody = {'message': 'Cannot cancel'};
    final failure = await BookingApiService().cancelBooking('booking-id');
    expect(failure['success'], isFalse);
    expect(failure['message'], 'Cannot cancel');
  });

  test('review failures and missing review ID never report success', () async {
    const request = SpaceReviewWriteRequestDTO(
      spaceType: 'STUDIO',
      spaceId: 'space-id',
      rating: 5,
    );
    for (final code in [409, 500, 201]) {
      statusCode = code;
      responseBody = {'message': 'Rejected'};
      final result = await ReviewApiService().createBookingReview(
        bookingId: 'booking-id',
        request: request,
      );
      expect(result['success'], isFalse, reason: 'HTTP $code');
    }
  });

  test('availability preserves absent price and explicit zero', () {
    expect(ProviderSpaceAvailabilityResponseDTO.fromJson({}).price, isNull);
    expect(ProviderSpaceAvailabilityResponseDTO.fromJson({'price': 0}).price, 0);
  });

  test('AI photography guide renders structured backend response', () {
    final result = formatPhotographyGuide({
      'concept': 'Chân dung',
      'compositionTips': ['Quy tắc một phần ba'],
      'lightingSetup': ['Ánh sáng cửa sổ'],
      'cameraSettings': {'aperture': 'f/2', 'shutterSpeed': '1/125', 'iso': '400'},
      'shotList': ['Toàn cảnh'],
      'safetyNote': 'Bảo vệ thiết bị',
    });
    expect(result, contains('Ý tưởng\nChân dung'));
    expect(result, contains('• Quy tắc một phần ba'));
    expect(result, contains('Khẩu độ: f/2'));
    expect(result, contains('ISO: 400'));
    expect(result, contains('Lưu ý an toàn\nBảo vệ thiết bị'));
  });

  test('pending VNPay return remains pending and does not call IPN', () async {
    responseBody = {'status': 'Pending', 'message': 'Browser return is valid'};
    final result = await PaymentApiService().verifyReturnEndpoint(Uri.parse(
      '${ApiClient().baseUrl}/api/payments/vnpay/return?vnp_ResponseCode=00&vnp_SecureHash=abc',
    ));
    expect(result?.isConfirmed, isFalse);
    expect(paths, ['/api/payments/vnpay/return']);
    expect(
      PaymentConfirmationResult.fromJson({'status': 'Confirmed'}).isConfirmed,
      isTrue,
    );
  });

  test('subscription confirmation matches purchase order, not package', () async {
    responseBody = [
      {
        'subscriptionId': 'old',
        'packageId': 'package',
        'purchaseOrderId': 'old-order',
        'status': 'ACTIVE',
      },
    ];
    expect(
      await PaymentApiService().refreshPackageSubscriptionStatus('new-order'),
      isNull,
    );
    (responseBody as List).add({
      'subscriptionId': 'new',
      'packageId': 'package',
      'purchaseOrderId': 'new-order',
      'status': 'ACTIVE',
    });
    final match = await PaymentApiService()
        .refreshPackageSubscriptionStatus('new-order');
    expect(match?.subscriptionId, 'new');
  });

  test('package and subscription failures are not empty successful lists',
      () async {
    statusCode = 500;
    await expectLater(
      BookingApiService().getServicePackages(),
      throwsStateError,
    );
    await expectLater(
      BookingApiService().getPackageSubscriptions(),
      throwsStateError,
    );
    statusCode = 200;
    responseBody = {'unexpected': 'shape'};
    await expectLater(
      BookingApiService().getServicePackages(),
      throwsFormatException,
    );
    responseBody = [];
    expect(await BookingApiService().getServicePackages(), isEmpty);
  });
}
