import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../guest/guest_home_screen.dart' show ChatThreadView;

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;
  const ConversationDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  Map<String, dynamic>? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    try {
      final r = await ApiClient.instance.get(
        '${ApiConfig.conversations}/${widget.bookingId}',
      );
      if (!mounted) return;
      setState(() {
        _booking = (r.data['booking'] as Map?)?.cast<String, dynamic>();
        _loading = false;
      });
    } on DioException catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                  child: ChatThreadView(
                    whoami: 'host',
                    messagesEndpoint:
                        '${ApiConfig.conversations}/${widget.bookingId}',
                    sendEndpoint:
                        '${ApiConfig.conversations}/${widget.bookingId}/messages',
                    typingEndpoint:
                        '${ApiConfig.conversations}/${widget.bookingId}/typing',
                    otherIcon: Icons.person,
                    emptyStateText:
                        'Nog geen berichten in deze conversatie.',
                  ),
                ),
              ],
            ),
    );
  }
}
