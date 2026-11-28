import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/payment_api_service.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_order_summary_card.dart';
import '../widgets/payment_success_dialog.dart';
import '../widgets/payment_webview_page.dart';

void _paymentLog(String message) {
  if (kDebugMode) {
    debugPrint('[PAYMENT_DEBUG] $message');
  }
}

class PaymentScreen extends StatefulWidget {
  final String? bookingId;
  final String? packageId;
  final String? customItemName;
  final BookingItem? item;
  final double? totalAmount;
  final DateTime? bookingDate;
  final String? timeSlot;

  /// Mặc định mở trong WebView nội bộ để bắt kết quả và tự đóng về app.
  final bool openInAppWebView;

  const PaymentScreen({
    super.key,
    this.bookingId,
    this.packageId,
    this.customItemName,
    this.item,
    this.totalAmount,
    this.bookingDate,
    this.timeSlot,
    this.openInAppWebView = true,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  // Hiện tại Backend chỉ hỗ trợ VNPAY (index 0)
  int _selectedPaymentMethod = 0;
  bool _isProcessing = false;
  bool _awaitingExternalReturn = false;
  bool _hasHandledConfirmation = false;

  String? _transactionId;
  String? _purchaseOrderId;
  String? _confirmationMessage;

  late final double _amount;
  late final String _itemName;
  late final String _bookingId;
  late final String _packageId;
  late final bool _isPackagePurchase;
  late final String _timeSlot;
  late final String _dateString;

  final PaymentApiService _paymentService = PaymentApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _amount = widget.totalAmount ?? 700000.0;
    _itemName = widget.customItemName ??
        widget.item?.name ??
        'Vintage Film Studio Saigon';
    _bookingId = widget.bookingId ?? '';
    _packageId = widget.packageId ?? '';
    _isPackagePurchase = _packageId.isNotEmpty && _bookingId.isEmpty;
    _timeSlot = widget.timeSlot ?? '3 giờ (09:00 - 12:00)';
    _dateString = widget.bookingDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.bookingDate!)
        : DateFormat('dd/MM/yyyy')
            .format(DateTime.now().add(const Duration(days: 1)));

    _paymentLog(
      'PaymentScreen.initState | bookingId=$_bookingId | packageId=$_packageId | '
      'isPackagePurchase=$_isPackagePurchase | amount=$_amount | '
      'itemName=$_itemName | date=$_dateString | timeSlot=$_timeSlot | '
      'openInAppWebView=${widget.openInAppWebView}',
    );
  }

  @override
  void dispose() {
    _paymentLog('PaymentScreen.dispose | bookingId=$_bookingId');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _paymentLog(
      'didChangeAppLifecycleState | state=$state | '
      'awaitingExternalReturn=$_awaitingExternalReturn | '
      'hasHandledConfirmation=$_hasHandledConfirmation',
    );
    if (state == AppLifecycleState.resumed &&
        _awaitingExternalReturn &&
        !_hasHandledConfirmation) {
      _handleResumeFromExternalBrowser();
    }
  }

  String? _resolveBackendPaymentMethod(int index) {
    switch (index) {
      case 0:
        return 'VNPAY';
      default:
        return null;
    }
  }

  Future<void> _handlePayment() async {
    _paymentLog('Start Of Payment Process=============================');
    if (_hasHandledConfirmation) return;

    if (!_isPackagePurchase && _bookingId.isEmpty) {
      _paymentLog('_handlePayment error: _bookingId and _packageId are empty');
      _showErrorToast(
        'Thiếu mã booking hoặc mã gói dịch vụ hợp lệ để thực hiện thanh toán.',
      );
      return;
    }

    final methodCode = _resolveBackendPaymentMethod(_selectedPaymentMethod);
    if (methodCode == null) {
      _showErrorToast('Hiện tại chỉ hỗ trợ thanh toán qua VNPay.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final Map<String, dynamic> initResult;
      if (_isPackagePurchase) {
        initResult = await _paymentService.initiatePackagePurchasePayment(
          packageId: _packageId,
        );
        _paymentLog('initiatePackagePurchasePayment result: $initResult');
      } else {
        initResult = await _paymentService.initiateDepositPayment(
          bookingId: _bookingId,
          paymentMethod: methodCode,
        );
        _paymentLog('initiateDepositPayment result: $initResult');
      }

      if (!mounted) return;

      if (initResult['success'] != true) {
        setState(() => _isProcessing = false);
        final errMsg = initResult['message'] ?? 'Khởi tạo thanh toán thất bại.';
        _showErrorToast(errMsg);
        return;
      }

      if (_isPackagePurchase) {
        final data = initResult['data'] as PackagePurchasePaymentResponseDTO?;
        if (data == null || data.orderId.isEmpty) {
          setState(() => _isProcessing = false);
          _showErrorToast('Backend không trả về mã đơn mua gói hợp lệ.');
          return;
        }
        _purchaseOrderId = data.orderId;
      }

      final String paymentUrl = initResult['paymentUrl'] as String;
      final uri = Uri.tryParse(paymentUrl);

      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        setState(() => _isProcessing = false);
        _showErrorToast('URL thanh toán từ Backend không hợp lệ: $paymentUrl');
        return;
      }

      if (widget.openInAppWebView) {
        await _openWithWebView(uri);
      } else {
        await _openWithExternalLauncher(uri);
      }
    } catch (e, stackTrace) {
      _paymentLog('_handlePayment exception: $e\n$stackTrace');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorToast('Đã xảy ra lỗi trong quá trình thanh toán: $e');
    }
  }

  Future<void> _openWithWebView(Uri paymentUri) async {
    final PaymentConfirmationResult? result =
        await Navigator.push<PaymentConfirmationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewPage(
          initialUri: paymentUri,
          paymentService: _paymentService,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    _paymentLog('VNPay return status: ${result?.status ?? "unknown"}');
    await _checkBookingFallback(showPendingToastIfNotPaid: true);
  }

  Future<void> _openWithExternalLauncher(Uri paymentUri) async {
    final launched = await launchUrl(
      paymentUri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!launched) {
      setState(() => _isProcessing = false);
      _showErrorToast('Không thể mở liên kết thanh toán.');
      return;
    }

    _awaitingExternalReturn = true;
    setState(() => _isProcessing = false);
  }

  Future<void> _handleResumeFromExternalBrowser() async {
    _awaitingExternalReturn = false;
    if (!mounted || _hasHandledConfirmation) return;

    setState(() => _isProcessing = true);

    try {
      await _checkBookingFallback(showPendingToastIfNotPaid: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _checkBookingFallback({
    bool showPendingToastIfNotPaid = false,
  }) async {
    if (_hasHandledConfirmation) return;

    if (_isPackagePurchase) {
      if (_purchaseOrderId == null || _purchaseOrderId!.isEmpty) return;
      final activeSub = await _paymentService
          .refreshPackageSubscriptionStatus(_purchaseOrderId!);
      if (!mounted || _hasHandledConfirmation) return;
      if (activeSub != null) {
        _onPaymentConfirmed(
          PaymentConfirmationResult(
            isConfirmed: true,
            status: activeSub.status,
            message:
                'Đăng ký gói dịch vụ "${activeSub.packageName}" thành công!',
            transactionId: activeSub.subscriptionId,
          ),
        );
      } else if (showPendingToastIfNotPaid) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          title: const Text('Đang chờ xác nhận thanh toán gói'),
          description: const Text(
            'Nếu bạn đã hoàn tất trên cổng thanh toán VNPay, vui lòng kiểm tra lại trong tab Gói Đã Đăng Ký.',
          ),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
          showProgressBar: false,
        );
      }
      return;
    }

    if (_bookingId.isEmpty) return;

    final updatedBooking =
        await _paymentService.refreshBookingStatus(_bookingId);
    if (!mounted || _hasHandledConfirmation) return;

    final depositStatus = updatedBooking?.depositStatus.toUpperCase() ?? '';
    final bookingStatus = updatedBooking?.status.toUpperCase() ?? '';
    final isPaid = depositStatus == 'SUCCESS' &&
        (bookingStatus == 'CONFIRMED' || bookingStatus == 'COMPLETED');

    if (isPaid) {
      _onPaymentConfirmed(
        PaymentConfirmationResult(
          isConfirmed: true,
          status: depositStatus.isNotEmpty ? depositStatus : bookingStatus,
          message: 'Thanh toán đặt cọc đã được xác nhận.',
          transactionId: null,
        ),
      );
    } else if (showPendingToastIfNotPaid) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flatColored,
        title: const Text('Đang chờ xác nhận thanh toán'),
        description: const Text(
          'Nếu bạn đã hoàn tất trên cổng thanh toán, vui lòng kiểm tra lại trạng thái đơn trong mục Lịch đặt.',
        ),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
      );
    }
  }

  void _onPaymentConfirmed(PaymentConfirmationResult result) {
    if (_hasHandledConfirmation) return;
    _hasHandledConfirmation = true;

    final formattedAmount =
        NumberFormat.currency(locale: 'vi', symbol: 'đ').format(_amount);
    final txText =
        result.transactionId != null ? ' (Mã GD: ${result.transactionId})' : '';

    setState(() {
      _transactionId = result.transactionId;
      _confirmationMessage = result.message;
    });

    NotificationService().triggerLocalNotification(
      context: context,
      title: 'Thanh Toán Thành Công! 🎉',
      body: '${result.message} Đơn $_itemName ($formattedAmount)$txText',
      route: '/home',
    );

    _showSuccessDialog(
      message: result.message,
      transactionId: result.transactionId,
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: const Text('Thanh toán chưa hoàn tất'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: false,
    );
  }

  void _showSuccessDialog({
    String? message,
    String? transactionId,
  }) {
    final displayMessage = (message != null && message.isNotEmpty)
        ? message
        : (_confirmationMessage ??
            'Đơn đặt lịch $_bookingId đã được xác nhận.');
    final displayTxId = transactionId ?? _transactionId;

    showPaymentSuccessDialog(
      context: context,
      displayMessage: displayMessage,
      transactionId: displayTxId,
      amount: _amount,
      isPackagePurchase: _isPackagePurchase,
      onConfirm: () {
        if (_isPackagePurchase) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount =
        NumberFormat.currency(locale: 'vi', symbol: 'đ').format(_amount);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Thanh Toán Đặt Chỗ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PaymentOrderSummaryCard(
                bookingId: _bookingId,
                itemName: _itemName,
                dateString: _dateString,
                timeSlot: _timeSlot,
                formattedAmount: formattedAmount,
              ),
              const SizedBox(height: 28),
              Text(
                'CHỌN CỔNG THANH TOÁN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 12),
              PaymentMethodCard(
                name: 'Cổng thanh toán VNPay',
                subtitle: 'Thanh toán đặt cọc qua cổng VNPay Sandbox',
                icon: Icons.account_balance_rounded,
                color: AppColors.info,
                isSelected: _selectedPaymentMethod == 0,
                onTap: () => setState(() => _selectedPaymentMethod = 0),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'XÁC NHẬN THANH TOÁN',
                isLoading: _isProcessing,
                onPressed: _handlePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
