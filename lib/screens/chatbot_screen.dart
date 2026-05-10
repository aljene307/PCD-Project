import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

enum _SessionState { loading, ready, error }

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  _SessionState _sessionState = _SessionState.loading;
  String? _sessionError;
  bool _isSending = false;

  static const _suggestions = [
    'Why is wheat ranked #1?',
    'How can I improve my soil?',
    'What crops suit my climate?',
  ];

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Session initialisation ───────────────────────────────────────────────────

  Future<void> _initSession() async {
    setState(() {
      _sessionState = _SessionState.loading;
      _sessionError = null;
    });

    try {
      // Reuse an existing session created earlier this app lifecycle.
      if (AppSession.advisorSessionId != null) {
        if (mounted) setState(() => _sessionState = _SessionState.ready);
        return;
      }

      // Soil layers — use augmented data for the report path, HWSD otherwise.
      Map<String, dynamic> soilLayers;
      try {
        soilLayers = AppSession.hasLabData
            ? await ApiService.getReportSoilLayersRaw(AppSession.userId)
            : await ApiService.getSoilLayersRaw(AppSession.userId);
      } catch (_) {
        soilLayers = {};
      }

      // Crop requirements are optional — don't block session init if unavailable.
      Map<String, dynamic> cropRequirements;
      try {
        cropRequirements = await ApiService.getCropsNeeds(AppSession.userId);
      } catch (_) {
        cropRequirements = {};
      }

      final sessionId = await ApiService.initAdvisorSession(
        userId: AppSession.userId,
        soilLayers: soilLayers,
        cropRequirements: cropRequirements,
      );

      AppSession.advisorSessionId = sessionId;
      if (mounted) setState(() => _sessionState = _SessionState.ready);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessionState = _SessionState.error;
          _sessionError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ── Messaging ────────────────────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await ApiService.sendAdvisorMessage(
        sessionId: AppSession.advisorSessionId!,
        message: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(_ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isUser: false,
          isError: true,
        ));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const _ChatHeader(),

          Expanded(
            child: switch (_sessionState) {
              _SessionState.loading => const _InitialisingState(),
              _SessionState.error => _ErrorState(
                  message: _sessionError ?? 'Failed to connect to advisor',
                  onRetry: _initSession,
                ),
              _SessionState.ready => _messages.isEmpty
                  ? _EmptyState(
                      suggestions: _suggestions,
                      onSuggestion: _sendMessage,
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isSending) {
                          return const _TypingIndicator();
                        }
                        return _BubbleTile(message: _messages[index])
                            .animate()
                            .fadeIn(duration: 280.ms)
                            .slideY(
                              begin: 0.04,
                              end: 0,
                              duration: 280.ms,
                              curve: Curves.easeOutCubic,
                            );
                      },
                    ),
            },
          ),

          if (_sessionState == _SessionState.ready)
            _InputBar(
              controller: _inputCtrl,
              onSend: _sendMessage,
              enabled: !_isSending,
            ),
        ],
      ),
    );
  }
}

// ─── Message model ────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.forestRich,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ARDHI Assistant',
                  style: AppTextStyles.headingS.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Ask me anything about your farm',
                  style: AppTextStyles.bodyS.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.amberWarm,
              boxShadow: AppShadows.amberGlow,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─── Initialising state ───────────────────────────────────────────────────────

class _InitialisingState extends StatelessWidget {
  const _InitialisingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.forestMid,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Preparing your advisor…',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Loading your soil and crop data',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.inkMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.forestMid.withValues(alpha: 0.09),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 38,
                    color: AppColors.forestMid,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cream,
                    border: Border.all(
                      color: AppColors.inkMuted.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 15,
                    color: AppColors.inkMuted.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Advisor unavailable',
              style: AppTextStyles.headingS.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.inkMuted,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.forestMid,
                textStyle: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State / Suggestions ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestion;

  const _EmptyState({
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forestMid.withValues(alpha: 0.10),
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 58)),
            ),
          ).animate().scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 20),
          Text(
            'Hello Farmer! 👋',
            style: AppTextStyles.headingM.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 10),
          Text(
            'I can help you understand your soil, crops, and farming recommendations.',
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.inkMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 30),
          Text(
            'Try asking:',
            style: AppTextStyles.label.copyWith(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < suggestions.length; i++)
                _SuggestionChip(
                  text: suggestions[i],
                  onTap: () => onSuggestion(suggestions[i]),
                )
                    .animate(delay: (240 + i * 60).ms)
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.08, end: 0, duration: 320.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.forestMid.withValues(alpha: 0.25),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: AppColors.forestMid,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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

// ─── Chat Bubble ──────────────────────────────────────────────────────────────

class _BubbleTile extends StatelessWidget {
  final _ChatMessage message;
  const _BubbleTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isError ? null : AppGradients.amberWarm,
                color: isError ? AppColors.error.withValues(alpha: 0.15) : null,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.eco_rounded,
                color: isError ? AppColors.error : Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.amber : AppColors.cardWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: AppShadows.soft,
                border: !isUser
                    ? Border(
                        left: BorderSide(
                          color: isError
                              ? AppColors.error.withValues(alpha: 0.5)
                              : AppColors.forestMid.withValues(alpha: 0.50),
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodyM.copyWith(
                  color: isUser ? Colors.white : AppColors.ink,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.amberWarm,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: AppShadows.soft,
              border: Border(
                left: BorderSide(
                  color: AppColors.forestMid.withValues(alpha: 0.50),
                  width: 3,
                ),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final wave = (_ctrl.value - delay).clamp(0.0, 1.0);
                    final bounce = wave < 0.5 ? wave * 2 : (1 - wave) * 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.translate(
                        offset: Offset(0, -bounce * 5),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.forestMid
                                .withValues(alpha: 0.4 + bounce * 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              style: AppTextStyles.bodyM.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: enabled ? 'Ask about your farm…' : 'Waiting for reply…',
                hintStyle: AppTextStyles.bodyM.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.creamSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.forestMid,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: enabled ? onSend : null,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: enabled ? AppColors.amber : AppColors.inkMuted.withValues(alpha: 0.3),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: enabled ? () => onSend(controller.text) : null,
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
