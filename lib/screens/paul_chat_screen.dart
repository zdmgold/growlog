import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../services/ai/ai_settings.dart';
import '../services/paul_ai_service.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import 'ai_setup_screen.dart';

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

  static const _starters = [
    'How often should I water it?',
    'Why are the leaves turning yellow?',
    'Does it need more light?',
    'When should I repot it?',
  ];

  @override
  void initState() {
    super.initState();
    _aiService.setPlantsContext(widget.plantProvider.activePlants);
    if (widget.plant != null) _aiService.setFocusedPlant(widget.plant!);
    _addPaulMessage(_greeting());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _greeting() {
    return widget.plant != null
        ? 'You are looking at **${widget.plant!.name}**. What would you like to know?'
        : 'I am Paul. Ask me about watering, light, pests, or anything that looks wrong with a plant.';
  }

  void _addPaulMessage(String text) {
    setState(() => _messages.add(ChatMessage(role: 'model', text: text)));
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isTyping) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await _aiService.sendMessage(text);
    if (!mounted) return;
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

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
      _aiService.clearMemory();
    });
    _addPaulMessage(_greeting());
  }

  void _openSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListenableBuilder(
      listenable: AiSettings.instance,
      builder: (context, _) {
        final ai = AiSettings.instance;
        final ready = ai.isConfigured;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Back',
              icon: Icon(PhosphorBold.arrowLeft, color: ink),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                const _PaulAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paul',
                          style: AppTypography.title1.copyWith(color: ink, fontSize: 20)),
                      Text(
                        ready
                            ? (ai.provider?.name ?? 'Connected')
                            : 'Not connected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Clear chat',
                icon: Icon(PhosphorRegular.trash, color: ink),
                onPressed: _clear,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              if (!ready) _ConnectBanner(isDark: isDark, onTap: _openSetup),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
                  ),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, i) {
                    if (i == _messages.length) {
                      if (ready && _messages.length == 1 && !_isTyping) {
                        return _Starters(
                          isDark: isDark,
                          items: _starters,
                          onPick: _send,
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    return _MessageBubble(msg: _messages[i], isDark: isDark);
                  },
                ),
              ),
              if (_isTyping) _TypingIndicator(isDark: isDark),
              _InputBar(
                controller: _controller,
                isDark: isDark,
                enabled: ready,
                onSend: _send,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaulAvatar extends StatelessWidget {
  const _PaulAvatar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(PhosphorFill.leaf, color: accent, size: 22),
    );
  }
}

class _ConnectBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ConnectBanner({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
      ),
      child: Material(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(PhosphorFill.key, color: accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Chat needs an AI connection. Add your API key to talk to Paul.',
                    style: AppTypography.footnote.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(PhosphorBold.caretRight, color: accent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Starters extends StatelessWidget {
  final bool isDark;
  final List<String> items;
  final ValueChanged<String> onPick;
  const _Starters({
    required this.isDark,
    required this.items,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final q in items)
            Semantics(
              button: true,
              label: q,
              child: Material(
                color: Colors.transparent,
                shape: StadiumBorder(side: BorderSide(color: accent.withOpacity(0.5))),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onPick(q),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(q, style: AppTypography.callout.copyWith(color: accent)),
                  ),
                ),
              ),
            ),
        ],
      ),
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
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
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
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? (isDark ? AppColors.accentLight : AppColors.forest)
              : (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.lg),
            topRight: const Radius.circular(AppRadii.lg),
            bottomLeft: Radius.circular(isUser ? AppRadii.lg : AppRadii.sm),
            bottomRight: Radius.circular(isUser ? AppRadii.sm : AppRadii.lg),
          ),
        ),
        child: isUser
            ? Text(
                msg.text,
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.bgPrimaryDark : Colors.white,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.body.copyWith(color: ink, height: 1.4),
                  strong: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ink,
                    height: 1.4,
                  ),
                  listBullet: AppTypography.body.copyWith(
                    color: isDark ? AppColors.accentLight : AppColors.accent,
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
    final dot = widget.isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: widget.isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
          ),
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
                  offset: Offset(0, -5 * bounce),
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: dot.withOpacity(0.5 + 0.5 * bounce),
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
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
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
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: enabled ? 'Ask Paul' : 'Connect AI to chat',
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
          Semantics(
            button: true,
            label: 'Send',
            child: Material(
              color: enabled ? accent : accent.withOpacity(0.35),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onSend : null,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    PhosphorFill.arrowUpRight,
                    size: 20,
                    color: isDark ? AppColors.bgPrimaryDark : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
