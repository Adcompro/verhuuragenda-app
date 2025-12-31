import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/garden/garden_task.dart';
import 'garden_task_form.dart';

class GardenTasksScreen extends StatefulWidget {
  final int? accommodationId;
  final String? accommodationName;

  const GardenTasksScreen({
    super.key,
    this.accommodationId,
    this.accommodationName,
  });

  @override
  State<GardenTasksScreen> createState() => _GardenTasksScreenState();
}

class _GardenTasksScreenState extends State<GardenTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<GardenTask> _todoTasks = [];
  List<GardenTask> _completedTasks = [];
  List<GardenTask> _recurringTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadCurrentTab();
      }
    });
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTab() async {
    switch (_tabController.index) {
      case 0:
        await _loadTodoTasks();
        break;
      case 1:
        await _loadCompletedTasks();
        break;
      case 2:
        await _loadRecurringTasks();
        break;
    }
  }

  Future<void> _loadTodoTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url = '${ApiConfig.gardenTasks}?status=todo,in_progress';
      if (widget.accommodationId != null) {
        url += '&accommodation_id=${widget.accommodationId}';
      }

      final response = await ApiClient.instance.get(url);
      final data = response.data['data'] as List;

      setState(() {
        _todoTasks = data.map((t) => GardenTask.fromJson(t)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompletedTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url = '${ApiConfig.gardenTasks}?status=completed';
      if (widget.accommodationId != null) {
        url += '&accommodation_id=${widget.accommodationId}';
      }

      final response = await ApiClient.instance.get(url);
      final data = response.data['data'] as List;

      setState(() {
        _completedTasks = data.map((t) => GardenTask.fromJson(t)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecurringTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url = ApiConfig.gardenRecurring;
      if (widget.accommodationId != null) {
        url += '?accommodation_id=${widget.accommodationId}';
      }

      final response = await ApiClient.instance.get(url);
      final data = response.data['data'] as List;

      setState(() {
        _recurringTasks = data.map((t) => GardenTask.fromJson(t)).toList();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gardenTasks),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.todoTasks),
            Tab(text: l10n.completedTasks),
            Tab(text: l10n.recurringTasks),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_todoTasks, l10n, showComplete: true),
          _buildTaskList(_completedTasks, l10n, showComplete: false),
          _buildRecurringList(l10n),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(List<GardenTask> tasks, AppLocalizations l10n, {required bool showComplete}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentTab,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showComplete ? Icons.check_circle_outline : Icons.task_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              showComplete ? l10n.noTodoTasks : l10n.noCompletedTasks,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCurrentTab,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(task, l10n, showComplete: showComplete);
        },
      ),
    );
  }

  Widget _buildTaskCard(GardenTask task, AppLocalizations l10n, {required bool showComplete}) {
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
                height: 60,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Category icon
              Icon(
                _getCategoryIcon(task.category),
                color: task.isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.home_work, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.accommodationName ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (task.dueDate != null || task.completedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              task.isCompleted ? Icons.check_circle : Icons.event,
                              size: 14,
                              color: task.isOverdue ? Colors.red : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.isCompleted
                                  ? task.completedAtFormatted ?? ''
                                  : task.dueDateFormatted ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isOverdue ? Colors.red : Colors.grey[600],
                              ),
                            ),
                            if (task.isOverdue) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.overdue,
                                  style: const TextStyle(fontSize: 10, color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Complete button
              if (showComplete && !task.isCompleted)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                  onPressed: () => _completeTask(task),
                  tooltip: l10n.markComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringList(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentTab,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_recurringTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noRecurringTasks,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCurrentTab,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recurringTasks.length,
        itemBuilder: (context, index) {
          final task = _recurringTasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(_getCategoryIcon(task.category)),
              title: Text(task.title),
              subtitle: Text(
                '${task.accommodationName ?? ''} • ${task.recurringIntervalLabel ?? task.recurringInterval ?? ''}',
              ),
              trailing: const Icon(Icons.repeat),
              onTap: () => _navigateToEditTask(task),
            ),
          );
        },
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

  Future<void> _completeTask(GardenTask task) async {
    try {
      await ApiClient.instance.post('${ApiConfig.gardenTasks}/${task.id}/complete');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.taskCompleted)),
      );
      _loadCurrentTab();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _navigateToNewTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GardenTaskForm(
          accommodationId: widget.accommodationId,
          accommodationName: widget.accommodationName,
        ),
      ),
    );

    if (result == true) {
      _loadCurrentTab();
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
      _loadCurrentTab();
    }
  }
}
