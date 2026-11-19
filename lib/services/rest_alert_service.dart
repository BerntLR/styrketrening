import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Alert when a rest period is over, also when the screen is locked or the
/// app is in the background. One pending alert at a time.
class RestAlertService {
  RestAlertService._();
  static final RestAlertService instance = RestAlertService._();

  static const int _id = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _asked = false;

  bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> _init() async {
    if (_ready || !_supported) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks for permission once per app start (the system only shows the
  /// dialog the first time).
  Future<void> _askPermission() async {
    if (_asked) return;
    _asked = true;
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true, badge: false);
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  /// Plans the alert at [end]. Replaces any earlier alert.
  Future<void> schedule(
    DateTime end, {
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    try {
      await _init();
      await _askPermission();
      await _plugin.cancel(_id);
      await _plugin.zonedSchedule(
        _id,
        title,
        body,
        tz.TZDateTime.from(end.toUtc(), tz.UTC),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rest_timer',
            'Rest timer',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // No alert is better than a crash; the in-app timer still works.
    }
  }

  Future<void> cancel() async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancel(_id);
    } catch (_) {}
  }
}
