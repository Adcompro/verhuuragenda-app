import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../core/api/api_client.dart';

/// Provider that polls the conversations index every 30 seconds and
/// exposes the global unread message count for the host.
final unreadMessagesProvider =
    StateNotifierProvider<UnreadMessagesNotifier, int>(
  (ref) => UnreadMessagesNotifier(),
);

class UnreadMessagesNotifier extends StateNotifier<int> {
  Timer? _timer;

  UnreadMessagesNotifier() : super(0) {
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final r = await ApiClient.instance.get(ApiConfig.conversations);
      final unread = (r.data['unread_total'] as num?)?.toInt() ?? 0;
      if (mounted) state = unread;
    } catch (_) {/* silent */}
  }

  Future<void> refresh() => _fetch();
}

/// AppBar action: chat icon with red unread badge. Tap → /conversations.
class MessagesActionButton extends ConsumerWidget {
  const MessagesActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadMessagesProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Berichten',
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => context.push('/conversations'),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
