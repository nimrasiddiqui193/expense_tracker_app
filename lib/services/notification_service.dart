import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;
  static const int _budgetAlertId = 1002;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'expense_tracker_notifications',
        'Expense Tracker Notifications',
        channelDescription: 'Daily expense reminders and monthly budget alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    // The installed flutter_timezone version returns a String.
    final String localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    // This plugin version accepts InitializationSettings positionally.
    await _notifications.initialize(initializationSettings);

    await _requestPermissions();
    await scheduleDailyReminder();
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a daily reminder for 9:00 PM local time.
  static Future<void> scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
    );

    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _dailyReminderId,
      'Expense Tracker Reminder',
      'Take a moment to review and record your daily expenses.',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Shows a warning when spending reaches 80% of the monthly budget.
  /// This must be connected to your budget calculation to trigger.
  static Future<void> showBudgetThresholdAlert({
    required double totalSpent,
    required double monthlyBudget,
  }) async {
    if (monthlyBudget <= 0 || totalSpent < monthlyBudget * 0.8) {
      return;
    }

    final percentage = (totalSpent / monthlyBudget * 100).round();

    await _notifications.show(
      _budgetAlertId,
      'Monthly Budget Alert',
      'You have used $percentage% of your monthly budget. '
          'Review your spending to stay on track.',
      _notificationDetails,
    );
  }

  /// Cancels the daily reminder.
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
  }

  /// Cancels the budget alert notification.
  static Future<void> cancelBudgetAlert() async {
    await _notifications.cancel(_budgetAlertId);
  }
}
