import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/network/api_client.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/payment_api_service.dart';

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
      _showErrorToast('Thiếu mã booking hoặc mã gói dịch vụ hợp lệ để thực hiện thanh toán.');
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
        builder: (_) => _PaymentWebViewPage(
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

  Future<void> _checkBookingFallback(
      {bool showPendingToastIfNotPaid = false}) async {
    if (_hasHandledConfirmation) return;

    if (_isPackagePurchase) {
      if (_purchaseOrderId == null || _purchaseOrderId!.isEmpty) return;
      final activeSub =
          await _paymentService.refreshPackageSubscriptionStatus(_purchaseOrderId!);
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

    final updatedBooking = await _paymentService.refreshBookingStatus(_bookingId);
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
        : (_confirmationMessage ?? 'Đơn đặt lịch $_bookingId đã được xác nhận.');
    final displayTxId = transactionId ?? _transactionId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thanh Toán Thành Công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (displayTxId != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.inputColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Mã giao dịch: $displayTxId',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.inputColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Tổng tiền đã trả:',
                        style: TextStyle(
                            fontSize: 13, color: context.textSecColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        NumberFormat.currency(locale: 'vi', symbol: 'đ')
                            .format(_amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _isPackagePurchase
                      ? 'Xem Gói Đã Đăng Ký'
                      : 'Hoàn tất & Về Trang chủ',
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isBoldValue = true,
    Color? valueColor,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: valueColor == null
                ? context.textSecColor
                : context.textColor,
            fontSize: fontSize,
            fontWeight: valueColor == null ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isBoldValue ? fontWeight : FontWeight.normal,
              fontSize: fontSize,
              color: valueColor ?? context.textColor,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount =
    NumberFormat.currency(locale: 'vi', symbol: 'đ').format(_amount);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'Thanh Toán Đặt Chỗ',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG QUAN ĐƠN HÀNG',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã đơn: $_bookingId',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      label: 'Địa điểm:',
                      value: _itemName,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      label: 'Ngày đặt:',
                      value: _dateString,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      label: 'Khung giờ:',
                      value: _timeSlot,
                      fontWeight: FontWeight.bold,
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      label: 'Tổng thanh toán:',
                      value: formattedAmount,
                      valueColor: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ],
                ),
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
              _buildPaymentOption(
                index: 0,
                name: 'Cổng thanh toán VNPay',
                subtitle: 'Thanh toán đặt cọc qua cổng VNPay Sandbox',
                icon: Icons.account_balance_rounded,
                color: Colors.blue.shade700,
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

  Widget _buildPaymentOption({
    required int index,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentWebViewPage extends StatefulWidget {
  final Uri initialUri;
  final PaymentApiService paymentService;

  const _PaymentWebViewPage({
    required this.initialUri,
    required this.paymentService,
  });

  @override
  State<_PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<_PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isResolvingReturn = false;
  bool _hasPopped = false;
  bool _hasWebError = false;
  String? _webErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isReturnUrl(request.url)) {
              _scheduleReturnCheck(request.url);
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasWebError = false;
              });
            }
            if (_isReturnUrl(url)) {
              _scheduleReturnCheck(url);
            }
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && _isReturnUrl(url)) {
              _scheduleReturnCheck(url);
            }
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _isLoading = false);
            await _tryResolveFromCurrentPage(url);
          },
          onWebResourceError: (error) async {
            final failingUrl = error.url ?? '';
            if (_isReturnUrl(failingUrl)) {
              await _tryResolveFromCurrentPage(failingUrl);
              return;
            }
            if (error.errorCode == -202 ||
                error.description.toLowerCase().contains('cert') ||
                error.description.toLowerCase().contains('ssl') ||
                error.errorCode < 0) {
              if (mounted && !_hasPopped) {
                setState(() {
                  _hasWebError = true;
                  _webErrorMessage =
                      'Lỗi SSL (${error.errorCode}: ${error.description})';
                });
              }
            }
          },
        ),
      )
      ..loadRequest(widget.initialUri);
  }

  bool _isReturnUrl(String url) {
    final uri = Uri.tryParse(url);
    final backend = Uri.tryParse(ApiClient().baseUrl);
    return uri != null &&
        backend != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.origin == backend.origin &&
        uri.path == '/api/payments/vnpay/return';
  }

  void _scheduleReturnCheck(String url) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && !_hasPopped) {
        _tryResolveFromCurrentPage(url);
      }
    });
  }

  Future<void> _tryResolveFromCurrentPage(String url) async {
    if (_isResolvingReturn || _hasPopped || !mounted) return;
    _isResolvingReturn = true;

    try {
      if (_isReturnUrl(url)) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          final verified =
              await widget.paymentService.verifyReturnEndpoint(uri);
          if (verified != null) {
            _popWithResult(verified);
            return;
          }
          final qp = uri.queryParameters;
          if (qp['vnp_ResponseCode'] != null &&
              qp['vnp_ResponseCode'] != '00') {
            _popWithResult(
              PaymentConfirmationResult(
                isConfirmed: false,
                status: 'Failed',
                message:
                    'Giao dịch VNPay không thành công (Mã: ${qp['vnp_ResponseCode']}).',
              ),
            );
            return;
          }
        }
      }

    } catch (e, stackTrace) {
      _paymentLog('_tryResolveFromCurrentPage error: $e\n$stackTrace');
    } finally {
      _isResolvingReturn = false;
    }
  }

  void _popWithResult(PaymentConfirmationResult result) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    Navigator.pop(context, result);
  }

  Future<void> _openInExternalBrowser(Uri uri) async {
    try {
      final launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết trình duyệt.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở trình duyệt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng Thanh Toán'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Mở trên trình duyệt ngoài',
            onPressed: () => _openInExternalBrowser(widget.initialUri),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          if (_hasWebError)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Colors.amber, size: 52),
                    const SizedBox(height: 16),
                    const Text(
                      'Lỗi chứng chỉ SSL / Kết nối',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _webErrorMessage ??
                          'Máy chủ đang sử dụng chứng chỉ SSL tự ký hoặc chưa được tin tưởng.',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openInExternalBrowser(widget.initialUri),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Mở trên Trình duyệt (Chrome)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}