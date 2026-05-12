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
  bool _blocked = false;

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
        _blocked = r.data['blocked'] == true;
        _loading = false;
      });
    } on DioException catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock() async {
    final guestName = _booking?['guest_name']?.toString() ?? 'deze gast';
    if (!_blocked) {
      // Confirm block
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('$guestName blokkeren?'),
          content: const Text(
            'Geblokkeerde gasten kunnen geen berichten meer naar je sturen en hun berichten zijn niet meer zichtbaar. Je kunt dit altijd weer opheffen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Blokkeren'),
            ),
          ],
        ),
      );
      if (ok != true) return;

      try {
        await ApiClient.instance.post(
          '${ApiConfig.conversations}/${widget.bookingId}/block',
        );
        if (!mounted) return;
        setState(() => _blocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$guestName is geblokkeerd.')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Blokkeren mislukt: $e')),
          );
        }
      }
    } else {
      try {
        await ApiClient.instance.delete(
          '${ApiConfig.conversations}/${widget.bookingId}/block',
        );
        if (!mounted) return;
        setState(() => _blocked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blokkade opgeheven voor $guestName.')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opheffen mislukt: $e')),
          );
        }
      }
    }
  }

  void _showReportInfo() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bericht melden'),
        content: const Text(
          'Houd een bericht ingedrukt om het te melden als ongepast. We bekijken meldingen binnen 24 uur en verwijderen ongepaste inhoud direct.\n\n'
          'CasaMio heeft een nultolerantie voor haatdragende, beledigende of intimiderende inhoud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Begrepen'),
          ),
        ],
      ),
    );
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opties',
            onSelected: (value) {
              if (value == 'block') {
                _toggleBlock();
              } else if (value == 'report') {
                _showReportInfo();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    const Text('Bericht melden…'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      _blocked ? Icons.person_outline : Icons.block,
                      size: 20,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 12),
                    Text(_blocked ? 'Blokkade opheffen' : 'Gast blokkeren'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_blocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red[50],
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red[800], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Je hebt deze gast geblokkeerd. Berichten heen en weer zijn uitgeschakeld.',
                            style: TextStyle(
                                color: Colors.red[800], fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _toggleBlock,
                          child: const Text('Opheffen'),
                        ),
                      ],
                    ),
                  ),
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
