import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:task_master/src/providers/auth_provider.dart';
import 'package:task_master/src/services/notification_service.dart';
import 'package:task_master/src/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String? _projectName;
  DateTime? _dueDate;
  final _dateController = TextEditingController();
  bool _isLoading = false;

  Future<void> _selectDateTime(BuildContext context) async {
    final themeData = Theme.of(context).copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        surface: AppColors.surfaceLight,
      ),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(data: themeData, child: child!),
    );
    if (pickedDate == null) return;
    if (!context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute)
          : const TimeOfDay(hour: 23, minute: 59),
      builder: (context, child) => Theme(data: themeData, child: child!),
    );

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 23,
      pickedTime?.minute ?? 59,
    );
    setState(() {
      _dueDate = combined;
      _dateController.text =
          DateFormat('d MMM yyyy, HH:mm').format(_dueDate!);
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final apiService = Provider.of<AuthProvider>(context, listen: false).apiService;
    final success = await apiService?.createTask(
      _description,
      dueDate: _dueDate?.toUtc().toIso8601String(), // kirim UTC agar Firestore simpan benar
      projectName: _projectName,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success == true) {
      // Jika deadline sudah lewat, kirim notif pop-up langsung
      if (_dueDate != null && _dueDate!.isBefore(DateTime.now())) {
        await NotificationService().showNow(
          title: '⚠️ Task Sudah Melewati Deadline!',
          body:
              '"$_description" deadline-nya sudah lewat: ${DateFormat('d MMM yyyy, HH:mm').format(_dueDate!)}',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task created successfully! 🎉'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create task'),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Create New Task',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a new task',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Manage your work efficiently',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
                const SizedBox(height: 28),

                // Description field
                Text(
                  'Task Description',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 10),
                TextFormField(
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'What do you need to do?',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.description_outlined),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Description cannot be empty' : null,
                  onSaved: (value) => _description = value!,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                const SizedBox(height: 24),

                // Project field
                Text(
                  'Project Name',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Optional - Link to project',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.workspaces_outlined),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  ),
                  onSaved: (value) => _projectName = value,
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
                const SizedBox(height: 24),

                // Due date & time field
                Text(
                  'Due Date & Time',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    hintText: 'Pilih tanggal & jam deadline',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.event_rounded),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                    suffixIcon: _dueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() {
                              _dueDate = null;
                              _dateController.clear();
                            }),
                          )
                        : null,
                  ),
                  readOnly: true,
                  onTap: () => _selectDateTime(context),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2),
                const SizedBox(height: 32),

                // Submit button
                if (_isLoading)
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitForm,
                      child: Text(
                        'Save Task',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}