import 'package:flutter/foundation.dart';

enum ExpertApplicationStatus { notApplied, pending, approved, rejected }

class ExpertApplicationState {
  ExpertApplicationState._();

  static final ExpertApplicationState instance = ExpertApplicationState._();

  // DEMO ONLY:
  // Trạng thái chỉ tồn tại trong bộ nhớ, chưa lưu vào backend.
  final ValueNotifier<ExpertApplicationStatus> status = ValueNotifier(
    ExpertApplicationStatus.notApplied,
  );

  String fullName = '';
  String specialty = '';
  String experience = '';
  String introduction = '';
  String portfolioUrl = '';

  bool get isApproved => status.value == ExpertApplicationStatus.approved;

  void submitDemoApplication({
    required String fullName,
    required String specialty,
    required String experience,
    required String introduction,
    required String portfolioUrl,
  }) {
    this.fullName = fullName;
    this.specialty = specialty;
    this.experience = experience;
    this.introduction = introduction;
    this.portfolioUrl = portfolioUrl;

    // DEMO ONLY:
    // Giả lập Admin duyệt đơn sau 5 giây.
    // TODO(BACKEND): Thay bằng API gửi đơn và nhận kết quả duyệt
    // từ backend. Không tự động approve ở production.

    status.value = ExpertApplicationStatus.pending;

    Future.delayed(const Duration(seconds: 5), () {
      status.value = ExpertApplicationStatus.approved;
    });
  }
}
