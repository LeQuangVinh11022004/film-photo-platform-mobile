import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_item.dart';
import '../services/payment_api_service.dart';

void _paymentLog(String message) {
  if (kDebugMode) {
    debugPrint('[PAYMENT_DEBUG] $message');
  }
}

class PaymentScreen extends StatefulWidget {
  final String? bookingId;
  final BookingItem? item;
  final double? totalAmount;
  final DateTime? bookingDate;
  final String? timeSlot;

  /// Mặc định mở trong WebView nội bộ để bắt JSON trả về và tự đóng về app.
  final bool openInAppWebView;

  const PaymentScreen({
    super.key,
    this.bookingId,
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
  int _selectedPaymentMethod = 0; // 0: VNPay, 1: MoMo, 2: VietQR
  bool _isProcessing = false;
  bool _awaitingExternalReturn = false;
  bool _hasHandledConfirmation = false;

  Uri? pendingReturnUri;

  String? _transactionId;
  String? _confirmationMessage;

  late final double _amount;
  late final String _itemName;
  late final String _bookingId;
  late final String _timeSlot;
  late final String _dateString;

  final PaymentApiService _paymentService = PaymentApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _amount = widget.totalAmount ?? 700000.0;
    _itemName = widget.item?.name ?? 'Vintage Film Studio Saigon';
    _bookingId = widget.bookingId ?? '';
    _timeSlot = widget.timeSlot ?? '3 giờ (09:00 - 12:00)';
    _dateString = widget.bookingDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.bookingDate!)
        : DateFormat('dd/MM/yyyy')
        .format(DateTime.now().add(const Duration(days: 1)));

    _paymentLog(
      'PaymentScreen.initState | bookingId=$_bookingId | amount=$_amount | '
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
      case 1:
        return 'MOMO';
      default:
        return null;
    }
  }

  Future<void> _handlePayment() async {
    _paymentLog('Start Of Payment Process=============================');
    _paymentLog(
      '_handlePayment triggered | bookingId=$_bookingId | '
          'selectedIndex=$_selectedPaymentMethod | '
          'hasHandledConfirmation=$_hasHandledConfirmation | '
          'openInAppWebView=${widget.openInAppWebView}',
    );

    if (_hasHandledConfirmation) {
      _paymentLog('_handlePayment aborted: already handled confirmation');
      return;
    }

    if (_bookingId.isEmpty) {
      _paymentLog('_handlePayment error: _bookingId is empty');
      _showErrorToast('Thiếu mã booking hợp lệ để thực hiện thanh toán.');
      return;
    }

    final methodCode = _resolveBackendPaymentMethod(_selectedPaymentMethod);
    _paymentLog('Resolved methodCode=$methodCode');
    if (methodCode == null) {
      _paymentLog(
          '_handlePayment aborted: unsupported payment method index=$_selectedPaymentMethod');
      _showErrorToast(
        'Phương thức VietQR hiện chưa được Backend hỗ trợ qua API đặt cọc. Vui lòng chọn VNPay hoặc MoMo.',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _paymentLog(
          'Calling initiateDepositPayment(bookingId=$_bookingId, paymentMethod=$methodCode)...');
      final initResult = await _paymentService.initiateDepositPayment(
        bookingId: _bookingId,
        paymentMethod: methodCode,
      );
      _paymentLog('initiateDepositPayment result: $initResult');

      if (!mounted) {
        _paymentLog('Widget unmounted after initiateDepositPayment');
        return;
      }

      if (initResult['success'] != true) {
        setState(() => _isProcessing = false);
        final errMsg = initResult['message'] ?? 'Khởi tạo thanh toán thất bại.';
        _paymentLog('initiateDepositPayment failed: $errMsg');
        _showErrorToast(errMsg);
        return;
      }

      final String paymentUrl = initResult['paymentUrl'] as String;
      _paymentLog('Received paymentUrl: $paymentUrl');
      final uri = Uri.tryParse(paymentUrl);

      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        setState(() => _isProcessing = false);
        _paymentLog('Invalid paymentUrl URI: $paymentUrl');
        _showErrorToast('URL thanh toán từ Backend không hợp lệ: $paymentUrl');
        return;
      }

      if (widget.openInAppWebView) {
        _paymentLog('Opening payment URL in WebView: $uri');
        await _openWithWebView(uri);
      } else {
        _paymentLog('Opening payment URL in external launcher: $uri');
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

    _paymentLog(
      '_openWithWebView returned | mounted=$mounted | result='
          '${result != null ? "{isConfirmed: ${result.isConfirmed}, status: ${result.status}, message: ${result.message}, txId: ${result.transactionId}}" : "null"}',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result != null && result.isConfirmed) {
      _onPaymentConfirmed(result);
    } else {
      _paymentLog(
          'WebView closed without confirmation -> running _checkBookingFallback');
      await _checkBookingFallback(showPendingToastIfNotPaid: true);
    }
  }

  Future<void> _openWithExternalLauncher(Uri paymentUri) async {
    final launched = await launchUrl(
      paymentUri,
      mode: LaunchMode.externalApplication,
    );
    _paymentLog(
        '_openWithExternalLauncher launched=$launched for uri=$paymentUri');

    if (!mounted) return;

    if (!launched) {
      setState(() => _isProcessing = false);
      _showErrorToast('Không thể mở liên kết thanh toán.');
      return;
    }

    _awaitingExternalReturn = true;
    setState(() => _isProcessing = false);
    _paymentLog('_awaitingExternalReturn set to true');
  }

  Future<void> _handleResumeFromExternalBrowser() async {
    _paymentLog(
        '_handleResumeFromExternalBrowser start | pendingReturnUri=$pendingReturnUri');
    _awaitingExternalReturn = false;
    if (!mounted || _hasHandledConfirmation) return;

    setState(() => _isProcessing = true);

    try {
      if (pendingReturnUri != null) {
        final uriToVerify = pendingReturnUri!;
        pendingReturnUri = null;
        _paymentLog('Verifying pendingReturnUri: $uriToVerify');

        final verified = await _paymentService.verifyReturnEndpoint(uriToVerify);
        _paymentLog('verifyReturnEndpoint result: $verified');
        if (!mounted) return;

        if (verified != null && verified.isConfirmed) {
          setState(() => _isProcessing = false);
          _onPaymentConfirmed(verified);
          return;
        }
      }

      _paymentLog('Falling back to _checkBookingFallback after resume');
      await _checkBookingFallback(showPendingToastIfNotPaid: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _checkBookingFallback(
      {bool showPendingToastIfNotPaid = false}) async {
    _paymentLog(
      '_checkBookingFallback start | bookingId=$_bookingId | '
          'hasHandledConfirmation=$_hasHandledConfirmation | '
          'showPendingToastIfNotPaid=$showPendingToastIfNotPaid',
    );
    if (_bookingId.isEmpty || _hasHandledConfirmation) return;

    final updatedBooking = await _paymentService.refreshBookingStatus(_bookingId);
    _paymentLog(
      'refreshBookingStatus response | depositStatus=${updatedBooking?.depositStatus} | '
          'status=${updatedBooking?.status}',
    );
    if (!mounted || _hasHandledConfirmation) return;

    final depositStatus = updatedBooking?.depositStatus.toUpperCase() ?? '';
    final bookingStatus = updatedBooking?.status.toUpperCase() ?? '';
    final isPaid = depositStatus == 'PAID' ||
        depositStatus == 'DEPOSITED' ||
        depositStatus == 'COMPLETED' ||
        depositStatus == 'CONFIRMED' ||
        depositStatus == 'SUCCESS' ||
        bookingStatus == 'CONFIRMED' ||
        bookingStatus == 'PAID';

    _paymentLog(
        'Fallback evaluated isPaid=$isPaid (depositStatus=$depositStatus, bookingStatus=$bookingStatus)');

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
      _paymentLog('Payment not yet paid -> showing pending toast');
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
    _paymentLog(
      '_onPaymentConfirmed | alreadyHandled=$_hasHandledConfirmation | '
          'status=${result.status} | message=${result.message} | txId=${result.transactionId}',
    );
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
    _paymentLog('_showErrorToast: $message');
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
          backgroundColor: Colors.white,
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
              const Text(
                'Thanh Toán Thành Công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
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
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Mã giao dịch: $displayTxId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Tổng tiền đã trả:',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
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
                  text: 'Hoàn tất & Về Trang chủ',
                  onPressed: () {
                    _paymentLog('User tapped "Hoàn tất & Về Trang chủ"');
                    Navigator.pop(ctx);
                    Navigator.pop(context);
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
                ? AppColors.textSecondary
                : AppColors.textPrimary,
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
              color: valueColor ?? AppColors.textPrimary,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh Toán Đặt Chỗ'),
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
                  color: Colors.white,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'TỔNG QUAN ĐƠN HÀNG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _bookingId,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
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
              const Text(
                'CHỌN CỔNG THANH TOÁN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                index: 0,
                name: 'Cổng thanh toán VNPay',
                subtitle: 'Khởi tạo qua /deposit-payment & xác nhận giao dịch',
                icon: Icons.account_balance_rounded,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                index: 1,
                name: 'Ví Điện Tử MoMo',
                subtitle: 'Khởi tạo qua /deposit-payment & xác nhận giao dịch',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.pink.shade600,
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                index: 2,
                name: 'Chuyển Khoản Ngân Hàng (VietQR)',
                subtitle: 'Chưa hỗ trợ API trực tiếp trên Backend',
                icon: Icons.qr_code_2_rounded,
                color: Colors.teal.shade700,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'XÁC NHẬN THANH TOÁN $formattedAmount',
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
        _paymentLog('Selected payment method index=$index ($name)');
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Radio<int>(
              value: index,
              groupValue: _selectedPaymentMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  _paymentLog('Radio changed to index=$val');
                  setState(() => _selectedPaymentMethod = val);
                }
              },
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
    _paymentLog(
        '_PaymentWebViewPage.initState | initialUri=${widget.initialUri}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            final isReturn = _isReturnUrl(url);
            _paymentLog(
                'WebView.onPageStarted | url=$url | isReturnUrl=$isReturn');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasWebError = false;
              });
            }
            if (isReturn) {
              _scheduleReturnCheck(url);
            }
          },
          onUrlChange: (change) {
            final url = change.url;
            final isReturn = url != null && _isReturnUrl(url);
            _paymentLog(
                'WebView.onUrlChange | url=$url | isReturnUrl=$isReturn');
            if (isReturn) {
              _scheduleReturnCheck(url);
            }
          },
          onPageFinished: (url) async {
            _paymentLog('WebView.onPageFinished | url=$url');
            if (mounted) setState(() => _isLoading = false);
            await _tryResolveFromCurrentPage(url);
          },
          onWebResourceError: (error) {
            _paymentLog(
              'WebView.onWebResourceError | code=${error.errorCode} | '
                  'desc=${error.description} | type=${error.errorType} | '
                  'url=${error.url} | isForMainFrame=${error.isForMainFrame}',
            );
            if (error.errorCode == -202 ||
                error.description.toLowerCase().contains('cert') ||
                error.description.toLowerCase().contains('ssl') ||
                error.errorCode < 0) {
              if (mounted) {
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
    final lower = url.toLowerCase();
    return lower.contains('/api/payments/vnpay/return') ||
        lower.contains('/api/payments/momo/return') ||
        lower.contains('payment/return');
  }

  void _scheduleReturnCheck(String url) {
    _paymentLog('_scheduleReturnCheck scheduled in 350ms for url=$url');
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && !_hasPopped) {
        _tryResolveFromCurrentPage(url);
      }
    });
  }

  Future<void> _tryResolveFromCurrentPage(String url) async {
    _paymentLog(
      '_tryResolveFromCurrentPage start | url=$url | '
          'isResolvingReturn=$_isResolvingReturn | hasPopped=$_hasPopped',
    );
    if (_isResolvingReturn || _hasPopped || !mounted) return;
    _isResolvingReturn = true;

    try {
      // 1. Đọc JSON trực tiếp từ nội dung trang đang hiển thị trên WebView
      final rawBody = await _controller.runJavaScriptReturningResult(
        '(document.querySelector("pre") ? document.querySelector("pre").innerText : (document.body ? document.body.innerText : ""))',
      );
      _paymentLog('WebView DOM rawBody: $rawBody');

      final parsedFromDom = _parseDomJson(rawBody);
      _paymentLog(
        'parsedFromDom: ${parsedFromDom != null ? "{isConfirmed: ${parsedFromDom.isConfirmed}, status: ${parsedFromDom.status}, message: ${parsedFromDom.message}, txId: ${parsedFromDom.transactionId}}" : "null"}',
      );

      if (parsedFromDom != null && parsedFromDom.isConfirmed) {
        _popWithResult(parsedFromDom);
        return;
      }

      // 2. Chỉ khi trên DOM chưa có JSON mà URL đúng là endpoint return thì mới gọi verifyReturnEndpoint
      if (_isReturnUrl(url)) {
        final uri = Uri.tryParse(url);
        _paymentLog(
            'DOM had no confirmed JSON, checking return URL via verifyReturnEndpoint: $uri');
        if (uri != null) {
          final verified = await widget.paymentService.verifyReturnEndpoint(uri);
          _paymentLog(
            'WebView verifyReturnEndpoint result: ${verified != null ? "{isConfirmed: ${verified.isConfirmed}, status: ${verified.status}, message: ${verified.message}, txId: ${verified.transactionId}}" : "null"}',
          );
          if (verified != null && verified.isConfirmed) {
            _popWithResult(verified);
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
    _paymentLog(
      '_popWithResult | hasPopped=$_hasPopped | isConfirmed=${result.isConfirmed} | '
          'status=${result.status} | txId=${result.transactionId}',
    );
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    Navigator.pop(context, result);
  }

  PaymentConfirmationResult? _parseDomJson(Object? rawResult) {
    if (rawResult == null) {
      _paymentLog('_parseDomJson: rawResult is null');
      return null;
    }
    String text = rawResult.toString().trim();

    if (text.startsWith('"') && text.endsWith('"') && text.length > 1) {
      try {
        final unwrapped = jsonDecode(text);
        if (unwrapped is String) text = unwrapped.trim();
      } catch (e) {
        _paymentLog('_parseDomJson unwrap string warning: $e');
      }
    }

    // Nếu trang có thêm text khác ngoài JSON, thử trích xuất khối {...}
    final startIdx = text.indexOf('{');
    final endIdx = text.lastIndexOf('}');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      _paymentLog('_parseDomJson: no valid {...} block found in DOM text');
      return null;
    }

    final jsonCandidate = text.substring(startIdx, endIdx + 1);
    _paymentLog('_parseDomJson candidate: $jsonCandidate');

    try {
      final decoded = jsonDecode(jsonCandidate);
      if (decoded is Map<String, dynamic> && decoded.containsKey('status')) {
        return PaymentConfirmationResult.fromJson(decoded);
      } else {
        _paymentLog(
            '_parseDomJson: decoded JSON missing "status" key or not a Map');
      }
    } catch (e) {
      _paymentLog('_parseDomJson jsonDecode error: $e');
    }

    return null;
  }

  Future<void> _openInExternalBrowser(Uri uri) async {
    _paymentLog('_openInExternalBrowser: $uri');
    try {
      final launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _paymentLog('_openInExternalBrowser launched=$launched');
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết trình duyệt.')),
        );
      }
    } catch (e) {
      _paymentLog('_openInExternalBrowser error: $e');
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