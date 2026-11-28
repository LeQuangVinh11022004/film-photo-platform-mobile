import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

Future<void> showHomeLocationPickerSheet({
  required BuildContext context,
  required List<String> locations,
  required String currentLocation,
  required ValueChanged<String> onLocationSelected,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => Container(
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
          Text(
            'Chọn Tỉnh / Thành Phố',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...locations.map(
            (loc) => ListTile(
              leading: Icon(
                Icons.location_on_rounded,
                color: currentLocation == loc
                    ? AppColors.primary
                    : context.textSecColor,
              ),
              title: Text(
                loc,
                style: TextStyle(
                  fontWeight: currentLocation == loc
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: currentLocation == loc
                      ? AppColors.primary
                      : context.textColor,
                ),
              ),
              trailing: currentLocation == loc
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () {
                onLocationSelected(loc);
                Navigator.pop(sheetCtx);
              },
            ),
          ),
        ],
      ),
    ),
  );
}
