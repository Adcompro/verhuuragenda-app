import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/pool/pool_measurement.dart';
import '../../models/pool/pool_task.dart';
import '../../models/pool/pool_chemical.dart';

class PoolHistoryScreen extends StatefulWidget {
  final int accommodationId;
  final String accommodationName;

  const PoolHistoryScreen({
    super.key,
    required this.accommodationId,
    required this.accommodationName,
  });

  @override
  State<PoolHistoryScreen> createState() => _PoolHistoryScreenState();
}

class _PoolHistoryScreenState extends State<PoolHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<PoolMeasurement> _measurements = [];
  List<PoolTask> _tasks = [];
  List<PoolChemical> _chemicals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      switch (_tabController.index) {
        case 0:
          await _loadMeasurements();
          break;
        case 1:
          await _loadTasks();
          break;
        case 2:
          await _loadChemicals();
          break;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMeasurements() async {
    final response = await ApiClient.instance.get(
      ApiConfig.poolMeasurements,
      queryParameters: {'accommodation_id': widget.accommodationId},
    );

    List<dynamic> data;
    if (response.data is Map && response.data['data'] != null) {
      data = response.data['data'] as List;
    } else if (response.data is List) {
      data = response.data as List;
    } else {
      data = [];
    }

    setState(() {
      _measurements = data.map((json) => PoolMeasurement.fromJson(json)).toList();
    });
  }

  Future<void> _loadTasks() async {
    final response = await ApiClient.instance.get(
      ApiConfig.poolTasks,
      queryParameters: {'accommodation_id': widget.accommodationId},
    );

    List<dynamic> data;
    if (response.data is Map && response.data['data'] != null) {
      data = response.data['data'] as List;
    } else if (response.data is List) {
      data = response.data as List;
    } else {
      data = [];
    }

    setState(() {
      _tasks = data.map((json) => PoolTask.fromJson(json)).toList();
    });
  }

  Future<void> _loadChemicals() async {
    final response = await ApiClient.instance.get(
      ApiConfig.poolChemicals,
      queryParameters: {'accommodation_id': widget.accommodationId},
    );

    List<dynamic> data;
    if (response.data is Map && response.data['data'] != null) {
      data = response.data['data'] as List;
    } else if (response.data is List) {
      data = response.data as List;
    } else {
      data = [];
    }

    setState(() {
      _chemicals = data.map((json) => PoolChemical.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.poolHistory),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.measurements, icon: const Icon(Icons.science)),
            Tab(text: l10n.tasks, icon: const Icon(Icons.build)),
            Tab(text: l10n.chemicals, icon: const Icon(Icons.water_drop)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasurementsTab(),
          _buildTasksTab(),
          _buildChemicalsTab(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _tabController.index == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tabController.index == 0) {
      return _buildErrorWidget();
    }

    if (_measurements.isEmpty) {
      return _buildEmptyWidget(l10n.noMeasurementsYet, Icons.science);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _measurements.length,
        itemBuilder: (context, index) {
          final m = _measurements[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(m.measuredAt),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteMeasurement(m),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (m.phValue != null)
                        _buildMeasurementChip(
                          'pH: ${m.phValue}',
                          m.phStatus == 'ok' ? Colors.green : Colors.orange,
                        ),
                      if (m.freeChlorine != null)
                        _buildMeasurementChip(
                          '${l10n.chlorine}: ${m.freeChlorine} ppm',
                          m.chlorineStatus == 'ok' ? Colors.green : Colors.orange,
                        ),
                      if (m.waterTemperature != null)
                        _buildMeasurementChip(
                          '${l10n.temperature}: ${m.waterTemperature}C',
                          Colors.blue,
                        ),
                      if (m.alkalinity != null)
                        _buildMeasurementChip(
                          '${l10n.alkalinity}: ${m.alkalinity} ppm',
                          Colors.grey,
                        ),
                    ],
                  ),
                  if (m.notes != null && m.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      m.notes!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTasksTab() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _tabController.index == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tabController.index == 1) {
      return _buildErrorWidget();
    }

    if (_tasks.isEmpty) {
      return _buildEmptyWidget(l10n.noTasksYet, Icons.build);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final t = _tasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Colors.green),
              ),
              title: Text(t.displayLabel),
              subtitle: Text(_formatDate(t.performedAt)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteTask(t),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChemicalsTab() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _tabController.index == 2) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tabController.index == 2) {
      return _buildErrorWidget();
    }

    if (_chemicals.isEmpty) {
      return _buildEmptyWidget(l10n.noChemicalsYet, Icons.water_drop);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chemicals.length,
        itemBuilder: (context, index) {
          final c = _chemicals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop, color: Colors.purple),
              ),
              title: Text(c.displayLabel),
              subtitle: Text('${c.displayAmount} - ${_formatDate(c.addedAt)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteChemical(c),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeasurementChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l10n.couldNotLoadData(l10n.poolHistory.toLowerCase())),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteMeasurement(PoolMeasurement m) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showDeleteConfirmation(l10n.deleteMeasurementQuestion);
    if (!confirm) return;

    try {
      await ApiClient.instance.delete('${ApiConfig.poolMeasurements}/${m.id}');
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.measurementDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotDelete)),
        );
      }
    }
  }

  Future<void> _deleteTask(PoolTask t) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showDeleteConfirmation(l10n.deleteTaskQuestion);
    if (!confirm) return;

    try {
      await ApiClient.instance.delete('${ApiConfig.poolTasks}/${t.id}');
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotDelete)),
        );
      }
    }
  }

  Future<void> _deleteChemical(PoolChemical c) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showDeleteConfirmation(l10n.deleteChemicalQuestion);
    if (!confirm) return;

    try {
      await ApiClient.instance.delete('${ApiConfig.poolChemicals}/${c.id}');
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chemicalDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotDelete)),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String message) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
