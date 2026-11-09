/// Android notification channel ids and display metadata.
///
/// iOS has no per-channel system toggles; these ids are still used for
/// grouping schedules and in-app settings.
abstract final class DootNotificationChannels {
  static const taskDue = 'task_due';
  static const dailyDigest = 'daily_digest';
  static const habits = 'habits';
  static const goals = 'goals';

  static const taskDueName = 'Task due reminders';
  static const taskDueDescription =
      'Alerts when a task reaches its due date or time.';

  static const dailyDigestName = 'Today summary';
  static const dailyDigestDescription =
      'A morning overview of tasks scheduled for today.';

  static const habitsName = 'Habit reminders';
  static const habitsDescription =
      'Nudges for habits that still need completing today.';

  static const goalsName = 'Goal deadlines';
  static const goalsDescription =
      'Reminders when a goal target date is approaching.';
}
