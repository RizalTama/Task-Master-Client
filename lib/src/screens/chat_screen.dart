import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_master/src/providers/auth_provider.dart';
import 'package:task_master/src/theme/app_theme.dart';

// Quick suggestion chips shown on empty state
const _suggestions = [
  'Tampilkan semua task saya',
  'Buat task baru untuk besok',
  'Task yang belum selesai',
  'Tandai task sebagai selesai',
  'Hapus task yang sudah lewat',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage([String? prefill]) async {
    final message = prefill ?? _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final apiService =
          Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await apiService.postChat(message);

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response['reply'] ?? 'Maaf, terjadi kesalahan.',
          'time': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Error: ${e.toString()}',
          'time': DateTime.now(),
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      child: Row(
        children: [
          // AI avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task AI Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4FFFB0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online · siap membantu',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _messages.clear()),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_sweep_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.12),
                  AppColors.secondaryLight.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 52,
              color: AppColors.primaryLight.withOpacity(0.7),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'Halo! Ada yang bisa saya bantu?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Saya bisa membuat, mengubah, menghapus,\ndan menampilkan task kamu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textLight,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Coba tanyakan:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.asMap().entries.map((e) {
              return _SuggestionChip(
                text: e.value,
                index: e.key,
                onTap: () => _sendMessage(e.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Message list ─────────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[_messages.length - 1 - index];
        final bool isUser = msg['role'] == 'user';
        return _MessageBubble(
          isUser: isUser,
          message: msg['content'] as String,
          time: msg['time'] as DateTime,
          index: index,
        );
      },
    );
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AiAvatar(size: 28),
          SizedBox(width: 8),
          _TypingDots(),
        ],
      ),
    );
  }

  // ─── Input bar ────────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                controller: _controller,
                enabled: !_isLoading,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  filled: false,
                ),
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textDark),
                onSubmitted: _isLoading ? null : (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : AppColors.primaryGradient,
              color: _isLoading ? AppColors.borderColor : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primaryLight.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _sendMessage,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.send_rounded,
                    color: _isLoading ? AppColors.textLight : Colors.white,
                    size: 20,
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

// ─── AI Avatar ────────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  final double size;
  const _AiAvatar({this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

// ─── Suggestion Chip ──────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String text;
  final int index;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryLight.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded,
                size: 14, color: AppColors.primaryLight),
            const SizedBox(width: 5),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 450 + index * 80))
        .slideY(begin: 0.2, delay: Duration(milliseconds: 450 + index * 80));
  }
}

// ─── Typing Dots (proper AnimationController for dispose safety) ─────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final bool isUser;
  final String message;
  final DateTime time;
  final int index;

  const _MessageBubble({
    required this.isUser,
    required this.message,
    required this.time,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AiAvatar(size: 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.primaryGradient : null,
                    color: isUser ? null : AppColors.surfaceLight,
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : AppColors.borderColor,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser
                                ? AppColors.primaryDark
                                : Colors.black)
                            .withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isUser ? Colors.white : AppColors.textDark,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: min(index * 40, 200)))
        .slideX(
          begin: isUser ? 0.1 : -0.1,
          delay: Duration(milliseconds: min(index * 40, 200)),
        );
  }
}
