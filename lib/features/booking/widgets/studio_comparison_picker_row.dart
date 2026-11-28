import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_item.dart';

class StudioComparisonPickerRow extends StatelessWidget {
  final BookingItem item1;
  final BookingItem item2;
  final List<BookingItem> options;
  final ValueChanged<BookingItem> onItem1Changed;
  final ValueChanged<BookingItem> onItem2Changed;

  const StudioComparisonPickerRow({
    super.key,
    required this.item1,
    required this.item2,
    required this.options,
    required this.onItem1Changed,
    required this.onItem2Changed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ComparisonItemPicker(
            slot: 1,
            selected: item1,
            options: options,
            onChanged: onItem1Changed,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: _ComparisonItemPicker(
            slot: 2,
            selected: item2,
            options: options,
            onChanged: onItem2Changed,
          ),
        ),
      ],
    );
  }
}

class _ComparisonItemPicker extends StatelessWidget {
  final int slot;
  final BookingItem selected;
  final List<BookingItem> options;
  final ValueChanged<BookingItem> onChanged;

  const _ComparisonItemPicker({
    required this.slot,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: slot == 1
              ? AppColors.primary.withValues(alpha: 0.45)
              : context.borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          SafeNetworkImage(
            url: selected.imageUrl,
            height: 90,
            width: double.infinity,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          Text(
            selected.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButton<BookingItem>(
            value: selected,
            isExpanded: true,
            dropdownColor: context.cardColor,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            style: TextStyle(fontSize: 12, color: context.textColor),
            items: options.map((item) {
              return DropdownMenuItem<BookingItem>(
                value: item,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.textColor),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                onChanged(val);
              }
            },
          ),
        ],
      ),
    );
  }
}
