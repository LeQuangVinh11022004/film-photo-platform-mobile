import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

Future<void> showProfileEditSheet({
  required BuildContext context,
  required String initialName,
  required String initialPhone,
  required String initialBio,
  required void Function(String name, String phone, String bio) onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ProfileEditSheetContent(
      initialName: initialName,
      initialPhone: initialPhone,
      initialBio: initialBio,
      onSave: onSave,
    ),
  );
}

class _ProfileEditSheetContent extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialBio;
  final void Function(String name, String phone, String bio) onSave;

  const _ProfileEditSheetContent({
    required this.initialName,
    required this.initialPhone,
    required this.initialBio,
    required this.onSave,
  });

  @override
  State<_ProfileEditSheetContent> createState() =>
      _ProfileEditSheetContentState();
}

class _ProfileEditSheetContentState extends State<_ProfileEditSheetContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Widget _buildInputLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: context.textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
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
              'Chỉnh Sửa Thông Tin Cá Nhân',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildInputLabel(context, 'Họ và tên'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nhập họ tên',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputLabel(context, 'Số điện thoại'),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Nhập số điện thoại',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputLabel(context, 'Giới thiệu bản thân (Bio)'),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Viết vài dòng giới thiệu...',
                filled: true,
                fillColor: context.inputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _nameController.text.trim(),
                  _phoneController.text.trim(),
                  _bioController.text.trim(),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lưu Thay Đổi',
                style: TextStyle(
                  color: context.cardColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
