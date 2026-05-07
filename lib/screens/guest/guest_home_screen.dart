import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';

class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient.instance.get(ApiConfig.guestBooking);
      if (!mounted) return;
      final data = Map<String, dynamic>.from(r.data as Map);
      // Surface host's brand name everywhere via the provider.
      final brand = (data['branding'] as Map?)?['app_name'] as String?;
      if (brand != null) {
        ref.read(brandingProvider.notifier).set(brand);
      }
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kon gegevens niet laden';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = _data?['accommodation'] as Map<String, dynamic>?;
    final accName = acc?['name'] as String? ?? 'Mijn verblijf';

    return Scaffold(
      appBar: AppBar(
        title: Text(accName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Uitloggen',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.event), text: 'Boeking'),
            Tab(icon: Icon(Icons.home_outlined), text: 'Verblijf'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Betaling'),
            Tab(icon: Icon(Icons.chat_outlined), text: 'Chat'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[400], size: 48),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Opnieuw proberen'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _BookingTab(data: _data!),
                      _StayInfoTab(data: _data!),
                      _PaymentTab(data: _data!),
                      const _ChatTab(),
                    ],
                  ),
                ),
    );
  }
}

// ============= Boeking-tab =============

class _BookingTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BookingTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final booking = (data['booking'] as Map?)?.cast<String, dynamic>() ?? {};
    final guest = (data['guest'] as Map?)?.cast<String, dynamic>();
    final acc = (data['accommodation'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          icon: Icons.calendar_month,
          title: 'Verblijfsperiode',
          color: AppTheme.primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateColumn(
                      label: 'Check-in',
                      date: booking['check_in'] as String?,
                      icon: Icons.login,
                      color: Colors.green[700],
                    ),
                  ),
                  Container(width: 1, height: 56, color: Colors.grey[300]),
                  Expanded(
                    child: _DateColumn(
                      label: 'Check-out',
                      date: booking['check_out'] as String?,
                      icon: Icons.logout,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const Divider(),
              _kvRow('Aantal nachten', '${booking['nights'] ?? '—'}'),
              _kvRow('Volwassenen', '${booking['adults'] ?? 0}'),
              if ((booking['children'] ?? 0) > 0)
                _kvRow('Kinderen', '${booking['children']}'),
              if ((booking['babies'] ?? 0) > 0)
                _kvRow("Baby's", '${booking['babies']}'),
              if (booking['has_pet'] == true)
                _kvRow('Huisdier', booking['pet_description']?.toString() ?? 'Ja'),
              _kvRow('Boekingnummer',
                  booking['booking_number']?.toString() ?? '—'),
              _kvRow('Status', _statusLabel(booking['status'] as String?)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.house_outlined,
          title: 'Accommodatie',
          color: Colors.deepPurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                acc['name']?.toString() ?? '—',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (acc['address'] != null || acc['city'] != null)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [acc['address'], acc['city'], acc['region']]
                            .where((e) => e != null && e.toString().isNotEmpty)
                            .join(', '),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (acc['max_guests'] != null)
                    _iconChip(Icons.people, '${acc['max_guests']} gasten'),
                  if (acc['bedrooms'] != null)
                    _iconChip(Icons.bed, '${acc['bedrooms']} slaapk.'),
                  if (acc['bathrooms'] != null)
                    _iconChip(Icons.bathtub, '${acc['bathrooms']} badk.'),
                ],
              ),
            ],
          ),
        ),
        if (guest != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.person_outline,
            title: 'Hoofdgast',
            color: Colors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest['name']?.toString() ?? '—',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (guest['email'] != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.email_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(guest['email'].toString()),
                  ]),
                ],
                if (guest['phone'] != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(guest['phone'].toString()),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'confirmed':
        return 'Bevestigd';
      case 'option':
        return 'Optie';
      case 'inquiry':
        return 'Aanvraag';
      case 'completed':
        return 'Afgerond';
      case 'cancelled':
        return 'Geannuleerd';
    }
    return s ?? '—';
  }
}

// ============= Verblijf-info tab =============

class _StayInfoTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StayInfoTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final acc = (data['accommodation'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (acc['checkin_time_from'] != null || acc['checkout_time'] != null)
          _SectionCard(
            icon: Icons.schedule,
            title: 'Aankomst & vertrek',
            color: Colors.indigo,
            child: Row(
              children: [
                if (acc['checkin_time_from'] != null)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.login, color: Colors.green[700], size: 28),
                        const SizedBox(height: 4),
                        Text('Inchecken',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        Text(
                          acc['checkin_time_until'] != null
                              ? '${_hm(acc['checkin_time_from'])} – ${_hm(acc['checkin_time_until'])}'
                              : 'vanaf ${_hm(acc['checkin_time_from'])}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                if (acc['checkout_time'] != null)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.logout, color: Colors.red[700], size: 28),
                        const SizedBox(height: 4),
                        Text('Uitchecken',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        Text(
                          'tot ${_hm(acc['checkout_time'])}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (acc['wifi_network'] != null || acc['wifi_password'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.wifi,
            title: 'WiFi',
            color: Colors.blue[700]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (acc['wifi_network'] != null)
                  _CopyableField(
                    label: 'Netwerk',
                    value: acc['wifi_network'].toString(),
                  ),
                if (acc['wifi_password'] != null) ...[
                  const SizedBox(height: 8),
                  _CopyableField(
                    label: 'Wachtwoord',
                    value: acc['wifi_password'].toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (acc['alarm_code'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.lock_outline,
            title: 'Alarmcode',
            color: Colors.deepOrange,
            child: _CopyableField(
              label: 'Code',
              value: acc['alarm_code'].toString(),
            ),
          ),
        ],
        if (acc['key_instructions'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.key_outlined,
            title: 'Sleutelinstructies',
            color: Colors.amber[800]!,
            child: Text(acc['key_instructions'].toString()),
          ),
        ],
        if (acc['arrival_instructions'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.directions,
            title: 'Aankomstinstructies',
            color: Colors.green[700]!,
            child: Text(acc['arrival_instructions'].toString()),
          ),
        ],
        if (acc['house_rules'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.rule,
            title: 'Huisregels',
            color: Colors.purple,
            child: Text(acc['house_rules'].toString()),
          ),
        ],
        if (acc['local_tips'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Lokale tips',
            color: Colors.cyan[700]!,
            child: Text(acc['local_tips'].toString()),
          ),
        ],
        if (acc['emergency_contacts'] != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.emergency_outlined,
            title: 'Noodcontacten',
            color: Colors.red[700]!,
            child: Text(acc['emergency_contacts'].toString()),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _hm(dynamic raw) {
    final s = raw?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}

// ============= Betaal-tab =============

class _PaymentTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PaymentTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final p = (data['payments'] as Map?)?.cast<String, dynamic>() ?? {};
    final breakdown = (p['breakdown'] as List?)?.cast<dynamic>() ?? [];
    final transactions = (p['transactions'] as List?)?.cast<dynamic>() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppTheme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Totaalbedrag',
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
                Text(
                  '€${_n(p['total'])}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _amountTile(
                        'Betaald',
                        p['paid'],
                        Colors.greenAccent[100]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _amountTile(
                        'Openstaand',
                        p['balance'],
                        Colors.orangeAccent[100]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.receipt_long,
          title: 'Specificatie',
          color: Colors.indigo,
          child: Column(
            children: breakdown
                .where((b) => (b['amount'] as num?) != null && (b['amount'] as num) > 0)
                .map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(b['label']?.toString() ?? '—')),
                          Text('€${_n(b['amount'])}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.history,
          title: 'Transacties',
          color: Colors.teal,
          child: transactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nog geen betalingen geregistreerd.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : Column(
                  children: transactions.map((t) {
                    final isRefund = t['type'] == 'refund';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        isRefund ? Icons.undo : Icons.check_circle,
                        color: isRefund ? Colors.orange : Colors.green,
                      ),
                      title: Text(
                        '${isRefund ? '−' : '+'} €${_n(t['amount'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRefund ? Colors.orange[800] : Colors.green[800],
                        ),
                      ),
                      subtitle: Text(
                        '${t['paid_at'] ?? '—'} · ${t['method'] ?? 'Betaling'}',
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _amountTile(String label, dynamic value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '€${_n(value)}',
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _n(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return d.toStringAsFixed(2);
  }
}

// ============= Chat-tab =============

class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
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
      final r = await ApiClient.instance.get(ApiConfig.guestMessages);
      final data = (r.data['data'] as List?)?.cast<dynamic>() ?? [];
      if (!mounted) return;
      setState(() {
        _messages = data.map((m) => Map<String, dynamic>.from(m as Map)).toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted && initial) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final r = await ApiClient.instance.post(
        ApiConfig.guestMessages,
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Stuur een bericht naar je verhuurder',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
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
                    final isMe = m['sender_type'] == 'guest';
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
                      hintText: 'Typ een bericht...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              child: Icon(Icons.support_agent,
                  size: 16, color: Colors.grey[700]),
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

// ============= Helpers =============

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  final String label;
  final String? date;
  final IconData icon;
  final Color? color;

  const _DateColumn({
    required this.label,
    required this.date,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          date ?? '—',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  final String label;
  final String value;
  const _CopyableField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Kopieer',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label gekopieerd')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

Widget _kvRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

Widget _iconChip(IconData icon, String text) {
  return Builder(
    builder: (context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    ),
  );
}
