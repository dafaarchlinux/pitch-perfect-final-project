import 'package:flutter/material.dart';
import '../../services/music_ai_service.dart';
import '../../services/practice_progress_service.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController questionController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isLoading = false;

  final List<Map<String, String>> messages = [
    {
      'role': 'assistant',
      'text':
          'Halo, aku AI Coach. Tanya latihan vokal, stem gitar, teori musik, atau rencana latihan.',
    },
  ];

  Future<void> _sendMessage() async {
    final text = questionController.text.trim();
    if (text.isEmpty || isLoading) return;

    setState(() {
      messages.add({'role': 'user', 'text': text});
      isLoading = true;
    });

    questionController.clear();
    _scrollToBottom();

    try {
      final answer = await MusicAiService.askMusicAssistant(
        question: text,
        history: messages
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

      if (!mounted) return;

      setState(() {
        messages.add({'role': 'assistant', 'text': answer});
        isLoading = false;
      });

      await PracticeProgressService.addPracticeSession(
        title:
            'AI Coach: ${text.length > 42 ? '${text.substring(0, 42)}...' : text}',
        type: 'Music Assistant',
        score: null,
        level: null,
        combo: null,
        passed: true,
        metadata: {
          'question': text,
          'answer_preview': answer.length > 120
              ? answer.substring(0, 120)
              : answer,
          'source': 'Groq AI Coach',
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'assistant',
          'text':
              'AI Coach belum bisa menjawab saat ini. Coba ulangi dengan pertanyaan yang lebih singkat.',
        });
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI error: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : const Color(0xFF1A1B2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 8),
            bottomRight: Radius.circular(isUser ? 8 : 22),
          ),
          border: Border.all(
            color: isUser
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF2D3050),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message['text'] ?? '',
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              questionController.text = text;
              _sendMessage();
            },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF232542),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2D3050)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFB8BCD7),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1020),
      appBar: AppBar(
        title: const Text('AI Coach'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F1020),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF2563EB),
                  Color(0xFFF472B6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology_rounded, color: Colors.white, size: 34),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Tanya latihan vokal, gitar, teori musik, atau rencana practice.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('Buat jadwal latihan 7 hari'),
                _buildSuggestionChip('Tips vokal untuk pemula'),
                _buildSuggestionChip('Cara stem gitar yang benar'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                ...messages.map(_buildBubble),
                if (isLoading)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'AI Coach sedang menjawab...',
                        style: TextStyle(
                          color: Color(0xFFB8BCD7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                bottomInset > 0 ? 12 : 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF151628),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2D3050)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: questionController,
                        minLines: 1,
                        maxLines: 4,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pertanyaan...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFF8B5CF6),
                          disabledBackgroundColor: const Color(0xFF2D3050),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
