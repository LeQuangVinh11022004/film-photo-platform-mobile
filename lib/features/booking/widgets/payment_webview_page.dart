import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../services/payment_api_service.dart';

class PaymentWebViewPage extends StatefulWidget {
  final Uri initialUri;
  final PaymentApiService paymentService;

  const PaymentWebViewPage({
    super.key,
    required this.initialUri,
    required this.paymentService,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
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
      if (kDebugMode) {
        debugPrint(
          '[PAYMENT_DEBUG] _tryResolveFromCurrentPage error: $e\n$stackTrace',
        );
      }
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
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
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
              color: AppColors.textPrimary.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.warning,
                      size: 52,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lỗi chứng chỉ SSL / Kết nối',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      onPressed: () =>
                          _openInExternalBrowser(widget.initialUri),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Mở trên Trình duyệt (Chrome)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
