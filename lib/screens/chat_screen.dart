import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Meeting meeting;
  final VoidCallback onBack;

  const ChatScreen({
    required this.meeting,
    required this.onBack,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late TextEditingController _inputController;
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': '안녕하세요! 이 회의 내용을 기반으로 추가 작업을 요청하거나 궁금한 내용을 질문해 보세요.',
    },
  ];
  bool _isTyping = false;

  final List<String> _quickOptions = [
    '액션아이템 추출',
    '영문 요약',
    '임원 보고용 재작성',
  ];

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });

    _inputController.clear();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'assistant',
            'text':
                '"$text"에 대한 분석을 완료했습니다. 추가로 필요한 사항이 있으시면 말씀해 주세요.',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: const Color(0xFF8e8ea0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '추가 작업',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFececec),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.meeting.title} 기반',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8e8ea0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 빠른 옵션
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (String option in _quickOptions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: ElevatedButton(
                        onPressed: () => _sendMessage(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2f2f2f),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFF3e3e3e),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFececec),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10a37f),
                          ),
                          child: const Center(
                            child: Icon(Icons.mic,
                                size: 13, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            for (int i = 0; i < 3; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF8e8ea0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      if (!isUser)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10a37f),
                          ),
                          child: const Center(
                            child: Icon(Icons.mic,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: isUser
                              ? const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                )
                              : EdgeInsets.zero,
                          decoration: isUser
                              ? BoxDecoration(
                                  color: const Color(0xFF2f2f2f),
                                  borderRadius: BorderRadius.circular(16),
                                )
                              : null,
                          child: Text(
                            message['text']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFececec),
                              height: 1.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 입력 필드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2f2f2f),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3e3e3e),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _sendMessage(value);
                        }
                      },
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                        color: Color(0xFFececec),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: '메시지 입력...',
                        hintStyle: TextStyle(
                          color: Color(0xFF8e8ea0),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => _sendMessage(_inputController.text),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _inputController.text.isNotEmpty
                              ? const Color(0xFF10a37f)
                              : const Color(0xFF3a3a3a),
                        ),
                        child: Icon(
                          Icons.send,
                          size: 14,
                          color: _inputController.text.isNotEmpty
                              ? Colors.white
                              : const Color(0xFF8e8ea0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
        ),
      ),
    );
  }
}
