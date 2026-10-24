import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_master/src/providers/auth_provider.dart';
import 'package:task_master/src/theme/app_theme.dart';
import 'package:task_master/src/widgets/task_list_skeleton.dart';

enum TaskScreenMode { all, active }

class TasksListScreen extends StatefulWidget {
  final TaskScreenMode mode;
  const TasksListScreen({super.key, required this.mode});

  @override
  _TasksListScreenState createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  late Future<List<dynamic>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant TasksListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _loadTasks();
    }
  }

  void _loadTasks() {
    final apiService =
        Provider.of<AuthProvider>(context, listen: false).apiService!;
    setState(() {
      _tasksFuture = widget.mode == TaskScreenMode.all
          ? apiService.getAllTasks()
          : apiService.getActiveTasks();
    });
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'selesai') return AppColors.accentGreen;
    if (s == 'in_progress' || s == 'in progress') return AppColors.accentYellow;
    return AppColors.primaryLight;
  }

  DateTime? _parseDueDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'N/A') return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _isOverdue(Map<String, dynamic> task) {
    final status = (task['status'] ?? '').toString().toLowerCase();
    if (status == 'completed' || status == 'selesai') return false;
    final due = _parseDueDate(task['due_date'] as String?);
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  bool _isDueSoon(Map<String, dynamic> task) {
    final status = (task['status'] ?? '').toString().toLowerCase();
    if (status == 'completed' || status == 'selesai') return false;
    final due = _parseDueDate(task['due_date'] as String?);
    if (due == null) return false;
    final diff = due.difference(DateTime.now());
    return diff.inHours >= 0 && diff.inHours <= 24;
  }

  void _showTaskDetailsDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final status = task['status'] ?? '';
        final statusColor = _getStatusColor(status);

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surfaceLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['description'] ?? 'No description',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            '📋 Project', task['project_name'] ?? 'N/A'),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            '📅 Due Date', _formatDueDateFull(task['due_date'] as String?)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Tutup'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.borderColor,
                              foregroundColor: AppColors.textDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TaskListSkeleton();
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: AppColors.accentOrange),
                const SizedBox(height: 16),
                Text(
                  'Oops! Terjadi kesalahan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 80,
                    color: AppColors.primaryLight.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  'Belum ada task',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk refresh\natau buat task baru',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data!;
        return RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surfaceLight,
          onRefresh: () async {
            _loadTasks();
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: widget.mode == TaskScreenMode.all
              ? _buildDashboard(tasks)
              : _buildTaskList(tasks),
        );
      },
    );
  }

  // ─── Dashboard "All" ────────────────────────────────────────────────────────

  Widget _buildDashboard(List<dynamic> tasks) {
    final total = tasks.length;
    final completed = tasks
        .where((t) =>
            (t['status'] ?? '').toString().toLowerCase() == 'completed' ||
            (t['status'] ?? '').toString().toLowerCase() == 'selesai')
        .length;
    final overdue = tasks.where((t) => _isOverdue(t as Map<String, dynamic>)).length;
    final active = total - completed;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      label: 'Total',
                      value: total,
                      icon: Icons.layers_rounded,
                      gradient: AppColors.primaryGradient,
                      index: 0,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Selesai',
                      value: completed,
                      icon: Icons.check_circle_rounded,
                      gradient: AppColors.successGradient,
                      index: 1,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Aktif',
                      value: active,
                      icon: Icons.pending_actions_rounded,
                      gradient: AppColors.warningGradient,
                      index: 2,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Terlambat',
                      value: overdue,
                      icon: Icons.warning_amber_rounded,
                      gradient: AppColors.errorGradient,
                      index: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Semua Task',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = tasks[index] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _buildTaskCard(task, index),
              );
            },
            childCount: tasks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ─── Active list ─────────────────────────────────────────────────────────────

  Widget _buildTaskList(List<dynamic> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index] as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTaskCard(task, index),
        );
      },
    );
  }

  // ─── Task card shared by both modes ──────────────────────────────────────────

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final status = task['status'] ?? '';
    final isCompleted = status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'selesai';
    final statusColor = _getStatusColor(status);
    final overdue = _isOverdue(task);
    final dueSoon = _isDueSoon(task);

    Color accentColor = statusColor;
    if (overdue) accentColor = AppColors.accentOrange;
    if (dueSoon && !overdue) accentColor = AppColors.accentYellow;

    return GestureDetector(
      onTap: () => _showTaskDetailsDialog(task),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? AppColors.borderColor
                : accentColor.withOpacity(0.35),
            width: isCompleted ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 62,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['description'] ?? 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? AppColors.textLight
                                  : AppColors.textDark,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (overdue)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        if (dueSoon && !overdue)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.alarm_on_rounded,
                              size: 16,
                              color: AppColors.accentYellow,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 13, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${task['project_name'] ?? 'N/A'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                        if (task['due_date'] != null &&
                            task['due_date'] != 'N/A') ...[
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_rounded,
                              size: 12,
                              color: overdue
                                  ? AppColors.accentOrange
                                  : AppColors.textLight),
                          const SizedBox(width: 3),
                          Text(
                            _formatDueDate(task['due_date'] as String),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: overdue
                                  ? AppColors.accentOrange
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status.replaceAll('_', ' ').replaceAll('belum selesai', 'pending'),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: min(index * 50, 250)))
          .slideX(begin: -0.1, delay: Duration(milliseconds: min(index * 50, 250))),
    );
  }

  String _formatDueDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatDueDateFull(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'N/A') return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

// ─── Stat Card Widget ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Gradient gradient;
  final int index;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 100 + min(index * 70, 200)))
          .scale(
              begin: const Offset(0.88, 0.88),
              delay: Duration(milliseconds: 100 + min(index * 70, 200)),
              duration: 250.ms),
    );
  }
}
