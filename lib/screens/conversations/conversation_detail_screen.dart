import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;
  const ConversationDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  Map<String, dynamic>? _booking;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _fetch(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _fetch());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool initial = false}) async {
    try {
      final r = await ApiClient.instance.get(
        '${ApiConfig.conversations}/${widget.bookingId}',
      );
      if (!mounted) return;
      setState(() {
        _booking = (r.data['booking'] as Map?)?.cast<String, dynamic>();
        _messages = ((r.data['data'] as List?) ?? [])
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted && initial) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final r = await ApiClient.instance.post(
        '${ApiConfig.conversations}/${widget.bookingId}/messages',
        data: {'body': text},
      );
      _controller.clear();
      setState(() {
        _messages.add(Map<String, dynamic>.from(r.data as Map));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bericht kon niet verzonden worden')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final guestName = _booking?['guest_name']?.toString() ?? 'Gast';
    final accName = _booking?['accommodation_name']?.toString() ?? '';
    final checkIn = _booking?['check_in']?.toString();
    final checkOut = _booking?['check_out']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guestName, style: const TextStyle(fontSize: 16)),
            if (accName.isNotEmpty)
              Text(
                accName,
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.85)),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (checkIn != null && checkOut != null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    color: Colors.blue[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event,
                            size: 14, color: Colors.blue[800]),
                        const SizedBox(width: 6),
                        Text(
                          '$checkIn → $checkOut',
                          style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Nog geen berichten in deze conversatie.',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final m = _messages[i];
                            final isMe = m['sender_type'] == 'host';
                            return _ChatBubble(
                              body: m['body']?.toString() ?? '',
                              timestamp: m['created_at']?.toString(),
                              isMe: isMe,
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Antwoord typen...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send),
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

class _ChatBubble extends StatelessWidget {
  final String body;
  final String? timestamp;
  final bool isMe;

  const _ChatBubble({
    required this.body,
    required this.timestamp,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp != null
        ? DateTime.tryParse(timestamp!)?.toLocal()
        : null;
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 16, color: Colors.grey[700]),
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    body,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 10,
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
