import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import '../models/review_api_models.dart';
import '../services/review_api_service.dart';

Future<bool?> showItemDetailWriteReviewSheet({
  required BuildContext context,
  required String itemName,
  required String resolvedSpaceType,
  required String resolvedSpaceId,
  required BookingResponseDTO? confirmedBooking,
  required ReviewApiService reviewApiService,
}) {
  int selectedRating = 5;
  final commentController = TextEditingController();
  bool isSubmitting = false;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (modalCtx) => StatefulBuilder(
      builder: (modalCtx, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Đánh Giá $itemName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đơn cần được thanh toán hoặc dùng lượt gói, lịch đã kết thúc và chưa được đánh giá.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 40,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setModalState(() => selectedRating = starValue);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm thực tế của bạn tại đây...',
                  filled: true,
                  fillColor: context.inputColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final comment = commentController.text.trim();
                          if (confirmedBooking != null &&
                              resolvedSpaceId.length >= 32) {
                            setModalState(() => isSubmitting = true);
                            final res =
                                await reviewApiService.createBookingReview(
                              bookingId: confirmedBooking.bookingId,
                              request: SpaceReviewWriteRequestDTO(
                                spaceType: resolvedSpaceType,
                                spaceId: resolvedSpaceId,
                                rating: selectedRating,
                                comment: comment,
                              ),
                            );
                            if (!modalCtx.mounted) return;
                            setModalState(() => isSubmitting = false);

                            if (res['success'] == true) {
                              Navigator.pop(modalCtx, true);
                            } else {
                              toastification.show(
                                context: modalCtx,
                                type: ToastificationType.warning,
                                style: ToastificationStyle.flatColored,
                                title: const Text('Chưa thể gửi đánh giá'),
                                description: Text(
                                  res['message']?.toString() ??
                                      'Vui lòng thử lại sau.',
                                ),
                                alignment: Alignment.topCenter,
                                autoCloseDuration: const Duration(seconds: 4),
                                showProgressBar: false,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Gửi Đánh Giá',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
