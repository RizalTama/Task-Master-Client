import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_master/src/providers/auth_provider.dart';
import 'package:task_master/src/screens/tasks_list_screen.dart';
import 'package:task_master/src/screens/chat_screen.dart';
import 'package:task_master/src/screens/projects_screen.dart';
import 'package:task_master/src/screens/add_task_screen.dart';
import 'package:task_master/src/screens/notifications_screen.dart';
import 'package:task_master/src/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late DateTime _currentTime;
  late Timer _clockTimer;

  static const List<Widget> _widgetOptions = <Widget>[
    TasksListScreen(mode: TaskScreenMode.all),
    TasksListScreen(mode: TaskScreenMode.active),
    ProjectsScreen(),
    ChatScreen(),
    NotificationsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Update clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
    _scheduleNotifications();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _scheduleNotifications() async {
    try {
      final apiService =
          Provider.of<AuthProvider>(context, listen: false).apiService;
      final tasks = await apiService!.getAllTasks();
      await NotificationService().scheduleTaskReminders(tasks);
    } catch (e) {
      // Simpan error agar terlihat di debug panel notifikasi
      NotificationService().lastScheduleError = 'Gagal ambil tasks: $e';
    }
  }

  void _onItemTapped(int index) {
    // Kalau user keluar dari tab Chat AI → re-schedule notifikasi
    // karena AI mungkin sudah buat/edit task dengan due_date baru
    if (_selectedIndex == 3 && index != 3) {
      _scheduleNotifications();
    }
    setState(() => _selectedIndex = index);
  }

  void _onNotificationTabSelected() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: _buildClock(),
        title: Text(
          'Task Master',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Provider.of<AuthProvider>(context, listen: false).signOut();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: (_selectedIndex != 3 && _selectedIndex != 4)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                          builder: (context) => const AddTaskScreen()),
                    )
                    .then((_) => _scheduleNotifications());
              },
              tooltip: 'Add Task',
              child: const Icon(Icons.add, size: 28),
            ).animate().scale(duration: 300.ms)
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'All',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_rounded),
              label: 'Active',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspaces_rounded),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              label: 'Chat AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded),
              label: 'Reminder',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            _onItemTapped(index);
            if (index == 4) _onNotificationTabSelected();
          },
        ),
      ),
    );
  }

  Widget _buildClock() {
    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final secStr  = DateFormat('ss').format(_currentTime);
    final dateStr = DateFormat('EEE, d MMM', 'id').format(_currentTime);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    ':$secStr',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
