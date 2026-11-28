import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../booking/models/booking_item.dart';
import '../../booking/models/review_api_models.dart';

Future<void> showProfileMyReviewsSheet({
  required BuildContext context,
  required List<SpaceReviewResponseDTO> reviews,
  required Map<String, BookingItem> spacesById,
  required ValueChanged<BookingItem> onOpenSpaceDetail,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => Container(
      height: MediaQuery.of(sheetCtx).size.height * 0.65,
      padding: const EdgeInsets.all(24),
      child: Column(
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
            'Đánh Giá Không Gian (${reviews.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.inputColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    reviews.isEmpty
                        ? '—'
                        : (reviews
                                    .map((review) => review.rating)
                                    .reduce((a, b) => a + b) /
                                reviews.length)
                            .toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chỉ hiển thị đánh giá của bạn trong các không gian đã tải, không phải toàn bộ lịch sử.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final r = reviews[index];
                  final spaceItem = spacesById[r.spaceId.toLowerCase()];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (spaceItem == null) return;
                      Navigator.pop(sheetCtx);
                      onOpenSpaceDetail(spaceItem);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        spaceItem?.name ?? r.customerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: context.textColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${r.rating} ⭐ • ${r.spaceType}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (r.comment != null &&
                                    r.comment!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    r.comment!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (spaceItem != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: context.textSecColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
