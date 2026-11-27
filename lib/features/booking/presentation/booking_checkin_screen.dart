import 'package:flutter/material.dart';

class BookingCheckinScreen extends StatelessWidget {
  const BookingCheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in / Check-out')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Vui lòng liên hệ nhà cung cấp để check-in hoặc check-out. '
            'Ứng dụng chưa hỗ trợ thao tác này.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
