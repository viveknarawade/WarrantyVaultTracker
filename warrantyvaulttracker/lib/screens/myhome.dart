import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:warrantyvaulttracker/services/notifi_service.dart';
import 'package:timezone/timezone.dart' as tz; // Added this

class Myhome extends StatefulWidget {
  const Myhome({super.key});

  @override
  State<Myhome> createState() => _MyhomeState();
}

class _MyhomeState extends State<Myhome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
      
            DateTime testDate = DateTime.now().add(const Duration(seconds: 60));

            try {
              // 2. Schedule the notification
              await NotificationService().notificationsPlugin.zonedSchedule(
                    999,
                    'Test Notification',
                    'The warranty tracker is working!',
                    tz.TZDateTime.from(testDate, tz.local),
                    NotificationService().notificationDetails(),
                    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                    uiLocalNotificationDateInterpretation:
                        UILocalNotificationDateInterpretation.absoluteTime,
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Scheduled! Close the app now to test.")),
                );
              }
            } catch (e) {
              // Catch errors like missing permissions
              debugPrint("Error scheduling test: $e");
            }
          },
          child: const Text("Test Notifications (5 Seconds)"),
        ),
      ),
    );
  }
}