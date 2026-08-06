import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../services/paul_ai_service.dart';
import '../utils/constants.dart';

class PaulChatScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final Plant? plant;

  const PaulChatScreen({
    super.key,
    required this.plantProvider,
    this.plant,
  });

  @override
  State<PaulChatScreen> createState() => _PaulChatScreenState();
}

class _PaulChatScreenState extends State<PaulChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = PaulAIService();
  final _messages = <ChatMessage>[];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _aiService.setPlantsContext(widget.plantProvider.activePlants);
    if (widget.plant != null) _aiService.setFocusedPlant(widget.plant!);
    _addPaulMessage(
      widget.plant != null
          ? 'Hey! I see you\'re looking at **${widget.plant!.name}**. What would you like to know? 🌿'
          : 'Hi! I\'m Paul, your plant care assistant. Ask me anything about your garden!',
    );
  }

  void _addPaulMessage(String text) {
    setState(() => _messages.add(ChatMessage(role: 'model', text: text)));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await _aiService.sendMessage(text);
    setState(() {
      _messages.add(ChatMessage(role: 'model', text: response));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _PaulAvatar(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paul',
                  style: AppTypography.title2.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Online',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _messages.clear();
                _aiService.clearMemory();
              });
              _addPaulMessage('Chat cleared. How can I help? 🌱');
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageBubble(
                msg: _messages[i],
                isDark: isDark,
              ),
            ),
          ),
          if (_isTyping) _TypingIndicator(isDark: isDark),
          _InputBar(
            controller: _controller,
            isDark: isDark,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _PaulAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.eco, color: Colors.white, size: 22),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isDark;

  const _MessageBubble({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.md,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.accent
              : (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.lg),
            topRight: const Radius.circular(AppRadii.lg),
            bottomLeft: Radius.circular(isUser ? AppRadii.lg : AppRadii.sm),
            bottomRight: Radius.circular(isUser ? AppRadii.sm : AppRadii.lg),
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: isUser
            ? Text(
                msg.text,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              )
            : MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.body.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    height: 1.35,
                  ),
                  strong: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    height: 1.35,
                  ),
                  listBullet: AppTypography.body.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          left: AppSpacing.lg,
          bottom: AppSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final t = (_ctrl.value + i * 0.33) % 1.0;
                final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Transform.translate(
                  offset: Offset(0, -6 * bounce),
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.5 + 0.5 * bounce),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        top: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask Paul anything...',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 8,
                      offset: Offset(0, 3),
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
