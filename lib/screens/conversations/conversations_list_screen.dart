import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  int _unreadTotal = 0;
  bool _loading = true;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final r = await ApiClient.instance.get(ApiConfig.conversations);
      if (!mounted) return;
      final list = (r.data['data'] as List?)?.cast<dynamic>() ?? [];
      setState(() {
        _conversations =
            list.map((c) => Map<String, dynamic>.from(c as Map)).toList();
        _unreadTotal = (r.data['unread_total'] as num?)?.toInt() ?? 0;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (initial) _error = 'Kon berichten niet laden';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Berichten'),
            if (_unreadTotal > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadTotal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _conversations.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _load(initial: false),
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) =>
                            _ConversationTile(conversation: _conversations[i]),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 12),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _load(initial: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nog geen berichten',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Zodra een gast je bericht stuurt vanuit de gast-app, verschijnt de conversatie hier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final last = conversation['last_message'] as Map?;
    final unread = (conversation['unread_count'] as num?)?.toInt() ?? 0;
    final color = _parseColor(conversation['accommodation_color'] as String?);
    final guestName = conversation['guest_name']?.toString() ?? 'Gast';
    final accName = conversation['accommodation_name']?.toString() ?? '—';

    final lastBody = last?['body']?.toString();
    final lastSender = last?['sender_type']?.toString();
    final lastTime = last?['created_at']?.toString();
    final time = lastTime != null
        ? DateTime.tryParse(lastTime)?.toLocal()
        : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        child: Text(
          guestName.isNotEmpty ? guestName[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              guestName,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (time != null)
            Text(
              _formatTime(time),
              style: TextStyle(
                color: unread > 0 ? AppTheme.primaryColor : Colors.grey[600],
                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            accName,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          if (lastBody != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (lastSender == 'host')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.reply,
                        size: 14, color: Colors.grey[500]),
                  ),
                Expanded(
                  child: Text(
                    lastBody,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread > 0 ? Colors.black87 : Colors.grey[600],
                      fontWeight:
                          unread > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        final id = conversation['booking_id'];
        if (id != null) context.push('/conversations/$id');
      },
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return AppTheme.primaryColor;
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays > 6) {
      return '${t.day}/${t.month}';
    } else if (diff.inDays >= 1) {
      const days = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'];
      return days[t.weekday - 1];
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}u';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    } else {
      return 'nu';
    }
  }
}
