import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupMessageHandlers();

    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');

    subscribeToTopic('all_devices');
  }

  // // Add this method for scheduling notifications
  // Future<void> scheduleNotification({
  //   required String title,
  //   required String body,
  //   required DateTime scheduledDate,
  //   String? appointmentId,
  // }) async {
  //   if (!_isFlutterLocalNotificationsInitialized) {
  //     await setupFlutterNotifications();
  //   }

  //   final now = DateTime.now();
  //   if (scheduledDate.isBefore(now)) {
  //     debugPrint('Cannot schedule notification for past time');
  //     return;
  //   }

  //   final id = appointmentId?.hashCode ??
  //       scheduledDate.millisecondsSinceEpoch.hashCode;

  //   try {
  //     await _localNotifications.zonedSchedule(
  //       id,
  //       title,
  //       body,
  //       tz.TZDateTime.from(scheduledDate, tz.local),
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           'appointment_channel',
  //           'Appointment Reminders',
  //           channelDescription: 'Notifications for upcoming appointments',
  //           importance: Importance.max,
  //           priority: Priority.max,
  //           fullScreenIntent: true,
  //           category: AndroidNotificationCategory.reminder,
  //           visibility: NotificationVisibility.public,
  //           color: const Color(0xFFFF0000),
  //           colorized: true,
  //           ongoing: true,
  //           autoCancel: false,
  //           enableLights: true,
  //           ledColor: const Color(0xFFFF0000),
  //           ledOnMs: 1000,
  //           ledOffMs: 500,
  //           icon: '@mipmap/ic_launcher',
  //           ticker: 'APPOINTMENT REMINDER',
  //         ),
  //       ),
  //       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //       uiLocalNotificationDateInterpretation:
  //           UILocalNotificationDateInterpretation.absoluteTime,
  //     );

  //     debugPrint('Scheduled notification for ${scheduledDate.toString()}');
  //   } catch (e) {
  //     debugPrint('Error scheduling notification: $e');
  //   }
  // }

  // // Add this method to cancel scheduled notifications
  // Future<void> cancelScheduledNotification(String appointmentId) async {
  //   final id = appointmentId.hashCode;
  //   await _localNotifications.cancel(id);
  //   debugPrint('Cancelled notification with id: $id');
  // }

  DateTime _parseAppointmentDateTime(String dateStr, String timeStr) {
    debugPrint('Parsing date: $dateStr, time: $timeStr');

    timeStr = timeStr.trim();

    int hour;
    int minute = 0;

    // Parse time in format "3:05 PM"
    final RegExp timeRegex =
        RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)', caseSensitive: false);
    final Match? match = timeRegex.firstMatch(timeStr);

    if (match != null) {
      hour = int.parse(match.group(1)!);
      minute = int.parse(match.group(2)!);
      String period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    } else {
      throw FormatException('Invalid time format: $timeStr');
    }

    final dateTime =
        DateTime.parse(dateStr).add(Duration(hours: hour, minutes: minute));
    debugPrint('Parsed DateTime: $dateTime');

    return dateTime;
  }

  Future<void> scheduleAppointmentNotifications(
    String appointmentId,
    String title,
    String dateStr,
    String timeStr,
  ) async {
    try {
      final scheduledTime = _parseAppointmentDateTime(dateStr, timeStr);
      final now = DateTime.now();

      debugPrint('\n=== Scheduling Notifications ===');
      debugPrint('Current time: $now');
      debugPrint('Scheduled time: $scheduledTime');

      final timeUntilAppointment = scheduledTime.difference(now);
      final reminderTime = scheduledTime.subtract(const Duration(minutes: 30));
      final timeUntilReminder = reminderTime.difference(now);

      debugPrint(
          'Time until appointment: ${timeUntilAppointment.inMinutes} minutes');
      debugPrint('Time until reminder: ${timeUntilReminder.inMinutes} minutes');

      // Send immediate confirmation
      await sendNotification(
        'Appointment Scheduled',
        'Your appointment "$title" is scheduled for $timeStr',
        isAppointment: true,
      );

      // Schedule 30-minute reminder
      if (timeUntilReminder.inMinutes > 0) {
        Timer(timeUntilReminder, () {
          sendNotification(
            'Appointment Reminder',
            'Your appointment "$title" starts in 30 minutes',
            isAppointment: true,
          );
          debugPrint('30-minute reminder sent at: ${DateTime.now()}');
        });
      }

      // Schedule start time notification
      if (timeUntilAppointment.inMinutes > 0) {
        Timer(timeUntilAppointment, () {
          sendNotification(
            'Appointment Starting',
            'Your appointment "$title" is starting now',
            isAppointment: true,
          );
          debugPrint('Start time notification sent at: ${DateTime.now()}');
        });
      }
    } catch (e) {
      debugPrint('Error scheduling appointment notifications: $e');
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    const emergencyChannel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Alerts',
      description:
          'Critical emergency notifications that require immediate attention',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000),
      playSound: true,
      showBadge: true,
    );

    const appointmentChannel = AndroidNotificationChannel(
      'appointment_channel',
      'Appointment Reminders',
      description: 'Notifications for upcoming appointments',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF0000FF),
      playSound: true,
      showBadge: true,
    );

    final flutterLocalNotificationsPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await flutterLocalNotificationsPlugin
        ?.createNotificationChannel(emergencyChannel);
    await flutterLocalNotificationsPlugin
        ?.createNotificationChannel(appointmentChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      debugPrint('Emergency notification: ${notification.title}');
      debugPrint('Emergency details: ${notification.body}');

      await _localNotifications.show(
        notification.hashCode,
        '🚨 EMERGENCY: ${notification.title?.toUpperCase()}',
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_channel',
            'Emergency Alerts',
            channelDescription:
                'Critical emergency notifications that require immediate attention',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            color: const Color(0xFFFF0000),
            colorized: true,
            ongoing: true,
            autoCancel: false,
            enableLights: true,
            ledColor: const Color(0xFFFF0000),
            ledOnMs: 1000,
            ledOffMs: 500,
            icon: '@mipmap/ic_launcher',
            ticker: 'EMERGENCY ALERT',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      //open chat screen
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint("Subscribed to $topic");
  }

  Future<String?> fetchAccessToken() async {
    try {
      DatabaseEvent event = await _dbRef.child('accesstoken').once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        String accessToken = snapshot.value.toString();
        debugPrint('Access token fetched: $accessToken');
        return accessToken;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to fetch access token: $e');
      return null;
    }
  }

  Future<void> sendNotification(String title, String body,
      {bool isAppointment = false}) async {
    if (!_isFlutterLocalNotificationsInitialized) {
      await setupFlutterNotifications();
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      isAppointment ? title : '🚨 EMERGENCY: ${title.toUpperCase()}',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isAppointment ? 'appointment_channel' : 'emergency_channel',
          isAppointment ? 'Appointment Reminders' : 'Emergency Alerts',
          channelDescription: isAppointment
              ? 'Notifications for upcoming appointments'
              : 'Critical emergency notifications that require immediate attention',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: isAppointment
              ? AndroidNotificationCategory.reminder
              : AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          color: const Color(0xFFFF0000),
          colorized: true,
          ongoing: true,
          autoCancel: false,
          enableLights: true,
          ledColor: const Color(0xFFFF0000),
          ledOnMs: 1000,
          ledOffMs: 500,
          icon: '@mipmap/ic_launcher',
          ticker: isAppointment ? 'APPOINTMENT REMINDER' : 'EMERGENCY ALERT',
        ),
      ),
    );

    String? accessToken = await fetchAccessToken();
    if (accessToken == null) return;

    final messagePayload = {
      'message': {
        'topic': 'all_devices',
        'notification': {
          'title':
              isAppointment ? title : '🚨 EMERGENCY: ${title.toUpperCase()}',
          'body': body,
        },
        'android': {
          'notification': {
            'channel_id':
                isAppointment ? 'appointment_channel' : 'emergency_channel',
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
            'color': '#FF0000',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true
          },
          'priority': 'high'
        }
      }
    };

    const url =
        'https://fcm.googleapis.com/v1/projects/thermal-origin-425102-c7/messages:send';
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(messagePayload),
    );

    if (response.statusCode == 200) {
      debugPrint('Notification sent successfully');
    } else {
      debugPrint('Error sending notification: ${response.body}');
    }
  }
}
