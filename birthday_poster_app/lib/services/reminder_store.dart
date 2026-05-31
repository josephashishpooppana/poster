import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderStore extends ChangeNotifier {
  ReminderStore._();
  static final ReminderStore instance = ReminderStore._();

  static const _handledKey = 'handled_anniversary_ids';

  Future<Set<String>> handledIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_handledKey)?.toSet() ?? {};
  }

  Future<bool> isHandled(String eventId) async {
    final ids = await handledIds();
    return ids.contains(eventId);
  }

  Future<void> markHandled(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_handledKey)?.toSet() ?? {};
    ids.add(eventId);
    await prefs.setStringList(_handledKey, ids.toList());
    notifyListeners();
  }

  Future<void> pruneOldHandled(Set<String> activeIds) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_handledKey)?.toSet() ?? {};
    ids.retainWhere(activeIds.contains);
    await prefs.setStringList(_handledKey, ids.toList());
    notifyListeners();
  }

  Future<void> resetDayIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    const dayKey = 'handled_anniversary_day';
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final storedDay = prefs.getString(dayKey);
    if (storedDay != todayKey) {
      await prefs.setStringList(_handledKey, []);
      await prefs.setString(dayKey, todayKey);
      notifyListeners();
    }
  }

  static String encodePayload({
    required String type,
    required String priestKey,
    required int year,
    required String eventId,
  }) {
    return '{"type":"$type","priestKey":"$priestKey","year":$year,"eventId":"$eventId"}';
  }

  static Map<String, dynamic>? decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final typeMatch = RegExp(r'"type"\s*:\s*"([^"]+)"').firstMatch(raw);
      final keyMatch = RegExp(r'"priestKey"\s*:\s*"([^"]+)"').firstMatch(raw);
      final yearMatch = RegExp(r'"year"\s*:\s*(\d+)').firstMatch(raw);
      final idMatch = RegExp(r'"eventId"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (typeMatch == null || keyMatch == null || yearMatch == null) {
        return null;
      }
      return {
        'type': typeMatch.group(1),
        'priestKey': keyMatch.group(1),
        'year': int.parse(yearMatch.group(1)!),
        if (idMatch != null) 'eventId': idMatch.group(1),
      };
    } catch (_) {
      return null;
    }
  }
}
