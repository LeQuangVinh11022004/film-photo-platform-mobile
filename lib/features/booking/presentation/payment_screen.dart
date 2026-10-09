import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPaymentMethod = 0; // 0: VNPay, 1: MoMo, 2: Stripe
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh Toán Trực Tuyến'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
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
                    const Text('TỔNG QUAN ĐƠN HÀNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Đơn đặt:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('Vintage Film Studio Saigon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Thời lượng:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('3 giờ (09:00 - 12:00)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mã giảm giá:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('-50.000đ (ANALOG20)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        Text('700.000đ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Payment Method Selectors
              const Text('CHỌN CỔNG THANH TOÁN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              _buildPaymentOption(
                index: 0,
                name: 'Cổng thanh toán VNPay',
                subtitle: 'Thẻ ATM / QR Pay ngân hàng nội địa',
                icon: Icons.account_balance_rounded,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                index: 1,
                name: 'Ví Điện Tử MoMo',
                subtitle: 'Thanh toán siêu tốc 1 chạm qua ứng dụng MoMo',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.pink.shade600,
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                index: 2,
                name: 'Thẻ Quốc Tế Stripe / Visa / MasterCard',
                subtitle: 'Thanh toán an toàn qua cổng Stripe toàn cầu',
                icon: Icons.credit_card_rounded,
                color: Colors.deepPurple.shade600,
              ),
              const SizedBox(height: 32),

              // Submit Payment
              PrimaryButton(
                text: 'XÁC NHẬN THANH TOÁN 700.000đ',
                isLoading: _isProcessing,
                onPressed: () {
                  setState(() => _isProcessing = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (!mounted) return;
                    setState(() => _isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanh toán thành công! Hóa đơn điện tử đã gửi tới Email của bạn.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  });
                },
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
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Radio<int>(
              value: index,
              groupValue: _selectedPaymentMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
