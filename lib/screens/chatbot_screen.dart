import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chatbot_service.dart';
import '../services/chat_storage_service.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/swimming_fish_background.dart';
import '../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  final bool isAuthority;
  const ChatbotScreen({super.key, this.isAuthority = false});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final ChatbotService _chatbotService = ChatbotService();
  final ChatStorageService _chatStorageService = ChatStorageService();
  
  late String _userId;
  bool _isTyping = false;
  late AnimationController _orbController;

  final List<String> _quickReplies = [
    'Check White Spot Risk',
    'Ideal pond salinity?',
    'Pond subsidies?',
    'Analyze stress levels',
  ];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
    
    // Animation controller for the glowing virtual assistant orb
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _orbController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }

    // 1. Save user msg to Firestore
    await _chatStorageService.saveMessage(_userId, 'user', text);
    
    setState(() {
      _isTyping = true;
    });

    _scrollToBottom();

    // 2. Fetch recent chat history from Firestore for context
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('chat_history')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
        
    final List<Map<String, String>> chatHistory = [];
    for (var doc in snapshot.docs.reversed) {
      final data = doc.data();
      chatHistory.add({
        'role': data['role'] as String,
        'content': data['content'] as String,
      });
    }

    // 3. Send message payload to AI
    final aiResponse = await _chatbotService.sendMessage(chatHistory);

    // 4. Save AI response to Firestore
    await _chatStorageService.saveMessage(_userId, 'assistant', aiResponse);

    setState(() {
      _isTyping = false;
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leadingWidth: 68,
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            // Holographic pulsing assistant orb
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, child) {
                return Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.35 + (_orbController.value * 0.25)),
                        blurRadius: 10 + (_orbController.value * 8),
                        spreadRadius: 1 + (_orbController.value * 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.online_prediction,
                    color: Colors.white,
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AquaGIS Copilot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isTyping ? 'AI is processing...' : 'Online AI Assistant',
                  style: TextStyle(
                    color: _isTyping ? const Color(0xFF06B6D4) : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      body: SwimmingFishBackground(
        child: Column(
          children: [
            // Dynamic Message Feed
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatStorageService.getChatHistory(_userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                     return Center(child: CircularProgressIndicator(color: AppColors.secondary));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: AppColors.textSecondary.withOpacity(0.2),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Begin your session with AquaGIS Copilot',
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask about species suitability, salinity metrics,\nsubsidies, or biosecurity recommendations.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            _buildInitialQuickReplies(),
                          ],
                        ),
                      ),
                    );
                  }
  
                  final messages = snapshot.data!.docs;
  
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data() as Map<String, dynamic>;
                      final isUser = data['role'] == 'user';
                      return _buildMessageBubble(data['content'], isUser);
                    },
                  );
                },
              ),
            ),
            
            // Typing Indicator
            if (_isTyping) _buildTypingIndicator(),
  
            // Inline Quick Action Chips
            _buildQuickActionChips(),
              
            // Input panel
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialQuickReplies() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _quickReplies.map((reply) {
          return InkWell(
            onTap: () => _sendMessage(reply),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch, color: AppColors.secondary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    reply,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    final isDark = AppColors.isDark;
    
    final bubbleBg = isUser
        ? (isDark ? const Color(0xFF6366F1).withOpacity(0.15) : AppColors.primary.withOpacity(0.12))
        : (isDark ? const Color(0xFF1E293B).withOpacity(0.45) : AppColors.cardLight.withOpacity(0.85));
        
    final bubbleBorder = isUser
        ? (isDark ? const Color(0xFF6366F1).withOpacity(0.3) : AppColors.primary.withOpacity(0.35))
        : (isDark ? const Color(0xFF06B6D4).withOpacity(0.2) : AppColors.border);
        
    final bubbleTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Icon(Icons.smart_toy, color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                isUser ? 'You' : 'AquaGIS Copilot',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GlassCard(
            borderRadius: 16.0,
            blur: 10.0,
            backgroundColor: bubbleBg,
            borderColor: bubbleBorder,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: bubbleTextColor,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = AppColors.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.secondary, size: 14),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : AppColors.cardLight.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF06B6D4).withOpacity(0.15) : AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    'Copilot is writing',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _AnimatedDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _quickReplies.map((reply) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border),
              label: Text(
                reply,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
              onPressed: () => _sendMessage(reply),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Message AquaGIS Copilot...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double cycle = _controller.value * 3.0;
        return Row(
          children: List.generate(3, (index) {
            double bounce = 0.0;
            double diff = cycle - index;
            if (diff >= 0 && diff <= 1.0) {
              bounce = math.sin(diff * math.pi) * -4.0;
            }
            return Container(
              margin: const EdgeInsets.only(left: 3),
              transform: Matrix4.translationValues(0, bounce, 0),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
