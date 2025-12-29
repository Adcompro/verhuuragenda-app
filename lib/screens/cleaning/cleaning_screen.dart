import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../utils/responsive.dart';

class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CleaningTask> _tasks = [];
  CleaningStats? _stats;
  bool _isLoading = true;
  String? _error;
  String _currentPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            _loadTasks('today');
            break;
          case 1:
            _loadTasks('week');
            break;
          case 2:
            _loadTasks('all');
            break;
        }
      }
    });
    _loadTasks('week');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks(String period) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPeriod = period;
    });

    try {
      final response = await ApiClient.instance.get(
        ApiConfig.cleaning,
        queryParameters: {'period': period},
      );

      final data = response.data;
      final tasksData = data['data'] as List? ?? [];
      final statsData = data['stats'] as Map<String, dynamic>?;

      setState(() {
        _tasks = tasksData.map((json) => CleaningTask.fromJson(json)).toList();
        _stats = statsData != null ? CleaningStats.fromJson(statsData) : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Error message will be shown in UI which uses l10n
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(l10n.cleaning),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.todayTab),
            Tab(text: l10n.thisWeekTab),
            Tab(text: l10n.allTab),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats header
            if (_stats != null) _buildStatsHeader(),
            // Tasks list
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatCard(
            l10n.total,
            _stats!.total.toString(),
            Icons.cleaning_services,
            Colors.blue,
          ),
          _buildStatCard(
            l10n.today,
            _stats!.today.toString(),
            Icons.today,
            Colors.orange,
          ),
          _buildStatCard(
            l10n.urgent,
            _stats!.urgent.toString(),
            Icons.priority_high,
            Colors.red,
          ),
          _buildStatCard(
            l10n.ready,
            _stats!.completed.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadTasks(_currentPeriod),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cleaning_services_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              l10n.noCleaningTasks,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _getPeriodDescription(l10n),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group tasks by status
    final pendingTasks = _tasks.where((t) => !t.cleaningCompleted).toList();
    final completedTasks = _tasks.where((t) => t.cleaningCompleted).toList();
    final isTablet = Responsive.useWideLayout(context);

    return RefreshIndicator(
      onRefresh: () => _loadTasks(_currentPeriod),
      child: ListView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        children: [
          // Pending tasks
          if (pendingTasks.isNotEmpty) ...[
            _buildSectionHeader(l10n.toDo, pendingTasks.length, Colors.orange),
            if (isTablet)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: pendingTasks.length,
                itemBuilder: (context, index) => _CleaningTaskCard(
                  task: pendingTasks[index],
                  onComplete: () => _showCompleteDialog(pendingTasks[index]),
                ),
              )
            else
              ...pendingTasks.map((task) => _CleaningTaskCard(
                task: task,
                onComplete: () => _showCompleteDialog(task),
              )),
          ],
          // Completed tasks
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.finishedSection, completedTasks.length, Colors.green),
            if (isTablet)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: completedTasks.length,
                itemBuilder: (context, index) => _CleaningTaskCard(
                  task: completedTasks[index],
                  onUndo: () => _undoComplete(completedTasks[index]),
                  onViewDetails: () => _showCompletedDetails(completedTasks[index]),
                ),
              )
            else
              ...completedTasks.map((task) => _CleaningTaskCard(
                task: task,
                onUndo: () => _undoComplete(task),
                onViewDetails: () => _showCompletedDetails(task),
              )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, {bool isCompleted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  color == Colors.green ? Icons.check_circle : Icons.schedule,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  '$title ($count)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodDescription(AppLocalizations l10n) {
    switch (_currentPeriod) {
      case 'today':
        return l10n.forToday;
      case 'week':
        return l10n.thisWeek;
      default:
        return '';
    }
  }

  void _showCompleteDialog(CleaningTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CleaningCompleteSheet(
        task: task,
        onComplete: (notes, issues) async {
          await _completeCleaning(task, notes, issues);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _completeCleaning(CleaningTask task, String? notes, List<CleaningIssue> issues) async {
    try {
      // Build notes with issues
      final allNotes = StringBuffer();
      if (issues.isNotEmpty) {
        for (final issue in issues) {
          allNotes.writeln('[${issue.type}] ${issue.description}');
        }
      }
      if (notes != null && notes.isNotEmpty) {
        if (allNotes.isNotEmpty) allNotes.writeln();
        allNotes.write(notes);
      }

      await ApiClient.instance.post(
        '${ApiConfig.cleaning}/${task.id}/complete',
        data: {
          'notes': allNotes.toString().isEmpty ? null : allNotes.toString(),
        },
      );

      _loadTasks(_currentPeriod);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.cleanedSuccess(task.accommodationName)),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCompletedDetails(CleaningTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CleaningDetailsSheet(
        task: task,
        onUndo: () {
          Navigator.pop(context);
          _undoComplete(task);
        },
      ),
    );
  }

  Future<void> _undoComplete(CleaningTask task) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(dialogL10n.undoCleaningTitle),
          content: Text(dialogL10n.undoCleaningMessage(task.accommodationName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dialogL10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dialogL10n.yesReset),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiClient.instance.post('${ApiConfig.cleaning}/${task.id}/uncomplete');
      _loadTasks(_currentPeriod);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cleaningStatusReset)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _CleaningTaskCard extends StatelessWidget {
  final CleaningTask task;
  final VoidCallback? onComplete;
  final VoidCallback? onUndo;
  final VoidCallback? onViewDetails;

  const _CleaningTaskCard({
    required this.task,
    this.onComplete,
    this.onUndo,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = task.cleaningCompleted;
    final isUrgent = task.hasSameDayCheckin;
    final isToday = task.isToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUrgent && !isCompleted
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Header with accommodation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: task.accommodationColor?.withOpacity(0.1) ?? Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: task.accommodationColor ?? AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Accommodation name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.accommodationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.guestLabel(task.guestName),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Status badges
                if (isUrgent && !isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          l10n.urgent.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isToday && !isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.today.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          l10n.ready.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Time window visualization
                _buildTimeWindow(),
                const SizedBox(height: 16),
                // Completed summary for completed tasks
                if (isCompleted) ...[
                  // Show quick preview of issues if any
                  if (task.cleaningNotes != null && task.cleaningNotes!.isNotEmpty)
                    GestureDetector(
                      onTap: onViewDetails,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _hasIssues(task.cleaningNotes!)
                              ? Colors.red.withOpacity(0.05)
                              : Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _hasIssues(task.cleaningNotes!)
                                ? Colors.red.withOpacity(0.3)
                                : Colors.amber.withOpacity(0.3)
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _hasIssues(task.cleaningNotes!)
                                      ? Icons.warning_amber
                                      : Icons.note,
                                  size: 16,
                                  color: _hasIssues(task.cleaningNotes!)
                                      ? Colors.red[700]
                                      : Colors.amber[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _hasIssues(task.cleaningNotes!)
                                      ? l10n.reports
                                      : l10n.notes,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _hasIssues(task.cleaningNotes!)
                                        ? Colors.red[700]
                                        : Colors.amber[700],
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getNotesPreview(task.cleaningNotes!),
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Completed time with tap hint
                  InkWell(
                    onTap: onViewDetails,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text(
                            l10n.completedAt(task.cleaningCompletedAt ?? ''),
                            style: TextStyle(color: Colors.green[600], fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            l10n.viewDetails,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: 16),
                        ],
                      ),
                    ),
                  ),
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: Text(l10n.details),
                      ),
                      TextButton.icon(
                        onPressed: onUndo,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(l10n.undo),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                // Action button for incomplete tasks
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.cleaning_services),
                      label: Text(l10n.finishCleaning),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasIssues(String notes) {
    return notes.contains('[Extra vies]') ||
           notes.contains('[Schade]') ||
           notes.contains('[Ontbrekend]') ||
           notes.contains('[Reparatie nodig]') ||
           notes.contains('[Anders]');
  }

  String _getNotesPreview(String notes) {
    // Parse out issue types and show them
    final issues = <String>[];
    if (notes.contains('[Extra vies]')) issues.add('Extra vies');
    if (notes.contains('[Schade]')) issues.add('Schade');
    if (notes.contains('[Ontbrekend]')) issues.add('Ontbrekend');
    if (notes.contains('[Reparatie nodig]')) issues.add('Reparatie nodig');

    if (issues.isNotEmpty) {
      return issues.join(' • ');
    }

    // Otherwise show the first line of notes
    return notes.split('\n').first;
  }

  Widget _buildTimeWindow() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Check-out
          Expanded(
            child: Column(
              children: [
                Icon(Icons.logout, color: Colors.red[400], size: 24),
                const SizedBox(height: 4),
                Text(
                  l10n.checkOut,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  task.checkOut,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  task.checkOutTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Arrow with duration
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: task.hasSameDayCheckin ? Colors.red : AppTheme.primaryColor,
                    ),
                    Icon(
                      Icons.cleaning_services,
                      color: task.hasSameDayCheckin ? Colors.red : AppTheme.primaryColor,
                    ),
                    Container(
                      width: 40,
                      height: 2,
                      color: task.hasSameDayCheckin ? Colors.red : AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.hasSameDayCheckin ? l10n.sameDay : l10n.cleaningWindow,
                  style: TextStyle(
                    fontSize: 11,
                    color: task.hasSameDayCheckin ? Colors.red : Colors.grey[600],
                    fontWeight: task.hasSameDayCheckin ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Next check-in
          Expanded(
            child: Column(
              children: [
                Icon(Icons.login, color: Colors.green[400], size: 24),
                const SizedBox(height: 4),
                Text(
                  l10n.checkIn,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  task.hasSameDayCheckin ? task.checkOut : l10n.flexible,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: task.hasSameDayCheckin ? Colors.red : Colors.grey[600],
                  ),
                ),
                if (task.hasSameDayCheckin)
                  Text(
                    '15:00', // Default check-in time
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleaningCompleteSheet extends StatefulWidget {
  final CleaningTask task;
  final Function(String?, List<CleaningIssue>) onComplete;

  const _CleaningCompleteSheet({
    required this.task,
    required this.onComplete,
  });

  @override
  State<_CleaningCompleteSheet> createState() => _CleaningCompleteSheetState();
}

class _CleaningCompleteSheetState extends State<_CleaningCompleteSheet> {
  final _notesController = TextEditingController();
  final List<CleaningIssue> _issues = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> _getIssueTypes(AppLocalizations l10n) => [
    {'type': l10n.extraDirty, 'icon': Icons.dirty_lens, 'color': Colors.brown},
    {'type': l10n.damage, 'icon': Icons.broken_image, 'color': Colors.red},
    {'type': l10n.missingItem, 'icon': Icons.search_off, 'color': Colors.orange},
    {'type': l10n.repairNeeded, 'icon': Icons.build, 'color': Colors.blue},
    {'type': l10n.other, 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final issueTypes = _getIssueTypes(l10n);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cleaning_services, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.finishCleaning,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.task.accommodationName,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick issue buttons
              Text(
                l10n.anythingToReport,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: issueTypes.map((type) {
                  final hasIssue = _issues.any((i) => i.type == type['type']);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type['icon'] as IconData, size: 16, color: type['color'] as Color),
                        const SizedBox(width: 6),
                        Text(type['type'] as String),
                      ],
                    ),
                    selected: hasIssue,
                    onSelected: (selected) {
                      if (selected) {
                        _showAddIssueDialog(type['type'] as String);
                      } else {
                        setState(() {
                          _issues.removeWhere((i) => i.type == type['type']);
                        });
                      }
                    },
                    selectedColor: (type['color'] as Color).withOpacity(0.2),
                  );
                }).toList(),
              ),

              // Issues list
              if (_issues.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: _issues.asMap().entries.map((entry) {
                      final issue = entry.value;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getIssueIcon(issue.type, l10n),
                          color: _getIssueColor(issue.type, l10n),
                          size: 20,
                        ),
                        title: Text(issue.type, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(issue.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _issues.removeAt(entry.key));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Notes
              Text(
                l10n.notesOptional,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.extraCommentsPlaceholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _isLoading = true);
                          widget.onComplete(
                            _notesController.text.isEmpty ? null : _notesController.text,
                            _issues,
                          );
                        },
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle, size: 24),
                  label: Text(
                    _isLoading ? l10n.processing : l10n.finishCleaning,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddIssueDialog(String type) {
    final descController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getIssueIcon(type, dialogL10n), color: _getIssueColor(type, dialogL10n)),
              const SizedBox(width: 8),
              Text(type),
            ],
          ),
          content: TextField(
            controller: descController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: _getIssueHint(type, dialogL10n),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(dialogL10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (descController.text.isNotEmpty) {
                setState(() {
                  _issues.add(CleaningIssue(type: type, description: descController.text));
                });
              }
              Navigator.pop(context);
            },
            child: Text(dialogL10n.add),
          ),
        ],
      );
      },
    );
  }

  IconData _getIssueIcon(String type, AppLocalizations l10n) {
    if (type == l10n.extraDirty) return Icons.dirty_lens;
    if (type == l10n.damage) return Icons.broken_image;
    if (type == l10n.missingItem) return Icons.search_off;
    if (type == l10n.repairNeeded) return Icons.build;
    return Icons.more_horiz;
  }

  Color _getIssueColor(String type, AppLocalizations l10n) {
    if (type == l10n.extraDirty) return Colors.brown;
    if (type == l10n.damage) return Colors.red;
    if (type == l10n.missingItem) return Colors.orange;
    if (type == l10n.repairNeeded) return Colors.blue;
    return Colors.grey;
  }

  String _getIssueHint(String type, AppLocalizations l10n) {
    // These hints are not in l10n yet - they are internal hints for the dialog
    // Keeping simple for now, can be localized later if needed
    if (type == l10n.extraDirty) return 'What was extra dirty?';
    if (type == l10n.damage) return 'What is damaged?';
    if (type == l10n.missingItem) return 'What is missing?';
    if (type == l10n.repairNeeded) return 'What needs repair?';
    return 'Describe the issue...';
  }
}

// Data models

class CleaningTask {
  final int id;
  final String? bookingNumber;
  final String checkOut;
  final String checkOutTime;
  final bool isToday;
  final bool cleaningCompleted;
  final String? cleaningCompletedAt;
  final String? cleaningNotes;
  final String guestName;
  final String accommodationName;
  final Color? accommodationColor;
  final bool hasSameDayCheckin;

  CleaningTask({
    required this.id,
    this.bookingNumber,
    required this.checkOut,
    required this.checkOutTime,
    required this.isToday,
    required this.cleaningCompleted,
    this.cleaningCompletedAt,
    this.cleaningNotes,
    required this.guestName,
    required this.accommodationName,
    this.accommodationColor,
    required this.hasSameDayCheckin,
  });

  factory CleaningTask.fromJson(Map<String, dynamic> json) {
    Color? color;
    final colorStr = json['accommodation']?['color'];
    if (colorStr != null && colorStr is String && colorStr.startsWith('#')) {
      try {
        color = Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
    }

    return CleaningTask(
      id: json['id'] ?? 0,
      bookingNumber: json['booking_number'],
      checkOut: json['check_out'] ?? '',
      checkOutTime: json['check_out_time'] ?? '10:00',
      isToday: json['is_today'] ?? false,
      cleaningCompleted: json['cleaning_completed'] ?? false,
      cleaningCompletedAt: json['cleaning_completed_at'],
      cleaningNotes: json['cleaning_notes'],
      guestName: json['guest']?['name'] ?? 'Onbekend',
      accommodationName: json['accommodation']?['name'] ?? 'Onbekend',
      accommodationColor: color,
      hasSameDayCheckin: json['has_same_day_checkin'] ?? false,
    );
  }
}

class CleaningStats {
  final int total;
  final int today;
  final int urgent;
  final int completed;

  CleaningStats({
    required this.total,
    required this.today,
    required this.urgent,
    required this.completed,
  });

  factory CleaningStats.fromJson(Map<String, dynamic> json) {
    return CleaningStats(
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      urgent: json['urgent'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class CleaningIssue {
  final String type;
  final String description;

  CleaningIssue({required this.type, required this.description});
}

class _CleaningDetailsSheet extends StatelessWidget {
  final CleaningTask task;
  final VoidCallback onUndo;

  const _CleaningDetailsSheet({
    required this.task,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final parsedIssues = _parseIssues(task.cleaningNotes);
    final otherNotes = _extractOtherNotes(task.cleaningNotes);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: task.accommodationColor ?? AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.accommodationName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gast: ${task.guestName}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Klaar',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Completed info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schoonmaak afgerond',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.cleaningCompletedAt ?? 'Onbekend',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Issues section
              if (parsedIssues.isNotEmpty) ...[
                const Text(
                  'Gemelde problemen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...parsedIssues.map((issue) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _getIssueColor(issue['type']!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getIssueColor(issue['type']!).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getIssueIcon(issue['type']!),
                        color: _getIssueColor(issue['type']!),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue['type']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getIssueColor(issue['type']!),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              issue['description']!,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],

              // Other notes section
              if (otherNotes.isNotEmpty) ...[
                const Text(
                  'Notities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    otherNotes,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // No notes message
              if (task.cleaningNotes == null || task.cleaningNotes!.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Schoonmaak zonder bijzonderheden afgerond',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Sluiten'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo),
                      label: const Text('Ongedaan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _parseIssues(String? notes) {
    if (notes == null) return [];

    final issues = <Map<String, String>>[];
    final lines = notes.split('\n');

    for (final line in lines) {
      if (line.startsWith('[')) {
        final endBracket = line.indexOf(']');
        if (endBracket > 1) {
          final type = line.substring(1, endBracket);
          final description = line.substring(endBracket + 1).trim();
          issues.add({'type': type, 'description': description});
        }
      }
    }

    return issues;
  }

  String _extractOtherNotes(String? notes) {
    if (notes == null) return '';

    final lines = notes.split('\n');
    final otherLines = lines.where((line) => !line.startsWith('['));
    return otherLines.join('\n').trim();
  }

  IconData _getIssueIcon(String type) {
    switch (type) {
      case 'Extra vies':
        return Icons.dirty_lens;
      case 'Schade':
        return Icons.broken_image;
      case 'Ontbrekend':
        return Icons.search_off;
      case 'Reparatie nodig':
        return Icons.build;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getIssueColor(String type) {
    switch (type) {
      case 'Extra vies':
        return Colors.brown;
      case 'Schade':
        return Colors.red;
      case 'Ontbrekend':
        return Colors.orange;
      case 'Reparatie nodig':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
