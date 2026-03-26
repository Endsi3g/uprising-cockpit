import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/groq/groq_service.dart';
import '../../core/ollama/ollama_service.dart';
import '../../core/theme/app_theme.dart';

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final bool isLoading;
  const _ChatMessage(
      {required this.role, required this.text, this.isLoading = false});
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _groq = GroqService();
  final _ollama = OllamaService();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  static const _systemPrompt =
      'Tu es un assistant IA pour une entreprise québécoise de plomberie/couverture. '
      'Tu aides le patron à analyser ses leads, urgences captées, et revenus sauvés par l\'IA. '
      'Réponds toujours en français, de façon concise et pratique. '
      'Tu as accès aux données du cockpit via le contexte de la conversation.';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _messages.add(
          const _ChatMessage(role: 'assistant', text: '', isLoading: true));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => !m.isLoading)
          .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...history,
      ];

      String response;
      try {
        response = await _groq.chat(messages.cast<Map<String, String>>());
      } catch (_) {
        // Ollama fallback
        response = await _ollama.generate(
            '$_systemPrompt\n\nUtilisateur: $text\n\nAssistant:');
      }

      setState(() {
        _messages.removeLast(); // remove loading
        _messages.add(_ChatMessage(role: 'assistant', text: response));
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(_ChatMessage(
            role: 'assistant',
            text: 'Désolé, une erreur est survenue. Vérifie ta connexion.'));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined,
                color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Assistant IA'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _messages.clear()),
            child: const Text('Effacer'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _WelcomeState(onPrompt: (p) {
                    _controller.text = p;
                    _send();
                  })
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) =>
                        _BubbleWidget(msg: _messages[i]),
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                  top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Pose une question à l\'IA...',
                        hintStyle: const TextStyle(
                            color: AppColors.textTertiary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        fillColor: AppColors.surface,
                        filled: true,
                      ),
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: _sending
                        ? const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          )
                        : IconButton.filled(
                            onPressed: _send,
                            icon: const Icon(Icons.send_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
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

class _BubbleWidget extends StatelessWidget {
  final _ChatMessage msg;
  const _BubbleWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 18, color: AppColors.primary),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: msg.isLoading
                  ? _TypingIndicator()
                  : Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
          duration: const Duration(milliseconds: 600), vsync: this);
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6 + _controllers[i].value * 6,
            decoration: BoxDecoration(
              color: AppColors.textSecondary
                  .withOpacity(0.4 + _controllers[i].value * 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _WelcomeState extends StatelessWidget {
  final ValueChanged<String> onPrompt;
  const _WelcomeState({required this.onPrompt});

  static const _suggestions = [
    "Résume mes urgences de cette semaine",
    "Quelle est mon heure de pointe?",
    "Combien j'ai sauvé ce mois-ci?",
    "Quels types d'urgences sont les plus fréquents?",
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.smart_toy_outlined,
            size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text('Assistant Uprising IA',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'Posez vos questions sur vos leads, revenus et urgences.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        ..._suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onPrompt(s),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(s,
                              style: const TextStyle(fontSize: 13))),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
