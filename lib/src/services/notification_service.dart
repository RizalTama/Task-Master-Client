import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final List<Map<String, dynamic>> scheduledNotifications = [];

  Future<void> init() async {
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Minta izin POST_NOTIFICATIONS (Android 13+)
    await android?.requestNotificationsPermission();

    // Minta izin SCHEDULE_EXACT_ALARM (Android 12+ — wajib untuk notif tepat waktu)
    // Ini membuka halaman Settings agar user bisa allow "Alarms & Reminders"
    final canExact = await android?.canScheduleExactNotifications();
    if (canExact == false) {
      await android?.requestExactAlarmsPermission();
    }
  }

  // Pesan error terakhir dari scheduling (untuk debug panel)
  String? lastScheduleError;
  int lastScheduledCount = 0;

  /// Jadwalkan notif -24 jam, -5 jam, dan H-0 untuk setiap task yang belum selesai.
  Future<void> scheduleTaskReminders(List<dynamic> tasks) async {
    lastScheduleError = null;
    await _plugin.cancelAll();
    scheduledNotifications.clear();

    // Tentukan mode scheduling berdasarkan permission
    final canExact = await hasExactAlarmPermission();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.alarmClock;

    final now = DateTime.now();
    int notifId = 0;

    for (final rawTask in tasks) {
      final task = rawTask as Map<String, dynamic>;
      final status = (task['status'] ?? '').toString().toLowerCase();
      if (status == 'completed' || status == 'selesai') continue;

      // due_date bisa berupa String ISO atau null
      final raw = task['due_date'];
      final dueDate = _parseDueDate(raw is String ? raw : raw?.toString());
      if (dueDate == null) continue;

      final description = (task['description'] ?? 'Task').toString();

      // Helper: schedule + record, catch per-notif agar tidak batalkan loop
      Future<void> trySchedule({
        required String title,
        required String body,
        required DateTime at,
        required String type,
      }) async {
        try {
          await _scheduleOne(
              id: notifId++,
              title: title,
              body: body,
              scheduledDate: at,
              mode: scheduleMode);
          scheduledNotifications.add({
            'title': title,
            'body': body,
            'scheduledAt': at,
            'type': type,
          });
        } catch (e) {
          lastScheduleError = e.toString();
        }
      }

      // ── -24 jam ──────────────────────────────────────────────────────
      final remind24h = dueDate.subtract(const Duration(hours: 24));
      if (remind24h.isAfter(now)) {
        await trySchedule(
          title: '⏰ Deadline Besok!',
          body: '"$description" jatuh tempo besok pukul ${_fmt(dueDate)}.',
          at: remind24h,
          type: '24h',
        );
      }

      // ── -5 jam ───────────────────────────────────────────────────────
      final remind5h = dueDate.subtract(const Duration(hours: 5));
      if (remind5h.isAfter(now)) {
        await trySchedule(
          title: '🔔 Deadline 5 Jam Lagi!',
          body: '"$description" jatuh tempo pukul ${_fmt(dueDate)}.',
          at: remind5h,
          type: '5h',
        );
      }

      // ── H-0 (tepat deadline) ─────────────────────────────────────────
      if (dueDate.isAfter(now)) {
        await trySchedule(
          title: '🚨 Deadline Sekarang!',
          body: '"$description" sudah jatuh tempo pukul ${_fmt(dueDate)}!',
          at: dueDate,
          type: 'h0',
        );
      }
    }

    lastScheduledCount = scheduledNotifications.length;
    scheduledNotifications.sort((a, b) =>
        (a['scheduledAt'] as DateTime)
            .compareTo(b['scheduledAt'] as DateTime));
  }

  /// Jadwalkan notif 1 menit dari sekarang — tampilannya sama persis dengan notif -24 jam asli.
  Future<void> scheduleIn1Min() async {
    final canExact = await hasExactAlarmPermission();
    final mode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.alarmClock;
    final target = DateTime.now().add(const Duration(minutes: 1));
    // Simulasi: notif ini adalah pengingat -24jam, jadi "deadline" = target + 24 jam
    final fakeDeadline = target.add(const Duration(hours: 24));
    await _scheduleOne(
      id: 9998,
      title: '⏰ Deadline Besok!',
      body: '"Contoh Task Test" jatuh tempo besok pukul ${_fmt(fakeDeadline)}.',
      scheduledDate: target,
      mode: mode,
    );
  }

  /// Cek apakah permission exact alarm sudah diberikan.
  Future<bool> hasExactAlarmPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  /// Tampilkan notifikasi SEKARANG — untuk test/demo.
  Future<void> showNow({
    String title = '🔔 Test Notifikasi',
    String body = 'Task Master berhasil kirim notif ke HP kamu!',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Pengingat deadline task',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(9999, title, body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Parse due_date string.
  /// FIX BUG 1: Jika hanya tanggal (tanpa jam), set jam ke 23:59
  /// agar -24h = kemarin 23:59 (bukan tengah malam yang sudah lewat).
  DateTime? _parseDueDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'N/A') return null;
    try {
      final dt = DateTime.parse(raw);
      // Jika UTC midnight → kemungkinan date-only (dari AI chat / backend lama)
      // → gunakan akhir hari di local timezone
      if (dt.isUtc && dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
        final local = dt.toLocal();
        return DateTime(local.year, local.month, local.day, 23, 59, 0);
      }
      // Selalu konversi ke local agar jadwal notif pakai waktu lokal
      return dt.isUtc ? dt.toLocal() : dt;
    } catch (_) {
      return null;
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    AndroidScheduleMode mode = AndroidScheduleMode.alarmClock,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Pengingat deadline task',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
