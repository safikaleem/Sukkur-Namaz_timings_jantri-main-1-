// Stub classes for web platform — all methods are no-ops
class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings) async {}
  Future<void> cancelAll() async {}
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
      dynamic styleInformation});
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

class DarwinNotificationDetails {
  const DarwinNotificationDetails(
      {bool presentAlert = true,
      bool presentBadge = true,
      bool presentSound = true,
      String? sound});
}

class AudioAttributesUsage {
  static const AudioAttributesUsage notification = AudioAttributesUsage._();
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
          AudioAttributesUsage.notification});
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
