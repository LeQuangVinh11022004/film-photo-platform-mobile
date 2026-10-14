
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/expert_question.dart';
import 'widgets/question_card.dart';
import 'widgets/create_question_sheet.dart';
import 'widgets/question_detail_sheet.dart';

class ExpertQaScreen extends StatefulWidget {
  const ExpertQaScreen({super.key});

  @override
  State<ExpertQaScreen> createState() => _ExpertQaScreenState();
}

class _ExpertQaScreenState extends State<ExpertQaScreen> {
  static const _accent = Color(0xFF7C5CFC);

  String _category = 'Tất cả';
  String _sort = 'Mới nhất';
  String _search = '';

  final Set<String> _likedQuestions = {};

  late final List<ExpertQuestion> _questions;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    // DEMO ONLY: thay bằng dữ liệu từ API khi có backend.
    _questions = [
      ExpertQuestion(
        id: 'q1',
        author: 'Minh Anh',
        title: 'Nên bắt đầu với máy film nào trong tầm giá 3 triệu?',
        body:
            'Mình mới tìm hiểu nhiếp ảnh film, chủ yếu chụp street và bạn bè. '
            'Mọi người có gợi ý body nào dễ dùng, dễ sửa và có lens phổ biến không?',
        category: 'Thiết bị',
        createdAt: now.subtract(const Duration(hours: 2)),
        comments: const [
          'Thử Canon EOS 300 hoặc Nikon F80, dễ dùng và nhiều lens.',
          'Nhớ để ngân sách cho film và tráng scan nhé.',
        ],
      ),
      ExpertQuestion(
        id: 'q2',
        author: 'Hoàng Nam',
        title: 'Film bị ám xanh khi chụp trong nhà, xử lý thế nào?',
        body:
            'Mình dùng Kodak ColorPlus trong phòng có đèn LED, ảnh scan ra '
            'hơi xanh. Có phải do nhiệt độ màu không?',
        category: 'Kỹ thuật',
        createdAt: now.subtract(const Duration(hours: 7)),
        comments: const [
          'Nguồn LED có thể làm lệch màu. Thử chụp gần cửa sổ hoặc dùng filter cân bằng màu.',
        ],
      ),
      ExpertQuestion(
        id: 'q3',
        author: 'Thảo Vy',
        title: 'Có nên tự tráng film màu tại nhà không?',
        body:
            'Mình đã tráng đen trắng vài lần và muốn thử C-41. '
            'Mọi người thường gặp khó nhất ở bước nào?',
        category: 'Tráng film',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ExpertQuestion(
        id: 'q4',
        author: 'Đức Phạm',
        title: 'Cách đo sáng khi chụp ngược sáng?',
        body:
            'Mình muốn giữ chi tiết khuôn mặt nhưng vẫn có ánh sáng nền. '
            'Nên đo sáng vào da hay bù sáng khoảng bao nhiêu stop?',
        category: 'Kỹ thuật',
        createdAt: now.subtract(const Duration(days: 2)),
        comments: const [
          'Nếu ưu tiên da người, hãy đo vào vùng da và cân nhắc bù sáng tùy máy.',
        ],
      ),
    ];
  }

  List<ExpertQuestion> get _visibleQuestions {
    final result = _questions.where((question) {
      final matchesCategory =
          _category == 'Tất cả' || question.category == _category;

      final keyword = _search.toLowerCase();

      final matchesSearch = keyword.isEmpty ||
          question.title.toLowerCase().contains(keyword) ||
          question.body.toLowerCase().contains(keyword) ||
          question.author.toLowerCase().contains(keyword);

      return matchesCategory && matchesSearch;
    }).toList();

    if (_sort == 'Nhiều bình luận') {
      result.sort(
        (a, b) => b.comments.length.compareTo(a.comments.length),
      );
    } else {
      result.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );
    }

    return result;
  }

  Future<void> _createQuestion() async {
    final question = await showModalBottomSheet<ExpertQuestion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateQuestionSheet(),
    );

    if (question == null || !mounted) return;

    setState(() {
      _questions.insert(0, question);
      _category = 'Tất cả';
      _search = '';
      _sort = 'Mới nhất';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng câu hỏi demo.')),
    );
  }

  Future<void> _openQuestion(ExpertQuestion question) async {
    final index = _questions.indexWhere((item) => item.id == question.id);
    if (index == -1) return;

    final updatedQuestion = await showModalBottomSheet<ExpertQuestion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionDetailSheet(
        question: _questions[index],
      ),
    );

    if (updatedQuestion == null || !mounted) return;

    setState(() {
      _questions[index] = updatedQuestion;
    });
  }

  Future<void> _searchQuestions() async {
    final controller = TextEditingController(text: _search);

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tìm câu hỏi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tiêu đề, nội dung hoặc tác giả',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null && mounted) {
      setState(() => _search = value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = [
      'Tất cả',
      'Thiết bị',
      'Kỹ thuật',
      'Tráng film',
      'Khác',
    ];

    final questions = _visibleQuestions;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 150),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hỏi đáp',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Trao đổi kiến thức cùng cộng đồng film',
                        style: TextStyle(
                          color: context.textSecColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: _searchQuestions,
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Banner tạo câu hỏi.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C5CFC),
                    Color(0xFF9B87FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Có điều gì muốn hỏi?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Chia sẻ kinh nghiệm, giúp nhau chụp film đẹp hơn.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _createQuestion,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _accent,
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Câu hỏi cộng đồng',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'Mới nhất',
                      child: Text('Mới nhất'),
                    ),
                    PopupMenuItem(
                      value: 'Nhiều bình luận',
                      child: Text('Nhiều bình luận'),
                    ),
                  ],
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: context.textSecColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sort,
                        style: TextStyle(
                          color: context.textSecColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bộ lọc chủ đề.
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _category = category);
                    },
                    selectedColor: _accent.withValues(alpha: 0.14),
                    side: BorderSide(
                      color: selected
                          ? _accent.withValues(alpha: 0.4)
                          : context.textSecColor.withValues(alpha: 0.15),
                    ),
                    labelStyle: TextStyle(
                      color: selected ? _accent : context.textSecColor,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),

            if (_search.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Từ khóa: $_search',
                        style: TextStyle(
                          color: context.textSecColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _search = ''),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            if (questions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 44,
                      color: context.textSecColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Không tìm thấy câu hỏi phù hợp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecColor),
                    ),
                  ],
                ),
              )
            else
              ...questions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuestionCard(
                    question: question,
                    liked: _likedQuestions.contains(question.id),
                    onTap: () => _openQuestion(question),
                    onLike: () {
                      setState(() {
                        if (!_likedQuestions.add(question.id)) {
                          _likedQuestions.remove(question.id);
                        }
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          heroTag: 'expert_qa_create',
          onPressed: _createQuestion,
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Đặt câu hỏi'),
        ),
      ),
    );
  }
}
