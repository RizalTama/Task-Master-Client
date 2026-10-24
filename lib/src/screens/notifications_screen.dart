import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_master/src/services/notification_service.dart';
import 'package:task_master/src/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> get _notifications =>
      NotificationService().scheduledNotifications;
  bool? _hasExactPerm;

  @override
  void initState() {
    super.initState();
    _checkPerm();
  }

  Future<void> _checkPerm() async {
    final ok = await NotificationService().hasExactAlarmPermission();
    if (mounted) setState(() => _hasExactPerm = ok);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _notifications.isEmpty
          ? Column(
              children: [
                _buildDebugPanel(context),
                _buildTestButton(context),
                Expanded(child: _buildEmpty()),
              ],
            )
          : Column(
              children: [
                _buildDebugPanel(context),
                _buildTestButton(context),
                _buildSummaryBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final scheduledAt =
                          notif['scheduledAt'] as DateTime;
                      final isPassed = scheduledAt.isBefore(now);
                      final type = notif['type'] as String;

                      return _NotificationCard(
                        notif: notif,
                        scheduledAt: scheduledAt,
                        isPassed: isPassed,
                        type: type,
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Debug panel ─────────────────────────────────────────────────────────────

  Widget _buildDebugPanel(BuildContext context) {
    final permOk = _hasExactPerm;
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm:ss, dd MMM yyyy').format(now);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: permOk == false
              ? AppColors.accentOrange.withOpacity(0.6)
              : AppColors.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bug_report_rounded,
                size: 15, color: AppColors.primaryLight),
            const SizedBox(width: 6),
            Text('Status Sistem',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ]),
          const SizedBox(height: 8),
          _debugRow('Waktu HP sekarang', timeStr),
          _debugRow(
            'Exact Alarm Permission',
            permOk == null
                ? 'Mengecek...'
                : permOk
                    ? '✅ Granted'
                    : '❌ BELUM DIIZINKAN — tap untuk buka Settings',
            color: permOk == false ? AppColors.accentOrange : null,
            onTap: permOk == false
                ? () async {
                    final android = await NotificationService()
                        .hasExactAlarmPermission();
                    if (!android) {
                      await NotificationService().init();
                      _checkPerm();
                    }
                  }
                : null,
          ),
          _debugRow('Notif terjadwal', '${_notifications.length} pengingat'),
          if (NotificationService().lastScheduleError != null)
            _debugRow(
              'Error terakhir',
              NotificationService().lastScheduleError!,
              color: AppColors.accentOrange,
            ),
        ],
      ),
    );
  }

  Widget _debugRow(String label, String value,
      {Color? color, VoidCallback? onTap}) {
    final widget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: color ?? AppColors.textDark,
                    fontWeight: color != null
                        ? FontWeight.w700
                        : FontWeight.w400)),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }

  // ─── Test buttons ─────────────────────────────────────────────────────────────

  Widget _buildTestButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Tombol 1: instant
          _actionBtn(
            label: 'Test Notif Sekarang (Instant)',
            icon: Icons.notifications_active_rounded,
            gradient: AppColors.successGradient,
            shadowColor: AppColors.accentGreen,
            onTap: () async {
              await NotificationService().showNow();
              if (!context.mounted) return;
              _snack(context,
                  '✅ Notif instant dikirim! Cek bilah notifikasi.', AppColors.accentGreen);
            },
          ),
          const SizedBox(height: 8),
          // Tombol 2: terjadwal 1 menit — sama persis mekanisme zonedSchedule deadline
          _actionBtn(
            label: 'Test Terjadwal (muncul 1 menit lagi)',
            icon: Icons.alarm_rounded,
            gradient: AppColors.warningGradient,
            shadowColor: AppColors.accentYellow,
            onTap: () async {
              await NotificationService().scheduleIn1Min();
              if (!context.mounted) return;
              _snack(context,
                  '⏱ Dijadwalkan! Tunggu 1 menit. Jika muncul → notif deadline juga bekerja.',
                  AppColors.accentYellow);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2);
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: shadowColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 12)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  Widget _buildSummaryBanner() {
    final now = DateTime.now();
    final upcoming = _notifications
        .where((n) => !(n['scheduledAt'] as DateTime).isBefore(now))
        .length;
    final passed = _notifications.length - upcoming;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengingat Terjadwal',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$upcoming akan datang  •  $passed sudah lewat',
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
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: AppColors.primaryLight.withOpacity(0.35),
            ),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 28),
          Text(
            'Belum Ada Pengingat',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tambahkan task dengan deadline untuk\nmendapatkan notifikasi pengingat otomatis',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.6,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'Notif muncul 24 jam & 5 jam sebelum deadline',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final DateTime scheduledAt;
  final bool isPassed;
  final String type; // '24h' | '5h' | 'h0'
  final int index;

  const _NotificationCard({
    required this.notif,
    required this.scheduledAt,
    required this.isPassed,
    required this.type,
    required this.index,
  });

  Color get _accentColor {
    if (type == '24h') return AppColors.accentYellow;
    if (type == 'h0') return const Color(0xFFE53935); // merah deadline
    return AppColors.accentOrange;
  }

  Gradient get _iconGradient {
    if (type == '24h') return AppColors.warningGradient;
    return AppColors.errorGradient;
  }

  IconData get _icon {
    if (type == '24h') return Icons.alarm_rounded;
    if (type == 'h0') return Icons.warning_amber_rounded;
    return Icons.notifications_active_rounded;
  }

  String get _badge {
    if (type == '24h') return '-24 jam';
    if (type == 'h0') return 'H-0';
    return '-5 jam';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isPassed ? AppColors.backgroundLight : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPassed
              ? AppColors.borderColor
              : _accentColor.withOpacity(0.5),
          width: isPassed ? 1 : 1.5,
        ),
        boxShadow: isPassed
            ? []
            : [
                BoxShadow(
                  color: _accentColor.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isPassed ? null : _iconGradient,
                color: isPassed ? AppColors.borderColor : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: isPassed ? AppColors.textLight : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isPassed ? AppColors.textLight : AppColors.textDark,
                      decoration:
                          isPassed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif['body'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: isPassed
                            ? AppColors.textLight
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(scheduledAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isPassed
                              ? AppColors.textLight
                              : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppColors.borderColor
                              : _accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPassed ? 'Sudah lewat' : _badge,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isPassed
                                ? AppColors.textLight
                                : _accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: min(index * 60, 240)))
        .slideY(begin: 0.1, delay: Duration(milliseconds: min(index * 60, 240)));
  }
}
