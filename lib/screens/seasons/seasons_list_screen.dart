import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/season.dart';
import 'season_form_screen.dart';

class SeasonsListScreen extends StatefulWidget {
  const SeasonsListScreen({super.key});

  @override
  State<SeasonsListScreen> createState() => _SeasonsListScreenState();
}

class _SeasonsListScreenState extends State<SeasonsListScreen> {
  List<Season> _seasons = [];
  bool _isLoading = true;
  String? _error;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(ApiConfig.seasons);
      final List<dynamic> data = response.data['seasons'] ?? [];

      setState(() {
        _seasons = data.map((json) => Season.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Season> get _filteredSeasons {
    return _seasons.where((s) => s.year == _selectedYear).toList();
  }

  Future<void> _navigateToForm(Season? season) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SeasonFormScreen(season: season),
      ),
    );
    if (result == true) {
      _loadSeasons();
    }
  }

  Future<void> _deleteSeason(Season season) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSeasonTitle),
        content: Text(l10n.deleteSeasonConfirmMessage(season.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.instance.delete('${ApiConfig.seasons}/${season.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.seasonDeleted), backgroundColor: Colors.green),
          );
        }
        _loadSeasons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.couldNotDeleteError(e.toString())), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seasons),
        actions: [
          // Year selector
          PopupMenuButton<int>(
            initialValue: _selectedYear,
            onSelected: (year) => setState(() => _selectedYear = year),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('$_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (context) => [
              for (int year = DateTime.now().year - 1; year <= DateTime.now().year + 2; year++)
                PopupMenuItem(value: year, child: Text('$year')),
            ],
          ),
        ],
      ),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSeason),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(l10n.couldNotLoadSeasonsError(_error!), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadSeasons,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final filteredSeasons = _filteredSeasons;

    if (filteredSeasons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noSeasonsForYear(_selectedYear),
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.addSeasonsHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSeasons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSeasons.length,
        itemBuilder: (context, index) {
          final season = filteredSeasons[index];
          return _SeasonCard(
            season: season,
            onTap: () => _navigateToForm(season),
            onDelete: () => _deleteSeason(season),
          );
        },
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final Season season;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SeasonCard({
    required this.season,
    required this.onTap,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (season.type) {
      case 'low':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (season.type) {
      case 'low':
        return Icons.ac_unit;
      case 'high':
        return Icons.wb_sunny;
      default:
        return Icons.cloud;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            season.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            season.typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: _typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(season.startDate)} - ${_formatDate(season.endDate)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
