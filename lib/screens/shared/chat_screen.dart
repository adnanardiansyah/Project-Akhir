import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/chat_message.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_date_time.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_message.dart';

// Pertanyaan cepat untuk pemesan sesuai kebutuhan M2
const List<String> _customerSuggestions = [
  'Level pedasnya bisa diatur?',
  'Toping apa saja yang tersedia?',
  'Menu ini masih tersedia?',
];

// Layar chat satu pesanan antara pemesan dan resto; pesan muncul tanpa refresh
class ChatScreen extends StatefulWidget {
  final String orderId;
  final AppUser user;
  final AppServices services;
  // Nama lawan bicara untuk judul layar
  final String title;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.user,
    required this.services,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Menyimpan aliran pesan, isian teks, dan tanda sedang mengirim
class _ChatScreenState extends State<ChatScreen> {
  late final Stream<List<ChatMessage>> _messages = widget.services.chat
      .watchMessages(widget.orderId);
  final _inputController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // Mengirim teks; isian dikosongkan dulu agar terasa cepat, dikembalikan bila gagal
  Future<void> _send(String text) async {
    if (_isSending || normalizeMessageText(text) == null) return;
    setState(() => _isSending = true);
    _inputController.clear();
    try {
      await widget.services.chat.sendMessage(
        orderId: widget.orderId,
        sender: widget.user,
        text: text,
      );
    } on ArgumentError catch (e) {
      if (mounted) _restoreAndShowError(text, '${e.message}');
    } catch (_) {
      if (mounted) {
        _restoreAndShowError(text, 'Pesan gagal terkirim. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Mengembalikan teks gagal hanya bila kolom masih kosong, agar ketikan baru tidak tertimpa
  void _restoreAndShowError(String text, String message) {
    if (_inputController.text.isEmpty) _inputController.text = text;
    showErrorSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.user.role == UserRole.customer;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              isCustomer ? 'Chat dengan resto' : 'Chat dengan pemesan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snapshot) => AnimatedSwitcher(
                duration: motionMedium,
                child: _buildMessages(snapshot, isCustomer),
              ),
            ),
          ),
          if (isCustomer) _SuggestionRow(onSelected: _isSending ? null : _send),
          _MessageInput(
            controller: _inputController,
            isSending: _isSending,
            onSend: () => _send(_inputController.text),
          ),
        ],
      ),
    );
  }

  // Memilih tampilan daftar pesan sesuai keadaan aliran
  Widget _buildMessages(
    AsyncSnapshot<List<ChatMessage>> snapshot,
    bool isCustomer,
  ) {
    if (snapshot.hasError) {
      return const StateMessage(
        key: ValueKey('error'),
        icon: Icons.wifi_off_rounded,
        title: 'Chat gagal dimuat',
        message: 'Periksa koneksi internet.',
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    final messages = snapshot.data ?? const [];
    if (messages.isEmpty) {
      return StateMessage(
        key: const ValueKey('empty'),
        icon: Icons.forum_outlined,
        title: 'Belum ada pesan',
        message: isCustomer
            ? 'Tanyakan toping, level pedas, atau ketersediaan menu.'
            : 'Pesan dari pemesan akan muncul di sini.',
      );
    }
    // Daftar dibalik agar pesan terbaru selalu di bawah dan terlihat
    final newestFirst = messages.reversed.toList();
    return ListView.builder(
      key: const ValueKey('messages'),
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: newestFirst.length,
      itemBuilder: (context, index) {
        final message = newestFirst[index];
        return FadeSlideIn(
          key: ValueKey(message.id),
          child: _MessageBubble(
            message: message,
            isMine: message.senderUid == widget.user.uid,
          ),
        );
      },
    );
  }
}

// Gelembung satu pesan; milik sendiri di kanan berwarna utama
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final createdAt = message.createdAt;
    final background = isMine ? scheme.primary : scheme.surfaceContainerHigh;
    final foreground = isMine ? scheme.onPrimary : scheme.onSurface;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: text.bodyLarge?.copyWith(color: foreground),
              ),
              const SizedBox(height: 4),
              Text(
                createdAt == null ? 'Mengirim…' : formatTime(createdAt),
                style: text.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Baris saran pertanyaan cepat yang langsung terkirim saat diketuk
class _SuggestionRow extends StatelessWidget {
  final ValueChanged<String>? onSelected;

  const _SuggestionRow({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _customerSuggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _customerSuggestions[index];
          return Center(
            child: ActionChip(
              label: Text(suggestion),
              onPressed: onSelected == null
                  ? null
                  : () => onSelected!(suggestion),
            ),
          );
        },
      ),
    );
  }
}

// Kolom ketik pesan dengan tombol kirim yang aktif hanya bila ada teks
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: maxMessageLength,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan…',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend =
                    !isSending && normalizeMessageText(value.text) != null;
                return AnimatedScale(
                  scale: canSend ? 1 : 0.9,
                  duration: motionShort,
                  child: IconButton.filled(
                    tooltip: 'Kirim',
                    iconSize: 22,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: canSend ? onSend : null,
                    icon: const Icon(Icons.send_rounded),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
