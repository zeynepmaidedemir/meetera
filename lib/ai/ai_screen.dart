import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/ai_chat_state.dart';
import '../state/app_state.dart';
import '../services/error_handler.dart';
import 'ai_service.dart';
import 'widgets/checklist_card.dart';
import 'ai_message.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  final List<String> _suggestions = [
    "🎒 Packing Checklist",
    "🏠 Find Accommodation",
    "🇪🇺 Learn about Erasmus+",
    "☕ Top Student Cafes",
    "💶 Budget Tips",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isChecklist(String text) {
    final lowerText = text.toLowerCase();
    final containsListKeyword = lowerText.contains('checklist') ||
        lowerText.contains('packing list') ||
        lowerText.contains('to-do list') ||
        lowerText.contains('todo list') ||
        lowerText.contains('task list') ||
        lowerText.contains('kontrol listesi') ||
        lowerText.contains('yapılacaklar listesi') ||
        lowerText.contains('to do list') ||
        lowerText.contains('todo');

    final lines = text.split('\n');
    final itemRegex = RegExp(r'^(\s*[-*•]\s+|\s*\d+\.\s+)(.*)$');
    int itemCount = 0;
    for (var line in lines) {
      if (itemRegex.hasMatch(line)) {
        itemCount++;
      }
    }
    return containsListKeyword && itemCount >= 1;
  }

  @override
  Widget build(BuildContext context) {
    final aiState = context.watch<AiChatState>();
    final appState = context.watch<AppState>();
    final activeChatId = aiState.activeChatId;

    if (activeChatId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("MeetEra AI")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_outlined, size: 52, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 18),
              const Text(
                "No active AI chat",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Start a new chat to begin planning your journey!",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await aiState.createNewChat();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text("New Conversation"),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('ai_chats').doc(activeChatId).snapshots(),
      builder: (context, chatSnap) {
        final data = chatSnap.data?.data() as Map<String, dynamic>?;
        final chatTitle = data?['title'] ?? 'MeetEra AI';

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.amber, size: 12),
                    SizedBox(width: 3),
                    Text(
                      "Gemini Powered",
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
            elevation: 0,
          ),
          body: StreamBuilder<List<AiMessage>>(
            stream: aiState.activeChatMessagesStream(activeChatId),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];

              if (messages.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              }

              return Column(
                children: [
                  // Horizontal Suggestion Chips (Only visible when no messages or only 1-2 messages exist)
                  if (messages.length < 3)
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                suggestion,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              backgroundColor: const Color(0xFF6366F1).withOpacity(0.06),
                              side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                              onPressed: () => _send(suggestion, activeChatId, messages, aiState, appState),
                            ),
                          );
                        },
                      ),
                    ),

                  // Messages Area
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Color(0xFF6366F1)),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    "MeetEra AI Assistant",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Ask about city tips, checklists, budgets, accommodation, or travel schedules!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: messages.length + (_loading ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == messages.length) {
                                return _buildTypingIndicator();
                              }

                              final m = messages[i];

                              if (!m.isUser && _isChecklist(m.text)) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: ErasmusChecklistCard(text: m.text),
                                );
                              }

                              return Align(
                                alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: m.isUser
                                        ? const LinearGradient(
                                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: m.isUser ? null : Theme.of(context).cardColor,
                                    border: m.isUser ? null : Border.all(color: Colors.grey.withOpacity(0.08)),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(m.isUser ? 20 : 4),
                                      bottomRight: Radius.circular(m.isUser ? 4 : 20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    m.text,
                                    style: TextStyle(
                                      color: m.isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                      fontSize: 14.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Input Box
                  _buildInput(activeChatId, messages, aiState, appState),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: const SizedBox(
          width: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypingDot(delay: 0),
              _TypingDot(delay: 200),
              _TypingDot(delay: 400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String chatId,
    List<AiMessage> messages,
    AiChatState aiState,
    AppState appState,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Ask MeetEra AI...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _loading
                    ? null
                    : () => _send(_controller.text, chatId, messages, aiState, appState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(
    String text,
    String chatId,
    List<AiMessage> currentMessages,
    AiChatState aiState,
    AppState appState,
  ) async {
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() => _loading = true);

    try {
      // 1. Save user message to Firestore
      await aiState.addUserMessage(chatId, text);
      _scrollToBottom();

      // 2. Prepare chat history format for Gemini API
      final history = currentMessages
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();
      // append the newest message we just saved
      history.add({'role': 'user', 'content': text});

      // 3. Request Gemini reply
      final res = await AiService.askAi(
        messages: history,
        city: appState.cityLabel,
      );

      // 4. Save AI message to Firestore
      await aiState.addAiMessage(chatId, res['reply'] ?? 'Sure! Let me help you ✨');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        UiHelpers.showPremiumSnackBar(
          context,
          message: ErrorMapper.getFriendlyMessage(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
