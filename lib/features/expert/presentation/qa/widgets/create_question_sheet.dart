
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/expert_question.dart';

class CreateQuestionSheet extends StatefulWidget {
  const CreateQuestionSheet({super.key});

  @override
  State<CreateQuestionSheet> createState() =>
      _CreateQuestionSheetState();
}

class _CreateQuestionSheetState
    extends State<CreateQuestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _category = 'Kỹ thuật';

  static const _accent = Color(0xFF7C5CFC);

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: context.bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final question = ExpertQuestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: 'Bạn',
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      category: _category,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, question);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textSecColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Đặt câu hỏi mới',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chia sẻ vấn đề để nhận lời khuyên từ cộng đồng.',
                style: TextStyle(
                  color: context.textSecColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                maxLength: 120,
                decoration: _decoration('Tiêu đề câu hỏi'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hãy nhập tiêu đề câu hỏi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _decoration('Chủ đề'),
                items: const [
                  DropdownMenuItem(
                    value: 'Thiết bị',
                    child: Text('Thiết bị'),
                  ),
                  DropdownMenuItem(
                    value: 'Kỹ thuật',
                    child: Text('Kỹ thuật'),
                  ),
                  DropdownMenuItem(
                    value: 'Tráng film',
                    child: Text('Tráng film'),
                  ),
                  DropdownMenuItem(
                    value: 'Khác',
                    child: Text('Khác'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyController,
                minLines: 4,
                maxLines: 7,
                maxLength: 3000,
                decoration: _decoration('Nội dung chi tiết'),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Nội dung cần ít nhất 10 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Đăng câu hỏi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
