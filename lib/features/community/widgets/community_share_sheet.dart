import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

Future<void> showCommunityShareSheet({
  required BuildContext context,
  required VoidCallback onCopyLink,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) {
      final bottomInset = math.max(
        MediaQuery.paddingOf(sheetCtx).bottom,
        MediaQuery.viewPaddingOf(sheetCtx).bottom,
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
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
              'Chia Sẻ Bài Viết',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: context.inputColor,
                child: const Icon(Icons.copy_rounded, color: AppColors.primary),
              ),
              title: const Text(
                'Sao chép liên kết',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                onCopyLink();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
