import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

Future<void> showHomeFilterSheet({
  required BuildContext context,
  required double minPriceLimit,
  required double maxPriceLimit,
  required double initialMaxPrice,
  required double initialMinRating,
  required String initialSortBy,
  required int Function() getResultCount,
  required ValueChanged<double> onMaxPriceChanged,
  required ValueChanged<double> onMinRatingChanged,
  required ValueChanged<String> onSortByChanged,
  required VoidCallback onReset,
}) {
  double maxPriceFilter = initialMaxPrice;
  double minRatingFilter = initialMinRating;
  String sortBy = initialSortBy;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setModalState) {
        Widget buildRatingChip(String label, double rating) {
          final isSelected = minRatingFilter == rating;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: context.inputColor,
            labelStyle: TextStyle(
              color: isSelected ? context.cardColor : context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            onSelected: (selected) {
              if (selected) {
                setModalState(() => minRatingFilter = rating);
                onMinRatingChanged(rating);
              }
            },
          );
        }

        Widget buildSortChip(String label, String value) {
          final isSelected = sortBy == value;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: context.inputColor,
            labelStyle: TextStyle(
              color: isSelected ? context.cardColor : context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            onSelected: (selected) {
              if (selected) {
                setModalState(() => sortBy = value);
                onSortByChanged(value);
              }
            },
          );
        }

        final formattedPrice = maxPriceFilter.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            );

        return Container(
          padding: const EdgeInsets.all(24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bộ Lọc Tìm Kiếm Nâng Cao',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        maxPriceFilter = maxPriceLimit;
                        minRatingFilter = 0.0;
                        sortBy = 'default';
                      });
                      onReset();
                    },
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Giá tối đa: $formattedPriceđ / giờ',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Slider(
                value: maxPriceFilter.clamp(minPriceLimit, maxPriceLimit),
                min: minPriceLimit,
                max: maxPriceLimit,
                divisions: 8,
                activeColor: AppColors.primary,
                label: '${maxPriceFilter.toInt()}đ',
                onChanged: (val) {
                  setModalState(() => maxPriceFilter = val);
                  onMaxPriceChanged(val);
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Đánh giá tối thiểu:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  buildRatingChip('Tất cả', 0.0),
                  const SizedBox(width: 8),
                  buildRatingChip('4.5+ ⭐', 4.5),
                  const SizedBox(width: 8),
                  buildRatingChip('4.8+ ⭐', 4.8),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Sắp xếp theo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildSortChip('Mặc định', 'default'),
                  buildSortChip('Giá thấp đến cao', 'price_asc'),
                  buildSortChip('Giá cao đến thấp', 'price_desc'),
                  buildSortChip('Đánh giá cao nhất', 'rating_desc'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(sheetCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Áp Dụng (${getResultCount()} Kết quả)',
                  style: TextStyle(
                    color: context.cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ),
  );
}
