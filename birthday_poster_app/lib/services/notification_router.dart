import 'package:flutter/material.dart';

import '../models/anniversary_event.dart';
import '../screens/birthday_poster_screen.dart';
import '../screens/ordination_poster_screen.dart';
import 'poster_prefill_mapper.dart';
import 'priest_repository.dart';
import 'reminder_store.dart';

class NotificationRouter {
  NotificationRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> handlePayload(String payload) async {
    final decoded = ReminderStore.decodePayload(payload);
    if (decoded == null) return;

    final typeName = decoded['type'] as String?;
    final priestKey = decoded['priestKey'] as String?;
    final yearRaw = decoded['year'];
    final year = yearRaw is int ? yearRaw : int.tryParse('$yearRaw');
    final eventId = decoded['eventId'] as String?;

    if (typeName == null || priestKey == null || year == null) {
      return;
    }

    final priest = PriestRepository.instance.findByKey(priestKey);
    if (priest == null) return;

    final type = AnniversaryType.values.byName(typeName);
    final sourceDate = type == AnniversaryType.birthday
        ? priest.birthDate
        : priest.ordinationDate;
    if (sourceDate == null) return;

    final event = AnniversaryEvent(
      type: type,
      priest: priest,
      sourceDate: sourceDate,
      anniversaryOn: DateTime(year, sourceDate.month, sourceDate.day),
    );

    if (eventId != null) {
      await ReminderStore.instance.markHandled(eventId);
    }

    _openPoster(event);
  }

  static Future<void> openPosterFromEvent(
    AnniversaryEvent event, {
    bool markHandled = false,
  }) async {
    if (markHandled) {
      await ReminderStore.instance.markHandled(event.id);
    }
    _openPoster(event);
  }

  static Future<void> openFromEvent(AnniversaryEvent event) async {
    await openPosterFromEvent(event, markHandled: true);
  }

  static void _openPoster(AnniversaryEvent event) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final initialData = PosterPrefillMapper.fromEvent(event);
    final screen = switch (event.type) {
      AnniversaryType.birthday => BirthdayPosterScreen(initialData: initialData),
      AnniversaryType.ordination =>
        OrdinationPosterScreen(initialData: initialData),
    };

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
