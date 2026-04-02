import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int _getNotificationId(String warrantyId) => warrantyId.hashCode.abs();

  Future<void> cancelWarrantyNotifications(String warrantyId) async {
    int baseId = _getNotificationId(warrantyId);
    await notificationsPlugin.cancel(baseId + 0);
    await notificationsPlugin.cancel(baseId + 1);
    await notificationsPlugin.cancel(baseId + 2);
  }

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
      },
    );
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails(
          'warranty_alerts',
          'Warranty Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails());
  }

  Future<void> scheduleWarrantyNotifications({
    required String warrantyId,
    required String productName,
    required DateTime expiryDate,
  }) async {
    int baseId = _getNotificationId(warrantyId);

    List<Duration> offsets = [
      const Duration(days: 30),
      const Duration(days: 7),
      const Duration(days: 0),
    ];

    for (int i = 0; i < offsets.length; i++) {
      DateTime scheduleDate = expiryDate.subtract(offsets[i]);

      DateTime scheduledAtTenAM = DateTime(
          scheduleDate.year, scheduleDate.month, scheduleDate.day, 10, 0, 0);

      log("Scheduling notification ID ${baseId + i} for $scheduledAtTenAM");

      if (scheduledAtTenAM.isAfter(DateTime.now())) {
        await notificationsPlugin.zonedSchedule(
          baseId + i,
          'Warranty Alert: $productName',
          i == 2
              ? 'Your warranty expires today!'
              : 'Expires in ${offsets[i].inDays} days',
          // ✅ FIX: Use 'scheduledAtTenAM' here instead of 'scheduleDate'
          tz.TZDateTime.from(scheduledAtTenAM, tz.local),
          notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.request().isDenied) {
      }

      var status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      if (await Permission.scheduleExactAlarm.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

}
