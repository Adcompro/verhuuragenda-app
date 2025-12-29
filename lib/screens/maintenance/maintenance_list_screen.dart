import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/maintenance.dart';
import '../../utils/responsive.dart';
import 'maintenance_form_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  bool _isLoading = true;
  String? _error;
  List<MaintenanceTask> _tasks = [];
  String _statusFilter = 'open'; // open, completed, all
  String _priorityFilter = 'all'; // all, urgent, high, medium, low

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{};
      if (_statusFilter == 'open') {
        queryParams['status'] = 'open,in_progress,waiting';
      } else if (_statusFilter == 'completed') {
        queryParams['status'] = 'completed';
      }
      if (_priorityFilter != 'all') {
        queryParams['priority'] = _priorityFilter;
      }

      final response = await ApiClient.instance.get(
        ApiConfig.maintenance,
        queryParameters: queryParams,
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
        _tasks = data.map((json) => MaintenanceTask.fromJson(json)).toList();
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
        title: Text(l10n.maintenanceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          // Extra add button in app bar for iPad (easier to reach)
          if (isTablet)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add),
                label: Text(l10n.newTask),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(),
          icon: const Icon(Icons.add),
          label: Text(l10n.newTask),
        ),
      ),
      floatingActionButtonLocation: isTablet
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFilters() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(l10n.filterOpen, 'open', _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                  _loadTasks();
                }),
                const SizedBox(width: 8),
                _buildFilterChip(l10n.filterCompleted, 'completed', _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                  _loadTasks();
                }),
                const SizedBox(width: 8),
                _buildFilterChip(l10n.all, 'all', _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                  _loadTasks();
                }),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey[400]),
                const SizedBox(width: 16),
                // Priority filter
                _buildPriorityChip('🔴 ${l10n.priorityUrgentEmoji}', 'urgent'),
                const SizedBox(width: 8),
                _buildPriorityChip('🟠 ${l10n.priorityHighEmoji}', 'high'),
                const SizedBox(width: 8),
                _buildPriorityChip('🟡 ${l10n.priorityMediumEmoji}', 'medium'),
                const SizedBox(width: 8),
                _buildPriorityChip('🟢 ${l10n.priorityLowEmoji}', 'low'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelected) {
    final isSelected = current == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildPriorityChip(String label, String value) {
    final isSelected = _priorityFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _priorityFilter = isSelected ? 'all' : value;
        });
        _loadTasks();
      },
      selectedColor: _getPriorityColor(value).withOpacity(0.2),
      showCheckmark: false,
    );
  }

  Widget _buildBody() {
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
            Text(l10n.couldNotLoadTasksError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _statusFilter == 'open'
                  ? l10n.noOpenTasks
                  : l10n.noTasksFound,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tapToAddTask,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final isTablet = Responsive.useWideLayout(context);

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: isTablet
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(_tasks[index]);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(_tasks[index]);
              },
            ),
    );
  }

  Widget _buildTaskCard(MaintenanceTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and accommodation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.accommodationName != null)
                          Text(
                            task.accommodationName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(task),
                ],
              ),
              // Description preview
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
              // Photos preview
              if (task.photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: task.photos.length > 3 ? 3 : task.photos.length,
                    itemBuilder: (context, index) {
                      if (index == 2 && task.photos.length > 3) {
                        return Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '+${task.photos.length - 2}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: task.photos[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                ),
              ],
              // Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  // Priority label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.priorityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(task.priority),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Due date or completed date
                  if (task.status == 'completed' && task.completedAt != null)
                    Text(
                      AppLocalizations.of(context)!.completedOnDate(_formatDate(task.completedAt!)),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  else if (task.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: task.isOverdue ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.isOverdue
                              ? AppLocalizations.of(context)!.overdueDate(_formatDate(task.dueDate!))
                              : AppLocalizations.of(context)!.deadlineDate(_formatDate(task.dueDate!)),
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isOverdue ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MaintenanceTask task) {
    Color bgColor;
    Color textColor;

    switch (task.status) {
      case 'completed':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'in_progress':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'cancelled':
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[600]!;
        break;
      default:
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        task.statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
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
        return Colors.amber[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return l10n.today;
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return l10n.yesterday;
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return l10n.tomorrow;
    }
    return '${date.day}-${date.month}-${date.year}';
  }

  void _showTaskDetail(MaintenanceTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailSheet(
        task: task,
        onEdit: () {
          Navigator.pop(context);
          _navigateToForm(task: task);
        },
        onStatusChange: (status) async {
          Navigator.pop(context);
          await _updateTaskStatus(task, status);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteTask(task);
        },
      ),
    );
  }

  Future<void> _navigateToForm({MaintenanceTask? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceFormScreen(task: task),
      ),
    );

    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _updateTaskStatus(MaintenanceTask task, String status) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.instance.patch(
        '${ApiConfig.maintenance}/${task.id}/status',
        data: {'status': status},
      );
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.statusChangedTo(_getStatusLabel(status)))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotChangeStatus)),
        );
      }
    }
  }

  String _getStatusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'open':
        return l10n.statusOpen;
      case 'in_progress':
        return l10n.statusInProgress;
      case 'waiting':
        return l10n.statusWaiting;
      case 'completed':
        return l10n.statusCompletedValue;
      case 'cancelled':
        return l10n.statusCancelledValue;
      default:
        return status;
    }
  }

  Future<void> _deleteTask(MaintenanceTask task) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTaskTitle),
        content: Text(l10n.confirmDeleteTaskMessage(task.title)),
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

    if (confirm != true) return;

    try {
      await ApiClient.instance.delete('${ApiConfig.maintenance}/${task.id}');
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskDeletedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotDeleteTaskError)),
        );
      }
    }
  }
}

class _TaskDetailSheet extends StatelessWidget {
  final MaintenanceTask task;
  final VoidCallback onEdit;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _TaskDetailSheet({
    required this.task,
    required this.onEdit,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
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
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Title and status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (task.accommodationName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.accommodationName!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: onEdit,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Priority, category and status row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          task.priorityLabel,
                          _getPriorityColor(task.priority),
                        ),
                        _buildInfoChip(
                          task.categoryLabel,
                          AppTheme.primaryColor,
                        ),
                        _buildInfoChip(
                          task.statusLabel,
                          _getStatusColor(task.status),
                        ),
                        if (task.isOverdue)
                          _buildInfoChip(AppLocalizations.of(context)!.overdueLabel, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.descriptionLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Due date
                    if (task.dueDate != null) ...[
                      _buildDetailRow(
                        Icons.schedule,
                        AppLocalizations.of(context)!.deadlineLabel,
                        _formatFullDate(context, task.dueDate!),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Completed info
                    if (task.completedAt != null) ...[
                      _buildDetailRow(
                        Icons.check_circle,
                        AppLocalizations.of(context)!.completedDateLabel,
                        task.completedBy != null
                            ? AppLocalizations.of(context)!.completedByPerson(_formatFullDate(context, task.completedAt!), task.completedBy!)
                            : _formatFullDate(context, task.completedAt!),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Photos
                    if (task.photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.photosLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: task.photos.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showFullImage(context, task.photos[index]),
                              child: Container(
                                width: 120,
                                height: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[200],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: task.photos[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Notes
                    if (task.notes != null && task.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.notesLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(task.notes!),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action buttons
                    if (task.status != 'completed' && task.status != 'cancelled') ...[
                      Row(
                        children: [
                          if (task.status == 'open')
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onStatusChange('in_progress'),
                                icon: const Icon(Icons.play_arrow),
                                label: Text(AppLocalizations.of(context)!.startAction),
                              ),
                            ),
                          if (task.status == 'open') const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onStatusChange('completed'),
                              icon: const Icon(Icons.check),
                              label: Text(AppLocalizations.of(context)!.completeAction),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Delete button
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: Text(
                        AppLocalizations.of(context)!.deleteTaskAction,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatFullDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.january, l10n.february, l10n.march, l10n.april, l10n.may, l10n.june,
      l10n.july, l10n.august, l10n.september, l10n.october, l10n.november, l10n.december
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
