import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';

class Campaign {
  final int id;
  final String name;
  final String subject;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int totalRecipients;
  final int sentCount;
  final int openedCount;
  final int clickedCount;
  final int unsubscribedCount;
  final int bouncedCount;

  Campaign({
    required this.id,
    required this.name,
    required this.subject,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    required this.totalRecipients,
    required this.sentCount,
    required this.openedCount,
    required this.clickedCount,
    required this.unsubscribedCount,
    required this.bouncedCount,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'draft',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'])
          : null,
      sentAt: json['sent_at'] != null || json['completed_at'] != null
          ? DateTime.tryParse(json['sent_at'] ?? json['completed_at'])
          : null,
      totalRecipients: json['total_recipients'] ?? 0,
      sentCount: json['sent_count'] ?? 0,
      openedCount: json['opened_count'] ?? 0,
      clickedCount: json['clicked_count'] ?? 0,
      unsubscribedCount: json['unsubscribed_count'] ?? 0,
      bouncedCount: json['bounced_count'] ?? 0,
    );
  }

  double get openRate =>
      sentCount > 0 ? (openedCount / sentCount * 100) : 0;

  double get clickRate =>
      openedCount > 0 ? (clickedCount / openedCount * 100) : 0;

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Concept';
      case 'scheduled':
        return 'Gepland';
      case 'sending':
        return 'Verzenden...';
      case 'sent':
        return 'Verzonden';
      case 'paused':
        return 'Gepauzeerd';
      case 'cancelled':
        return 'Geannuleerd';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'scheduled':
        return Colors.blue;
      case 'sending':
        return Colors.orange;
      case 'sent':
        return Colors.green;
      case 'paused':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'draft':
        return Icons.edit_outlined;
      case 'scheduled':
        return Icons.schedule;
      case 'sending':
        return Icons.send;
      case 'sent':
        return Icons.check_circle;
      case 'paused':
        return Icons.pause_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.mail_outline;
    }
  }
}

class CampaignsListScreen extends ConsumerStatefulWidget {
  const CampaignsListScreen({super.key});

  @override
  ConsumerState<CampaignsListScreen> createState() =>
      _CampaignsListScreenState();
}

class _CampaignsListScreenState extends ConsumerState<CampaignsListScreen> {
  List<Campaign> _campaigns = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'Alle'},
    {'value': 'sent', 'label': 'Verzonden'},
    {'value': 'scheduled', 'label': 'Gepland'},
    {'value': 'draft', 'label': 'Concepten'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.baseUrl}/campaigns',
        queryParameters: _statusFilter != 'all' ? {'status': _statusFilter} : null,
      );

      final data = response.data;
      List<dynamic> campaignsData = [];

      if (data is Map && data['data'] != null) {
        campaignsData = data['data'] as List;
      } else if (data is List) {
        campaignsData = data;
      }

      setState(() {
        _campaigns = campaignsData
            .map((json) => Campaign.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon campagnes niet laden';
        _isLoading = false;
      });
    }
  }

  List<Campaign> get _filteredCampaigns {
    if (_statusFilter == 'all') return _campaigns;
    return _campaigns.where((c) => c.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campagnes'),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Campagnes aanmaken en bewerken doe je via de website. Hier kun je de statistieken bekijken.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _statusFilter == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _statusFilter = filter['value']!);
                      _loadCampaigns();
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCampaigns,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    if (_filteredCampaigns.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCampaigns,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCampaigns.length,
        itemBuilder: (context, index) {
          return _buildCampaignCard(_filteredCampaigns[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Geen campagnes gevonden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Maak je eerste campagne aan via de website om je gasten te bereiken.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCampaignDetail(campaign),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.subject,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: campaign.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          campaign.statusIcon,
                          size: 14,
                          color: campaign.statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          campaign.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: campaign.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Date info
              if (campaign.sentAt != null || campaign.scheduledAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      campaign.sentAt != null ? Icons.send : Icons.schedule,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      campaign.sentAt != null
                          ? 'Verzonden op ${_formatDate(campaign.sentAt!)}'
                          : 'Gepland voor ${_formatDate(campaign.scheduledAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],

              // Stats (only for sent campaigns)
              if (campaign.status == 'sent' && campaign.sentCount > 0) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatItem(
                      Icons.send_outlined,
                      '${campaign.sentCount}',
                      'Verzonden',
                      Colors.blue,
                    ),
                    _buildStatItem(
                      Icons.visibility_outlined,
                      '${campaign.openRate.toStringAsFixed(1)}%',
                      'Geopend',
                      Colors.green,
                    ),
                    _buildStatItem(
                      Icons.touch_app_outlined,
                      '${campaign.clickRate.toStringAsFixed(1)}%',
                      'Geklikt',
                      Colors.orange,
                    ),
                    _buildStatItem(
                      Icons.unsubscribe_outlined,
                      '${campaign.unsubscribedCount}',
                      'Afgemeld',
                      Colors.red,
                    ),
                  ],
                ),
              ],

              // Recipients count for non-sent
              if (campaign.status != 'sent' && campaign.totalRecipients > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '${campaign.totalRecipients} ontvangers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showCampaignDetail(Campaign campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: campaign.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.campaign,
                              color: campaign.statusColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: campaign.statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    campaign.statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: campaign.statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Subject
                      _buildDetailSection(
                        'Onderwerp',
                        campaign.subject,
                        Icons.subject,
                      ),

                      // Date
                      if (campaign.sentAt != null)
                        _buildDetailSection(
                          'Verzonden op',
                          _formatDateTime(campaign.sentAt!),
                          Icons.send,
                        ),
                      if (campaign.scheduledAt != null && campaign.sentAt == null)
                        _buildDetailSection(
                          'Gepland voor',
                          _formatDateTime(campaign.scheduledAt!),
                          Icons.schedule,
                        ),

                      // Recipients
                      _buildDetailSection(
                        'Ontvangers',
                        '${campaign.totalRecipients} contacten',
                        Icons.people_outline,
                      ),

                      // Stats section (only for sent)
                      if (campaign.status == 'sent' && campaign.sentCount > 0) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Statistieken',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              'Verzonden',
                              campaign.sentCount.toString(),
                              Icons.send,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Geopend',
                              '${campaign.openedCount} (${campaign.openRate.toStringAsFixed(1)}%)',
                              Icons.visibility,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Geklikt',
                              '${campaign.clickedCount} (${campaign.clickRate.toStringAsFixed(1)}%)',
                              Icons.touch_app,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Afgemeld',
                              campaign.unsubscribedCount.toString(),
                              Icons.unsubscribe,
                              Colors.red,
                            ),
                          ],
                        ),

                        // Bounced if any
                        if (campaign.bouncedCount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.amber[700]),
                                const SizedBox(width: 12),
                                Text(
                                  '${campaign.bouncedCount} emails zijn niet afgeleverd (bounced)',
                                  style: TextStyle(color: Colors.amber[900]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 24),

                      // Website link
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Open de website om deze campagne te bewerken'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Bekijken op website'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} om ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
