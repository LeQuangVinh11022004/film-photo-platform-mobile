import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/ai_api_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiApiService _aiApiService = AiApiService();
  
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Xin chào! Tôi là Trợ Lý Nhiếp Ảnh Film AI. Hãy chia sẻ thông số buổi chụp (chủ đề, địa điểm, ánh sáng...) để tôi gợi ý cách set up phù hợp nhất nhé!',
      'time': '10:00 AM',
    },
  ];

  final List<String> _suggestedQuestions = [
    'Chân dung vintage ngoài trời',
    'Chụp mẫu trong Studio',
    'Chụp phố đêm với Kodak Portra',
    'Quy tắc Sunny 16?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text.trim(),
        'time': 'Vừa xong',
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Call Real API
    final result = await _aiApiService.getPhotographyGuide(
      theme: text.trim(),
      location: 'Chưa xác định',
      availableLight: 'Ánh sáng tự nhiên',
      equipment: 'Máy 35mm',
      experienceLevel: 'Beginner',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _messages.add({
          'isUser': false,
          'text': result['guide'],
          'time': 'Vừa xong',
        });
      } else {
        _messages.add({
          'isUser': false,
          'text': 'Rất tiếc, đã xảy ra lỗi: ${result['message']}',
          'time': 'Vừa xong',
        });
      }
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Trợ Lý AI Film'),
      ),
      body: Column(
        children: [
          // Suggested Questions Chips Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(_suggestedQuestions[index]),
                      backgroundColor: AppColors.primarySoft,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      labelStyle: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                      onPressed: () => _sendMessage(_suggestedQuestions[index]),
                    ),
                  );
                },
              ),
            ),
          ),

          // Messages Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Khối Loading
                if (index == _messages.length && _isLoading) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: context.inputColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          SizedBox(width: 12),
                          Text('AI đang phân tích...', style: TextStyle(fontSize: 13, color: AppColors.primary, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isUser ? AppColors.primaryGradient : null,
                      color: isUser ? null : context.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      border: isUser ? null : Border.all(color: context.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: isUser ? AppColors.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('Trợ Lý AI Film', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        if (!isUser) SizedBox(height: 8),
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser ? context.cardColor : context.textColor,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isUser ? Colors.white70 : AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Hỏi AI về kỹ thuật, tráng film...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                        filled: true,
                        fillColor: context.inputColor,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send_rounded, color: context.cardColor, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


