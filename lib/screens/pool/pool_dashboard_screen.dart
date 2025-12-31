import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/pool/pool_measurement.dart';
import '../../utils/responsive.dart';
import 'pool_measurement_form.dart';
import 'pool_task_form.dart';
import 'pool_chemical_form.dart';
import 'pool_history_screen.dart';

class PoolDashboardScreen extends StatefulWidget {
  const PoolDashboardScreen({super.key});

  @override
  State<PoolDashboardScreen> createState() => _PoolDashboardScreenState();
}

class _PoolDashboardScreenState extends State<PoolDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _accommodations = [];
  int? _selectedAccommodationId;
  Map<String, dynamic>? _dashboardData;
  IdealRanges _idealRanges = IdealRanges();

  @override
  void initState() {
    super.initState();
    _loadAccommodations();
  }

  Future<void> _loadAccommodations() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.accommodations);
      List<dynamic> data;
      if (response.data is Map && response.data['data'] != null) {
        data = response.data['data'] as List;
      } else if (response.data is List) {
        data = response.data as List;
      } else {
        data = [];
      }

      setState(() {
        _accommodations = data.map((a) => {
          'id': a['id'],
          'name': a['name'] ?? '',
        }).toList();
        if (_accommodations.isNotEmpty) {
          _selectedAccommodationId = _accommodations.first['id'];
          _loadDashboard();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDashboard() async {
    if (_selectedAccommodationId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.poolDashboard}/$_selectedAccommodationId',
      );

      setState(() {
        _dashboardData = response.data;
        if (response.data['ideal_ranges'] != null) {
          _idealRanges = IdealRanges.fromJson(response.data['ideal_ranges']);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = Responsive.useWideLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.poolMaintenance),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _selectedAccommodationId != null
                ? () => _navigateToHistory()
                : null,
            tooltip: l10n.viewHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Accommodation selector
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.home, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedAccommodationId,
                      decoration: InputDecoration(
                        labelText: l10n.selectAccommodation,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _accommodations.map((a) {
                        return DropdownMenuItem<int>(
                          value: a['id'],
                          child: Text(a['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccommodationId = value;
                        });
                        _loadDashboard();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isTablet) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.couldNotLoadData(l10n.poolMaintenance.toLowerCase())),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_accommodations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pool, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              l10n.noAccommodationsYet,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last measurement card
            _buildLastMeasurementCard(),
            const SizedBox(height: 24),

            // Quick actions
            Text(
              l10n.actions,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(isTablet),
            const SizedBox(height: 24),

            // Recent activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentActivity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToHistory(),
                  child: Text(l10n.viewHistory),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMeasurementCard() {
    final l10n = AppLocalizations.of(context)!;
    final lastMeasurement = _dashboardData?['last_measurement'];

    if (lastMeasurement == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.science_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noMeasurementsYet,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _navigateToMeasurementForm(),
                icon: const Icon(Icons.add),
                label: Text(l10n.newMeasurement),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.lastMeasurement,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  lastMeasurement['measured_at_relative'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMeasurementTile(
                  label: 'pH',
                  value: lastMeasurement['ph_value']?.toString() ?? '-',
                  status: lastMeasurement['ph_status'],
                  idealMin: _idealRanges.phMin,
                  idealMax: _idealRanges.phMax,
                ),
                _buildMeasurementTile(
                  label: l10n.chlorine,
                  value: lastMeasurement['free_chlorine']?.toString() ?? '-',
                  unit: 'ppm',
                  status: lastMeasurement['chlorine_status'],
                  idealMin: _idealRanges.chlorineMin,
                  idealMax: _idealRanges.chlorineMax,
                ),
                _buildMeasurementTile(
                  label: l10n.temperature,
                  value: lastMeasurement['water_temperature']?.toString() ?? '-',
                  unit: 'C',
                  status: null,
                  idealMin: _idealRanges.tempMin,
                  idealMax: _idealRanges.tempMax,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTile({
    required String label,
    required String value,
    String? unit,
    String? status,
    required double idealMin,
    required double idealMax,
  }) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.remove;

    if (status == 'ok') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'low' || status == 'high') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (value != '-') {
      // Check if value is in range for temperature (no status from API)
      final numValue = double.tryParse(value);
      if (numValue != null) {
        if (numValue >= idealMin && numValue <= idealMax) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.warning;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              if (unit != null)
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Icon(statusIcon, size: 20, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isTablet) {
    final l10n = AppLocalizations.of(context)!;

    final actions = [
      _QuickAction(
        icon: Icons.science,
        label: l10n.newMeasurement,
        color: Colors.blue,
        onTap: () => _navigateToMeasurementForm(),
      ),
      _QuickAction(
        icon: Icons.build,
        label: l10n.addTask,
        color: Colors.green,
        onTap: () => _navigateToTaskForm(),
      ),
      _QuickAction(
        icon: Icons.water_drop,
        label: l10n.addChemical,
        color: Colors.purple,
        onTap: () => _navigateToChemicalForm(),
      ),
    ];

    if (isTablet) {
      return Row(
        children: actions.map((action) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(action),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildActionButton(action),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(_QuickAction action) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final l10n = AppLocalizations.of(context)!;
    final recentActivity = _dashboardData?['recent_activity'] as List? ?? [];

    if (recentActivity.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.noRecentActivity,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: recentActivity.take(5).map((item) {
          IconData icon;
          Color iconColor;

          switch (item['type']) {
            case 'measurement':
              icon = Icons.science;
              iconColor = Colors.blue;
              break;
            case 'task':
              icon = Icons.build;
              iconColor = Colors.green;
              break;
            case 'chemical':
              icon = Icons.water_drop;
              iconColor = Colors.purple;
              break;
            default:
              icon = Icons.circle;
              iconColor = Colors.grey;
          }

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(item['description'] ?? ''),
            subtitle: Text(item['date_relative'] ?? ''),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToMeasurementForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoolMeasurementForm(
          accommodationId: _selectedAccommodationId!,
          accommodationName: _accommodations.firstWhere(
            (a) => a['id'] == _selectedAccommodationId,
          )['name'],
        ),
      ),
    );
    if (result == true) {
      _loadDashboard();
    }
  }

  void _navigateToTaskForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoolTaskForm(
          accommodationId: _selectedAccommodationId!,
          accommodationName: _accommodations.firstWhere(
            (a) => a['id'] == _selectedAccommodationId,
          )['name'],
        ),
      ),
    );
    if (result == true) {
      _loadDashboard();
    }
  }

  void _navigateToChemicalForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoolChemicalForm(
          accommodationId: _selectedAccommodationId!,
          accommodationName: _accommodations.firstWhere(
            (a) => a['id'] == _selectedAccommodationId,
          )['name'],
        ),
      ),
    );
    if (result == true) {
      _loadDashboard();
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoolHistoryScreen(
          accommodationId: _selectedAccommodationId!,
          accommodationName: _accommodations.firstWhere(
            (a) => a['id'] == _selectedAccommodationId,
          )['name'],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
