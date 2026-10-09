// Stub classes for web platform — all methods are no-ops
class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings) async {}
  Future<void> cancelAll() async {}
  Future<void> cancel(int id) async {}
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      const [];
  Future<void> zonedSchedule(int id, String? title, String? body,
      dynamic scheduledDate, dynamic notificationDetails,
      {dynamic androidScheduleMode,
      dynamic uiLocalNotificationDateInterpretation,
      dynamic matchDateTimeComponents}) async {}
  Future<void> show(int id, String? title, String? body,
      dynamic notificationDetails,
      {String? payload}) async {}
  T? resolvePlatformSpecificImplementation<T>() => null;
}

/// Web has no scheduling queue to report on, so this only ever arrives empty.
class PendingNotificationRequest {
  final int id;
  final String? title;
  final String? body;
  final String? payload;
  const PendingNotificationRequest(this.id, this.title, this.body, this.payload);
}

class AndroidInitializationSettings {
  const AndroidInitializationSettings(String defaultIcon);
}

class DarwinInitializationSettings {
  const DarwinInitializationSettings(
      {bool requestAlertPermission = true,
      bool requestBadgePermission = true,
      bool requestSoundPermission = true});
}

class InitializationSettings {
  const InitializationSettings(
      {AndroidInitializationSettings? android,
      DarwinInitializationSettings? iOS});
}

class AndroidNotificationCategory {
  static const AndroidNotificationCategory alarm = AndroidNotificationCategory._();
  static const AndroidNotificationCategory event = AndroidNotificationCategory._();
  static const AndroidNotificationCategory reminder = AndroidNotificationCategory._();
  static const AndroidNotificationCategory status = AndroidNotificationCategory._();
  static const AndroidNotificationCategory service = AndroidNotificationCategory._();
  static const AndroidNotificationCategory call = AndroidNotificationCategory._();
  static const AndroidNotificationCategory email = AndroidNotificationCategory._();
  static const AndroidNotificationCategory message = AndroidNotificationCategory._();
  static const AndroidNotificationCategory navigation = AndroidNotificationCategory._();
  static const AndroidNotificationCategory progress = AndroidNotificationCategory._();
  static const AndroidNotificationCategory promo = AndroidNotificationCategory._();
  static const AndroidNotificationCategory recommendation = AndroidNotificationCategory._();
  static const AndroidNotificationCategory social = AndroidNotificationCategory._();
  static const AndroidNotificationCategory transport = AndroidNotificationCategory._();
  static const AndroidNotificationCategory sys = AndroidNotificationCategory._();
  const AndroidNotificationCategory._();
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(String channelId, String channelName,
      {String? channelDescription,
      dynamic importance,
      dynamic priority,
      bool playSound = true,
      bool enableVibration = true,
      dynamic sound,
      String? icon,
      dynamic largeIcon,
      dynamic color,
      dynamic visibility,
      dynamic styleInformation,
      dynamic category,
      dynamic audioAttributesUsage,
      bool ongoing = false,
      bool onlyAlertOnce = false,
      bool autoCancel = true,
      bool showWhen = true});
}

class NotificationVisibility {
  static const NotificationVisibility public = NotificationVisibility._();
  static const NotificationVisibility private = NotificationVisibility._();
  static const NotificationVisibility secret = NotificationVisibility._();
  const NotificationVisibility._();
}

class DrawableResourceAndroidBitmap {
  const DrawableResourceAndroidBitmap(String name);
}

class DefaultStyleInformation {
  const DefaultStyleInformation(bool htmlFormatTitle, bool htmlFormatBody);
}

class BigTextStyleInformation extends DefaultStyleInformation {
  const BigTextStyleInformation(String bigText,
      {String? contentTitle,
      String? summaryText,
      bool htmlFormatBigText = false,
      bool htmlFormatContent = false,
      bool htmlFormatContentTitle = false,
      bool htmlFormatSummaryText = false,
      bool htmlFormatTitle = false})
      : super(htmlFormatTitle, htmlFormatContent);
}

class InterruptionLevel {
  static const InterruptionLevel passive = InterruptionLevel._();
  static const InterruptionLevel active = InterruptionLevel._();
  static const InterruptionLevel timeSensitive = InterruptionLevel._();
  static const InterruptionLevel critical = InterruptionLevel._();
  const InterruptionLevel._();
}

class DarwinNotificationDetails {
  const DarwinNotificationDetails(
      {bool presentAlert = true,
      bool presentBadge = true,
      bool presentSound = true,
      String? sound,
      dynamic interruptionLevel});
}

class AudioAttributesUsage {
  static const AudioAttributesUsage notification = AudioAttributesUsage._();
  static const AudioAttributesUsage alarm = AudioAttributesUsage._();
  const AudioAttributesUsage._();
}

class AndroidNotificationChannel {
  const AndroidNotificationChannel(String id, String name,
      {String? description,
      dynamic importance,
      bool playSound = true,
      bool enableVibration = true,
      dynamic sound,
      AudioAttributesUsage audioAttributesUsage =
          AudioAttributesUsage.notification,
      bool showBadge = true});
}

class AndroidNotificationSound {
  const AndroidNotificationSound();
}

class RawResourceAndroidNotificationSound extends AndroidNotificationSound {
  const RawResourceAndroidNotificationSound(String name);
}

class UriAndroidNotificationSound extends AndroidNotificationSound {
  const UriAndroidNotificationSound(String uri);
}

class NotificationDetails {
  const NotificationDetails(
      {AndroidNotificationDetails? android, DarwinNotificationDetails? iOS});
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<void> requestNotificationsPermission() async {}
  Future<void> createNotificationChannel(dynamic channel) async {}
  Future<void> deleteNotificationChannel(String channelId) async {}
  Future<bool?> areNotificationsEnabled() async => false;
  Future<bool?> canScheduleExactNotifications() async => false;
  Future<bool?> requestExactAlarmsPermission() async => false;
}

class DateTimeComponents {
  static const DateTimeComponents time = DateTimeComponents._();
  static const DateTimeComponents dayOfWeekAndTime = DateTimeComponents._();
  static const DateTimeComponents dayOfMonthAndTime = DateTimeComponents._();
  static const DateTimeComponents dateAndTime = DateTimeComponents._();
  const DateTimeComponents._();
}

class Importance {
  static const Importance unspecified = Importance._();
  static const Importance none = Importance._();
  static const Importance min  = Importance._();
  static const Importance low  = Importance._();
  static const Importance defaultImportance = Importance._();
  static const Importance high = Importance._();
  static const Importance max  = Importance._();
  const Importance._();
}

class Priority {
  static const Priority min  = Priority._();
  static const Priority low  = Priority._();
  static const Priority defaultPriority = Priority._();
  static const Priority high = Priority._();
  static const Priority max  = Priority._();
  const Priority._();
}

class AndroidScheduleMode {
  static const AndroidScheduleMode alarmClock = AndroidScheduleMode._();
  static const AndroidScheduleMode exact = AndroidScheduleMode._();
  static const AndroidScheduleMode exactAllowWhileIdle = AndroidScheduleMode._();
  static const AndroidScheduleMode inexact = AndroidScheduleMode._();
  static const AndroidScheduleMode inexactAllowWhileIdle = AndroidScheduleMode._();
  const AndroidScheduleMode._();
}

class UILocalNotificationDateInterpretation {
  static const UILocalNotificationDateInterpretation absoluteTime =
      UILocalNotificationDateInterpretation._();
  const UILocalNotificationDateInterpretation._();
}

class FlutterTimezone {
  static Future<String> getLocalTimezone() async => 'Asia/Karachi';
}
