
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/expert_question.dart';

class QuestionDetailSheet extends StatefulWidget {
  final ExpertQuestion question;

  const QuestionDetailSheet({
    super.key,
    required this.question,
  });

  @override
  State<QuestionDetailSheet> createState() =>
      _QuestionDetailSheetState();
}

class _QuestionDetailSheetState
    extends State<QuestionDetailSheet> {
  static const _accent = Color(0xFF7C5CFC);

  final _commentController = TextEditingController();
  late List<String> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List<String>.of(widget.question.comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _comments.add(content);
    });

    _commentController.clear();
  }

  void _saveAndClose() {
    Navigator.pop(
      context,
      widget.question.copyWith(comments: _comments),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _accent.withValues(alpha: 0.12),
                      child: Text(
                        question.author.isEmpty
                            ? '?'
                            : question.author[0].toUpperCase(),
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.author,
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saveAndClose,
                      tooltip: 'Đóng',
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.textSecColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.category.toUpperCase(),
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.title,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  question.body,
                  style: TextStyle(
                    color: context.textSecColor,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  color: context.textSecColor.withValues(alpha: 0.15),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bình luận (${_comments.length})',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _comments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Chưa có bình luận. Hãy bắt đầu thảo luận!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textSecColor,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: context.bgColor,
                            child: Icon(
                              Icons.person_rounded,
                              size: 17,
                              color: context.textSecColor,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.bgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _comments[index],
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        filled: true,
                        fillColor: context.bgColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addComment,
                    style: IconButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton(
              onPressed: _saveAndClose,
              child: const Text('Lưu bình luận và đóng'),
            ),
          ),
        ],
      ),
    );
  }
}
