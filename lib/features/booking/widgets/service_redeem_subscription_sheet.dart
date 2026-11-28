import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/booking_api_models.dart';
import '../services/booking_api_service.dart';

Future<bool?> showServiceRedeemSubscriptionSheet({
  required BuildContext context,
  required PhotographerPackageSubscriptionResponseDTO subscription,
  required List<int> stepNumbers,
  required Map<int, List<ProviderSpaceAvailabilityResponseDTO>> stepSlots,
  required Map<int, String?> initialSelectedAvailabilityByStep,
  required Map<int, List<String>> equipmentIdsByStep,
  required BookingApiService apiService,
}) {
  final selectedAvailabilityByStep =
      Map<int, String?>.from(initialSelectedAvailabilityByStep);
  bool isSubmitting = false;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                const SizedBox(height: 16),
                Text(
                  'Đặt Lịch Từ Gói: ${subscription.packageName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn khung giờ trống cho từng bước trong gói (Miễn phí đặt cọc - Trừ 1 lượt dùng).',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...stepNumbers.map((step) {
                  final stepItems = subscription.items
                      .where((i) => i.stepOrder == step)
                      .toList();
                  final roomItem = stepItems.firstWhere(
                    (i) =>
                        i.componentType.toUpperCase() == 'STUDIO' ||
                        i.componentType.toUpperCase() == 'DARKROOM',
                    orElse: () => stepItems.first,
                  );
                  final slots = stepSlots[step] ?? [];
                  final selectedId = selectedAvailabilityByStep[step];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.inputColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bước $step: ${roomItem.resourceName} (${roomItem.componentType})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (slots.isEmpty)
                          Text(
                            equipmentIdsByStep[step]?.isNotEmpty ?? false
                                ? 'Không có khung giờ nào còn đủ phòng và thiết bị cho bước này.'
                                : 'Hiện chưa có khung giờ trống cho phòng này.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: selectedId,
                            isExpanded: true,
                            dropdownColor: context.cardColor,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textColor,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: context.cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                ),
                              ),
                            ),
                            items: slots.map((s) {
                              return DropdownMenuItem<String>(
                                value: s.availabilityId,
                                child: Text(
                                  '${s.date} • ${s.startTime} - ${s.endTime}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() {
                                selectedAvailabilityByStep[step] = val;
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'XÁC NHẬN ĐẶT LỊCH THEO GÓI',
                  isLoading: isSubmitting,
                  onPressed: () async {
                    final segments = <PackageBookingSegmentRequestDTO>[];
                    for (final step in stepNumbers) {
                      final availId = selectedAvailabilityByStep[step];
                      if (availId == null || availId.isEmpty) {
                        toastification.show(
                          context: ctx,
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          title: const Text('Thiếu khung giờ'),
                          description: Text(
                            'Vui lòng chọn khung giờ hợp lệ cho Bước $step.',
                          ),
                          alignment: Alignment.topCenter,
                          autoCloseDuration: const Duration(seconds: 3),
                          showProgressBar: false,
                        );
                        return;
                      }
                      segments.add(
                        PackageBookingSegmentRequestDTO(
                          stepOrder: step,
                          availabilityId: availId,
                          equipmentIds: equipmentIdsByStep[step] ?? const [],
                        ),
                      );
                    }

                    setModalState(() => isSubmitting = true);
                    final result = await apiService.createPackageBooking(
                      subscriptionId: subscription.subscriptionId,
                      segments: segments,
                    );
                    if (!ctx.mounted) return;
                    setModalState(() => isSubmitting = false);

                    if (result['success'] == true) {
                      Navigator.pop(ctx, true);
                    } else {
                      toastification.show(
                        context: ctx,
                        type: ToastificationType.error,
                        style: ToastificationStyle.flatColored,
                        title: const Text('Đặt lịch theo gói thất bại'),
                        description: Text(
                          result['message']?.toString() ??
                              'Không thể tạo đơn đặt lịch theo gói.',
                        ),
                        alignment: Alignment.topCenter,
                        autoCloseDuration: const Duration(seconds: 4),
                        showProgressBar: false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
