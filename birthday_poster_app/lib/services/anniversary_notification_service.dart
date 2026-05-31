import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/anniversary_event.dart';
import 'poster_prefill_mapper.dart';
import 'priest_repository.dart';
import 'reminder_store.dart';

class AnniversaryNotificationService {
  AnniversaryNotificationService._();
  static final AnniversaryNotificationService instance =
      AnniversaryNotificationService._();

  static const _channelId = 'anniversary_reminders';
  static const _channelName = 'Anniversary Reminders';
  static const _createPosterActionId = 'create_poster';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String payload)? onNotificationTap;

  Future<void> initialize({
    required void Function(String payload) onTap,
  }) async {
    onNotificationTap = onTap;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Birthday and ordination anniversary reminders',
          importance: Importance.max,
        ),
      );
    }
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    onNotificationTap?.call(payload);
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
      return granted ?? true;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  Future<void> rescheduleAll() async {
    await _plugin.cancelAll();

    final events = PriestRepository.instance.eventsForNextMonths(12);
    final activeIds = events.map((event) => event.id).toSet();
    await ReminderStore.instance.pruneOldHandled(activeIds);

    for (final event in events) {
      final scheduled = _nextMidnight(event.anniversaryOn);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      await _plugin.zonedSchedule(
        _notificationId(event),
        event.title,
        PosterPrefillMapper.notificationBody(event),
        scheduled,
        _notificationDetails(event),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: ReminderStore.encodePayload(
          type: event.type.name,
          priestKey: event.priest.key,
          year: event.anniversaryOn.year,
          eventId: event.id,
        ),
      );
    }
  }

  Future<void> showImmediate(AnniversaryEvent event) async {
    await _plugin.show(
      _notificationId(event),
      event.title,
      PosterPrefillMapper.notificationBody(event),
      _notificationDetails(event),
      payload: ReminderStore.encodePayload(
        type: event.type.name,
        priestKey: event.priest.key,
        year: event.anniversaryOn.year,
        eventId: event.id,
      ),
    );
  }

  NotificationDetails _notificationDetails(AnniversaryEvent event) {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Birthday and ordination anniversary reminders',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      actions: [
        AndroidNotificationAction(
          _createPosterActionId,
          'Create Poster',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: _createPosterActionId,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static int _notificationId(AnniversaryEvent event) {
    return event.id.hashCode.abs().remainder(2147483646) + 1;
  }

  static tz.TZDateTime _nextMidnight(DateTime date) {
    final local = tz.local;
    return tz.TZDateTime(local, date.year, date.month, date.day);
  }

  Future<NotificationAppLaunchDetails?> launchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background tap is handled when the app resumes via getNotificationAppLaunchDetails.
}
