import 'package:shared_preferences/shared_preferences.dart';

/// On-device notification toggles and permission-prompt state.
class NotificationPreferences {
  NotificationPreferences(this._prefs);

  static const askedKey = 'dootdoot.notif.asked';
  static const taskDueKey = 'dootdoot.notif.taskDue';
  static const dailyDigestKey = 'dootdoot.notif.dailyDigest';
  static const habitsKey = 'dootdoot.notif.habits';
  static const goalsKey = 'dootdoot.notif.goals';
  static const digestHourKey = 'dootdoot.notif.digestHour';

  final SharedPreferences _prefs;

  bool get permissionAsked => _prefs.getBool(askedKey) ?? false;

  Future<void> setPermissionAsked(bool value) =>
      _prefs.setBool(askedKey, value);

  bool get taskDueEnabled => _prefs.getBool(taskDueKey) ?? false;

  Future<void> setTaskDueEnabled(bool value) =>
      _prefs.setBool(taskDueKey, value);

  bool get dailyDigestEnabled => _prefs.getBool(dailyDigestKey) ?? false;

  Future<void> setDailyDigestEnabled(bool value) =>
      _prefs.setBool(dailyDigestKey, value);

  bool get habitsEnabled => _prefs.getBool(habitsKey) ?? false;

  Future<void> setHabitsEnabled(bool value) => _prefs.setBool(habitsKey, value);

  bool get goalsEnabled => _prefs.getBool(goalsKey) ?? false;

  Future<void> setGoalsEnabled(bool value) => _prefs.setBool(goalsKey, value);

  int get digestHour => _prefs.getInt(digestHourKey) ?? 8;

  Future<void> setDigestHour(int hour) =>
      _prefs.setInt(digestHourKey, hour.clamp(0, 23));

  /// Defaults turned on after the user grants OS notification permission.
  Future<void> enableRecommendedDefaults() async {
    await setTaskDueEnabled(true);
    await setDailyDigestEnabled(true);
  }
}
