import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:tududi_api/tududi_api.dart';

import 'notification_channels.dart';
import 'notification_preferences.dart';

typedef NotificationTapHandler = void Function(String? payload);

/// Schedules and presents local notifications. Safe to use from background
/// isolates after [initialize] has run in that isolate.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const digestNotificationId = 1;
  static const _maxTaskNotifications = 60;

  final FlutterLocalNotificationsPlugin _plugin;
  NotificationPreferences? _preferences;
  bool _initialized = false;
  NotificationTapHandler? onNotificationTap;

  NotificationPreferences get preferences {
    final prefs = _preferences;
    if (prefs == null) {
      throw StateError('NotificationPreferences have not been attached');
    }
    return prefs;
  }

  void attachPreferences(NotificationPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> initialize({NotificationTapHandler? onTap}) async {
    if (_initialized) {
      onNotificationTap = onTap ?? onNotificationTap;
      return;
    }

    onNotificationTap = onTap;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the platform timezone cannot be resolved.
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (response) {
          onNotificationTap?.call(response.payload);
        },
      );
      await _ensureAndroidChannels();
      _initialized = true;
    } catch (_) {
      // Missing plugin bindings in unit/widget tests.
      _initialized = false;
    }
  }

  Future<void> _ensureAndroidChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        DootNotificationChannels.taskDue,
        DootNotificationChannels.taskDueName,
        description: DootNotificationChannels.taskDueDescription,
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        DootNotificationChannels.dailyDigest,
        DootNotificationChannels.dailyDigestName,
        description: DootNotificationChannels.dailyDigestDescription,
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        DootNotificationChannels.habits,
        DootNotificationChannels.habitsName,
        description: DootNotificationChannels.habitsDescription,
        importance: Importance.defaultImportance,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        DootNotificationChannels.goals,
        DootNotificationChannels.goalsName,
        description: DootNotificationChannels.goalsDescription,
        importance: Importance.defaultImportance,
      ),
    );
  }

  Future<bool> areNotificationsAuthorized() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      if (options != null) {
        return options.isEnabled;
      }
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return false;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<void> openSystemNotificationSettings() => openAppSettings();

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> rescheduleFromTasks({
    required List<TududiTask> tasks,
    List<TududiHabit> habits = const [],
    List<TududiGoal> goals = const [],
    bool proUnlocked = false,
  }) async {
    if (!_initialized) return;

    await _plugin.cancelAllPendingNotifications();

    final authorized = await areNotificationsAuthorized();
    if (!authorized) return;

    if (preferences.taskDueEnabled) {
      await _scheduleTaskDue(tasks);
    }
    if (preferences.dailyDigestEnabled) {
      await _scheduleDailyDigest(tasks);
    }
    if (proUnlocked && preferences.habitsEnabled) {
      await _scheduleHabits(habits);
    }
    if (proUnlocked && preferences.goalsEnabled) {
      await _scheduleGoals(goals);
    }
  }

  Future<void> _scheduleTaskDue(List<TududiTask> tasks) async {
    final upcoming = <({TududiTask task, tz.TZDateTime when})>[];
    final now = tz.TZDateTime.now(tz.local);

    for (final task in tasks) {
      if (!task.isOpen) continue;
      final when = _dueDateTime(task);
      if (when == null || !when.isAfter(now)) continue;
      upcoming.add((task: task, when: when));
    }

    upcoming.sort((a, b) => a.when.compareTo(b.when));
    for (final entry in upcoming.take(_maxTaskNotifications)) {
      final uid = entry.task.uid ?? entry.task.id.toString();
      await _plugin.zonedSchedule(
        id: _taskNotificationId(uid),
        scheduledDate: entry.when,
        title: 'Task due',
        body: entry.task.displayName,
        payload: 'task:$uid',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: _details(
          channelId: DootNotificationChannels.taskDue,
          channelName: DootNotificationChannels.taskDueName,
          channelDescription: DootNotificationChannels.taskDueDescription,
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _scheduleDailyDigest(List<TududiTask> tasks) async {
    final hour = preferences.digestHour;
    var next = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      hour,
    );
    if (!next.isAfter(tz.TZDateTime.now(tz.local))) {
      next = next.add(const Duration(days: 1));
    }

    final todayCount = tasks.where((t) {
      if (!t.isOpen || t.dueDate == null) return false;
      final due = DateTime.tryParse(t.dueDate!);
      if (due == null) return false;
      final now = DateTime.now();
      return due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    }).length;

    final body = todayCount == 0
        ? 'No tasks for today'
        : todayCount == 1
        ? '1 task for today'
        : '$todayCount tasks for today';

    await _plugin.zonedSchedule(
      id: digestNotificationId,
      scheduledDate: next,
      title: 'Today in DootDoot',
      body: body,
      payload: 'digest',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      notificationDetails: _details(
        channelId: DootNotificationChannels.dailyDigest,
        channelName: DootNotificationChannels.dailyDigestName,
        channelDescription: DootNotificationChannels.dailyDigestDescription,
      ),
    );
  }

  Future<void> _scheduleHabits(List<TududiHabit> habits) async {
    final incomplete = habits.where((h) => !h.completedToday).toList();
    if (incomplete.isEmpty) return;

    var when = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      18,
    );
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }

    final names = incomplete.take(3).map((h) => h.name).join(', ');
    final more = incomplete.length > 3 ? ' +${incomplete.length - 3} more' : '';

    await _plugin.zonedSchedule(
      id: 200001,
      scheduledDate: when,
      title: 'Habits waiting',
      body: '$names$more',
      payload: 'habits',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      notificationDetails: _details(
        channelId: DootNotificationChannels.habits,
        channelName: DootNotificationChannels.habitsName,
        channelDescription: DootNotificationChannels.habitsDescription,
      ),
    );
  }

  Future<void> _scheduleGoals(List<TududiGoal> goals) async {
    final now = tz.TZDateTime.now(tz.local);
    final upcoming = <({TududiGoal goal, tz.TZDateTime when})>[];

    for (final goal in goals) {
      if (goal.status != 'active') continue;
      final date = goal.targetDate;
      if (date == null || date.isEmpty) continue;
      final parsed = DateTime.tryParse(date);
      if (parsed == null) continue;
      final when = tz.TZDateTime(
        tz.local,
        parsed.year,
        parsed.month,
        parsed.day,
        9,
      );
      if (!when.isAfter(now)) continue;
      upcoming.add((goal: goal, when: when));
    }

    upcoming.sort((a, b) => a.when.compareTo(b.when));
    for (final entry in upcoming.take(20)) {
      final uid = entry.goal.uid ?? entry.goal.id.toString();
      await _plugin.zonedSchedule(
        id: _goalNotificationId(uid),
        scheduledDate: entry.when,
        title: 'Goal deadline',
        body: entry.goal.title,
        payload: 'goal:$uid',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: _details(
          channelId: DootNotificationChannels.goals,
          channelName: DootNotificationChannels.goalsName,
          channelDescription: DootNotificationChannels.goalsDescription,
        ),
      );
    }
  }

  tz.TZDateTime? _dueDateTime(TududiTask task) {
    final dateRaw = task.dueDate;
    if (dateRaw == null || dateRaw.isEmpty) return null;
    final date = DateTime.tryParse(dateRaw);
    if (date == null) return null;

    var hour = 9;
    var minute = 0;
    final timeRaw = task.dueTime;
    if (timeRaw != null && timeRaw.isNotEmpty) {
      final parts = timeRaw.split(':');
      if (parts.isNotEmpty) {
        hour = int.tryParse(parts[0]) ?? 9;
      }
      if (parts.length > 1) {
        minute = int.tryParse(parts[1]) ?? 0;
      }
    }

    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDescription,
    Importance importance = Importance.defaultImportance,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  int _taskNotificationId(String uid) => 1000 + (uid.hashCode.abs() % 90000);

  int _goalNotificationId(String uid) => 300000 + (uid.hashCode.abs() % 90000);
}
