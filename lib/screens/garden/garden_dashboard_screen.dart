import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/garden/garden_task.dart';
import 'garden_task_form.dart';
import 'garden_tasks_screen.dart';

class GardenDashboardScreen extends StatefulWidget {
  const GardenDashboardScreen({super.key});

  @override
  State<GardenDashboardScreen> createState() => _GardenDashboardScreenState();
}

class _GardenDashboardScreenState extends State<GardenDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _accommodations = [];
  int? _selectedAccommodationId;

  // Dashboard data
  Map<String, int> _stats = {'overdue': 0, 'this_week': 0, 'completed_this_month': 0};
  List<GardenTask> _upcomingTasks = [];
  List<GardenTask> _recentlyCompleted = [];

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
        _accommodations = data.map((a) => {'id': a['id'], 'name': a['name']}).toList();
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
        '${ApiConfig.gardenDashboard}/$_selectedAccommodationId',
      );
      final data = response.data['data'];

      setState(() {
        _stats = {
          'overdue': data['stats']['overdue'] ?? 0,
          'this_week': data['stats']['this_week'] ?? 0,
          'completed_this_month': data['stats']['completed_this_month'] ?? 0,
        };
        _upcomingTasks = (data['upcoming_tasks'] as List)
            .map((t) => GardenTask.fromJson(t))
            .toList();
        _recentlyCompleted = (data['recently_completed'] as List)
            .map((t) => GardenTask.fromJson(t))
            .toList();
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gardenMaintenance),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => _navigateToTasks(),
            tooltip: l10n.gardenTasks,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _buildBody(l10n, theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToNewTask,
        icon: const Icon(Icons.add),
        label: Text(l10n.newGardenTask),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
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
        child: Text(l10n.noAccommodations),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Accommodation selector
        _buildAccommodationSelector(l10n),
        const SizedBox(height: 24),

        // Stats cards
        _buildStatsRow(l10n, theme),
        const SizedBox(height: 24),

        // Upcoming tasks
        _buildSectionHeader(l10n.upcomingTasks, Icons.schedule),
        const SizedBox(height: 8),
        if (_upcomingTasks.isEmpty)
          _buildEmptyCard(l10n.noUpcomingTasks)
        else
          ..._upcomingTasks.map((task) => _buildTaskCard(task, l10n, theme)),
        const SizedBox(height: 24),

        // Recently completed
        _buildSectionHeader(l10n.recentlyCompleted, Icons.check_circle_outline),
        const SizedBox(height: 8),
        if (_recentlyCompleted.isEmpty)
          _buildEmptyCard(l10n.noCompletedTasks)
        else
          ..._recentlyCompleted.map((task) => _buildCompletedCard(task, l10n, theme)),
        const SizedBox(height: 24),

        // View all tasks button
        OutlinedButton.icon(
          onPressed: _navigateToTasks,
          icon: const Icon(Icons.list),
          label: Text(l10n.viewAllTasks),
        ),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildAccommodationSelector(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<int>(
          value: _selectedAccommodationId,
          decoration: InputDecoration(
            labelText: l10n.accommodation,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.home_work),
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
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _stats['overdue']!,
            l10n.overdue,
            Colors.red,
            Icons.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            _stats['this_week']!,
            l10n.thisWeek,
            Colors.orange,
            Icons.event,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            _stats['completed_this_month']!,
            l10n.thisMonth,
            Colors.green,
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(int value, String label, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(GardenTask task, AppLocalizations l10n, ThemeData theme) {
    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToEditTask(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Category icon
              Icon(
                _getCategoryIcon(task.category),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.categoryLabel ?? task.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Due date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    task.dueDateFormatted ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (task.isOverdue)
                    Text(
                      l10n.overdue,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard(GardenTask task, AppLocalizations l10n, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[400],
            ),
            const SizedBox(width: 12),
            Icon(
              _getCategoryIcon(task.category),
              color: Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Text(
              task.completedAtFormatted ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'mowing':
        return Icons.grass;
      case 'pruning':
        return Icons.content_cut;
      case 'weeding':
        return Icons.eco;
      case 'fertilizing':
        return Icons.compost;
      case 'watering':
        return Icons.water_drop;
      case 'leaf_removal':
        return Icons.energy_savings_leaf;
      case 'hedge_trimming':
        return Icons.park;
      case 'planting':
        return Icons.local_florist;
      case 'seeding':
        return Icons.grain;
      case 'composting':
        return Icons.recycling;
      case 'tool_maintenance':
        return Icons.build;
      default:
        return Icons.more_horiz;
    }
  }

  void _navigateToNewTask() async {
    if (_selectedAccommodationId == null) return;

    final accommodation = _accommodations.firstWhere(
      (a) => a['id'] == _selectedAccommodationId,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GardenTaskForm(
          accommodationId: _selectedAccommodationId!,
          accommodationName: accommodation['name'],
        ),
      ),
    );

    if (result == true) {
      _loadDashboard();
    }
  }

  void _navigateToEditTask(GardenTask task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GardenTaskForm(
          accommodationId: task.accommodationId,
          accommodationName: task.accommodationName ?? '',
          task: task,
        ),
      ),
    );

    if (result == true) {
      _loadDashboard();
    }
  }

  void _navigateToTasks() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GardenTasksScreen(
          accommodationId: _selectedAccommodationId,
          accommodationName: _accommodations.firstWhere(
            (a) => a['id'] == _selectedAccommodationId,
            orElse: () => {'name': ''},
          )['name'],
        ),
      ),
    );

    if (result == true) {
      _loadDashboard();
    }
  }
}
