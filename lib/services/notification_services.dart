import 'package:calendar_app/screen/notified_page.dart';
import 'package:calendar_app/model/event.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // การตั้งค่าเริ่มต้นสำหรับ Android และ iOS
  static const _androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  static const _iosInitSettings = DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  static const _initSettings = InitializationSettings(
    android: _androidInitSettings,
    iOS: _iosInitSettings,
  );

  // การตั้งค่า NotificationDetails
  static const _defaultChannel = AndroidNotificationDetails(
    'default_channel',
    'Default Notifications',
    channelDescription: 'This channel is used for default notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  static const _scheduledChannel = AndroidNotificationDetails(
    'default_channel',
    'Scheduled Notifications',
    channelDescription: 'This channel is used for scheduled notifications',
    icon: '@mipmap/ic_launcher',
  );
  static const _defaultDetails = NotificationDetails(
    android: _defaultChannel,
    iOS: DarwinNotificationDetails(),
  );
  static const _scheduledDetails = NotificationDetails(android: _scheduledChannel);

  // ชื่อ task สำหรับ WorkManager
  static const String taskName = "notificationTask";

  /// เริ่มต้นระบบแจ้งเตือน
  Future<void> initializeNotification() async {
    await _configureLocalTimeZone();

    final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      _initSettings,
      onDidReceiveNotificationResponse: (response) async {
        await selectNotification(response.payload);
      },
    );
    print("Notification initialized: $initialized");

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print("Notification permission: $status");
      if (status.isDenied) {
        print("Please enable notifications in settings");
      }
    }
  }

  /// เริ่มต้น WorkManager
  Future<void> initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    print("WorkManager initialized");
  }

  /// ขอสิทธิ์การแจ้งเตือนสำหรับ iOS
  Future<void> requestIOSPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// แสดงการแจ้งเตือนทันที
  Future<void> displayNotification({
    required String title,
    required String body,
    String? startTime,
    String? endTime,
  }) async {
    print("Displaying immediate notification: $title - $body");
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      _defaultDetails,
      payload: "$title|$body|$startTime|$endTime|", // เพิ่ม startTime และ endTime ใน payload
    );
    print("Notification displayed successfully");
  }

  /// ตั้งการแจ้งเตือนตามเวลา (ใช้ WorkManager)
  Future<void> scheduledNotification(
    int hour,
    int minutes,
    Event event, {
    int reminderMinutes = 0,
    String? startTime,
    String? endTime,
  }) async {
    if (event.isSucceed == 1) {
      print("Event ${event.title} is already succeeded (isSucceed = 1), skipping notification");
      return;
    }

    final notificationId = _generateNotificationId(event);
    print("Using ID: $notificationId for event: ${event.Id}");

    if (event.remind != null && event.remind! > 0) {
      reminderMinutes = event.remind!;
      print("Using event.remind: $reminderMinutes minutes for reminder");
    } else {
      print("No remind value set, using default reminderMinutes: $reminderMinutes");
    }

    final scheduleDate = _convertTime(hour, minutes, event.repeat);
    final reminderDate = scheduleDate.subtract(Duration(minutes: reminderMinutes));
    final delay = reminderDate.difference(DateTime.now());

    if (delay.inSeconds < 0 && (event.repeat == 'None' || event.repeat == null)) {
      print("One-time event in the past: $reminderDate, skipping notification");
      return;
    }

    if (delay.inSeconds < 0) {
      print("Cannot schedule notification in the past: $reminderDate");
      return;
    }

    final taskId = event.Id ?? "task_${notificationId}";
    final defaultStartTime = "${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
    print("Scheduling notification for ${event.title} at $reminderDate with delay: ${delay.inSeconds} seconds (reminder $reminderMinutes minutes before $scheduleDate) - Task ID: $taskId");
    print("StartTime: $startTime, EndTime: $endTime");

    await Workmanager().registerOneOffTask(
      taskId,
      taskName,
      initialDelay: delay,
      inputData: {
        "title": event.title ?? "No Title",
        "description": event.description ?? "No Description",
        "originalTime": scheduleDate.toIso8601String(),
        "eventId": event.Id,
        "hour": hour,
        "minutes": minutes,
        "repeat": event.repeat,
        "reminderMinutes": reminderMinutes,
        "startTime": startTime ?? defaultStartTime,
        "endTime": endTime ?? "N/A",
      },
    );
    print("Scheduled WorkManager task for ${event.title} at $reminderDate (reminder $reminderMinutes minutes before $scheduleDate) - Task ID: $taskId");
  }

  /// ยกเลิก task เฉพาะตาม event
  Future<void> cancelTaskForEvent(Event event) async {
    final notificationId = _generateNotificationId(event);
    final taskId = event.Id ?? "task_${notificationId}";
    await Workmanager().cancelByUniqueName(taskId);
    print("Cancelled WorkManager task for event: ${event.title} (Task ID: $taskId)");
  }

  /// ล้าง Pending Notifications และ WorkManager tasks
  Future<void> clearPendingNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    await Workmanager().cancelAll();
    print("All pending notifications and WorkManager tasks cleared");
    await _logPendingNotifications("after clearing");
  }

  /// จัดการเมื่อผู้ใช้กดแจ้งเตือน
  Future<void> selectNotification(String? payload) async {
    print('Notification payload: $payload');
    if (payload != null) {
      final parts = payload.split("|");
      if (parts.length < 4) {
        print("Invalid payload format: $payload");
        payload = "$payload|No Description|N/A|N/A|";
      }
      print("Notification triggered and clicked: $payload");
      Get.to(() => NotifiedPage(label: payload));
    }
  }

  /// จัดการเมื่อได้รับการแจ้งเตือน (สำหรับ iOS)
  Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print("Received local notification: $id - $title - $body");
    Get.dialog(Text("Notification: $title"));
  }

  /// แปลงเวลาเป็น TZDateTime และปรับวันถ้าอยู่ในอดีต
  tz.TZDateTime _convertTime(int hour, int minutes, String? repeat) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduleDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minutes);
    print("Current time: $now, Initial schedule: $scheduleDate");

    if (scheduleDate.isBefore(now)) {
      switch (repeat) {
        case 'Daily':
          scheduleDate = scheduleDate.add(const Duration(days: 1));
          print("Daily event in past, adjusted to tomorrow: $scheduleDate");
          break;

        case 'Weekly':
          scheduleDate = scheduleDate.add(const Duration(days: 7));
          print("Weekly event in past, adjusted to next week: $scheduleDate");
          break;

        case 'Monthly':
          scheduleDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month + 1,
            now.day,
            hour,
            minutes,
          );
          print("Monthly event in past, adjusted to next month: $scheduleDate");
          break;

        case 'None':
        default:
          print("One-time event in past, will be skipped: $scheduleDate");
          break;
      }
    }

    return scheduleDate;
  }

  /// ตั้งค่า Timezone
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    print("Timezone configured: $timeZoneName");
  }

  /// สร้าง Notification ID
  int _generateNotificationId(Event event) {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 + (event.hashCode % 1000);
  }

  /// ตรวจสอบและขอสิทธิ์ Exact Alarm
  Future<bool> _checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.status;
    print("Exact alarm permission: $status");
    if (status.isDenied) {
      final newStatus = await Permission.scheduleExactAlarm.request();
      print("Exact alarm request result: $newStatus");
      return newStatus.isGranted;
    }
    return true;
  }

  /// บันทึกข้อมูล Pending Notifications
  Future<void> _logPendingNotifications(String phase) async {
    final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print("Pending notifications $phase: ${pending.length}");
    for (var request in pending) {
      print("ID: ${request.id}, Payload: ${request.payload}");
    }
  }

  /// รอและตรวจสอบเมื่อถึงเวลาการแจ้งเตือน
  Future<void> _waitAndCheckNotification(tz.TZDateTime scheduleDate, String title) async {
    final waitTime = scheduleDate.difference(DateTime.now());
    if (waitTime.inSeconds > 0 && waitTime.inSeconds < 300) {
      await Future.delayed(waitTime + const Duration(seconds: 5));
      print("Time passed, notification should have triggered for $title");
      await _logPendingNotifications("after time passed");
    }
  }
}

/// Callback สำหรับ WorkManager
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Executing WorkManager task: $task");
    final notificationService = NotificationService();
    final title = inputData?["title"] ?? "No Title";
    final description = inputData?["description"] ?? "No Description";
    final originalTime = DateTime.parse(inputData?["originalTime"] ?? DateTime.now().toIso8601String());
    final eventId = inputData?["eventId"];
    final hour = inputData?["hour"] as int?;
    final minutes = inputData?["minutes"] as int?;
    final repeat = inputData?["repeat"] as String?;
    final reminderMinutes = inputData?["reminderMinutes"] as int?;
    final startTime = inputData?["startTime"] as String?;
    final endTime = inputData?["endTime"] as String?;

    // แสดงการแจ้งเตือน
    await notificationService.displayNotification(
      title: reminderMinutes != null && reminderMinutes > 0 ? "Reminder: $title" : title,
      body: "$description (Event starts at ${originalTime.hour}:${originalTime.minute})",
      startTime: startTime,
      endTime: endTime,
    );
    print("WorkManager task executed: $title");

    if (eventId != null) {
      print("Updated isSucceed to 1 for event ID: $eventId");
    }

    if (repeat != null && repeat != 'None' && hour != null && minutes != null && reminderMinutes != null) {
      final event = Event(
        Id: eventId,
        title: title,
        description: description,
        repeat: repeat,
        isSucceed: 1,
        remind: reminderMinutes,
      );
      await notificationService.scheduledNotification(
        hour,
        minutes,
        event,
        reminderMinutes: reminderMinutes,
        startTime: startTime,
        endTime: endTime,
      );
      print("Rescheduled repeating task for $title (Repeat: $repeat)");
    }

    return Future.value(true);
  });
}