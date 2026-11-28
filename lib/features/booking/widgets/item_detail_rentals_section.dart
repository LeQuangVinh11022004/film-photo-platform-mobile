import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';

class ItemDetailRentalsSection extends StatelessWidget {
  final String resolvedSpaceType;
  final List<PhotographerEquipmentResponseDTO> spaceEquipment;
  final List<DarkroomChemicalResponseDTO> darkroomChemicals;

  const ItemDetailRentalsSection({
    super.key,
    required this.resolvedSpaceType,
    required this.spaceEquipment,
    required this.darkroomChemicals,
  });

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String? _formatChemicalExpiry(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      final d = parsed.day.toString().padLeft(2, '0');
      final m = parsed.month.toString().padLeft(2, '0');
      return '$d/$m/${parsed.year}';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spaceEquipment.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Thiết bị cho thuê tại không gian (${spaceEquipment.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ).animate().fadeIn(delay: 340.ms),
          const SizedBox(height: 12),
          ...spaceEquipment.map((eq) {
            final price = (eq.priceForSelectedSlot ?? eq.rentalPrice ?? 0).round();
            final priceFormatted = _formatAmount(price);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eq.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${eq.category}${eq.variant != null && eq.variant!.isNotEmpty ? " • ${eq.variant}" : ""} • SL: ${eq.quantityTotal}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (price > 0)
                    Text(
                      '+$priceFormattedđ/h',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
        if (resolvedSpaceType == 'DARKROOM' && darkroomChemicals.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Hóa chất cho thuê tại không gian (${darkroomChemicals.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ).animate().fadeIn(delay: 360.ms),
          const SizedBox(height: 12),
          ...darkroomChemicals.map((chem) {
            final price = chem.unitSellingPrice.round();
            final priceFormatted = _formatAmount(price);
            final qtyText = chem.stockQuantity % 1 == 0
                ? chem.stockQuantity.toInt().toString()
                : chem.stockQuantity.toString();
            final metaParts = <String>[
              if (chem.brand.trim().isNotEmpty) chem.brand.trim(),
              if (chem.chemicalType.trim().isNotEmpty) chem.chemicalType.trim(),
              if (chem.stockQuantity > 0 || chem.stockUnit.trim().isNotEmpty)
                'Tồn: $qtyText${chem.stockUnit.trim().isNotEmpty ? ' ${chem.stockUnit.trim()}' : ''}',
            ];
            final expiryDisplay = _formatChemicalExpiry(chem.expiresOn);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chem.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textColor,
                          ),
                        ),
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            metaParts.join(' • '),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecColor,
                            ),
                          ),
                        ],
                        if (expiryDisplay != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'HSD: $expiryDisplay',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (price > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$priceFormattedđ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
