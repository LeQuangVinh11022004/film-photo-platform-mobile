import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import '../models/review_api_models.dart';
import '../services/review_api_service.dart';
import 'schedule_formatters.dart';

Future<bool?> showScheduleReviewSheet({
  required BuildContext context,
  required BookingResponseDTO booking,
  required String resolvedSpaceType,
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
              const SizedBox(height: 18),
              Text(
                'Đánh Giá Không Gian Đặt Chỗ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${booking.spaceName} • ${ScheduleHelpers.formatDateDisplay(booking.bookingDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 40,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setModalState(() => selectedRating = star);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText:
                      'Chia sẻ nhận xét về không gian, thiết bị và chất lượng phục vụ...',
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
                          setModalState(() => isSubmitting = true);
                          final res =
                              await reviewApiService.createBookingReview(
                            bookingId: booking.bookingId,
                            request: SpaceReviewWriteRequestDTO(
                              spaceType: resolvedSpaceType,
                              spaceId: booking.spaceId,
                              rating: selectedRating,
                              comment: commentController.text.trim(),
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
                                    'Vui lòng thử lại sau khi kết thúc buổi chụp.',
                              ),
                              alignment: Alignment.topCenter,
                              autoCloseDuration: const Duration(seconds: 4),
                              showProgressBar: false,
                            );
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
