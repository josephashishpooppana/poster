import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anniversary_event.dart';
import '../models/priest_record.dart';
import 'priest_csv_parser.dart';
import 'priest_sheet_sync.dart';

class PriestRepository {
  PriestRepository._();
  static final PriestRepository instance = PriestRepository._();

  static const _birthdaySheetUrl =
      'https://docs.google.com/spreadsheets/d/174QqITzlKsmpF-15KtkccLkpYSzOKLqyi8eXpI_0oxM/export?format=csv&gid=1721766266';
  static const _ordinationSheetUrl =
      'https://docs.google.com/spreadsheets/d/174QqITzlKsmpF-15KtkccLkpYSzOKLqyi8eXpI_0oxM/export?format=csv&gid=825888209';

  static const _birthdayAsset = 'assets/data/dob.csv';
  static const _ordinationAsset = 'assets/data/ordination.csv';
  static const _birthdayCacheFile = 'dob_cache.csv';
  static const _ordinationCacheFile = 'ordination_cache.csv';
  static const _lastSyncKey = 'priest_data_last_sync';

  List<PriestRecord> _priests = [];
  DateTime? _lastSync;

  List<PriestRecord> get priests => List.unmodifiable(_priests);
  DateTime? get lastSync => _lastSync;

  Future<void> initialize({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    _lastSync = _readTimestamp(prefs.getString(_lastSyncKey));

    String birthdayCsv;
    String ordinationCsv;

    if (forceRefresh || await _shouldRefresh()) {
      final fetched = await _fetchRemoteCsvs();
      if (fetched != null) {
        birthdayCsv = fetched.$1;
        ordinationCsv = fetched.$2;
        await _writeCache(birthdayCsv, ordinationCsv);
        _lastSync = DateTime.now();
        await prefs.setString(_lastSyncKey, _lastSync!.toIso8601String());
      } else {
        final cached = await _readCache();
        if (cached != null) {
          birthdayCsv = cached.$1;
          ordinationCsv = cached.$2;
        } else {
          birthdayCsv = await rootBundle.loadString(_birthdayAsset);
          ordinationCsv = await rootBundle.loadString(_ordinationAsset);
        }
      }
    } else {
      final cached = await _readCache();
      if (cached != null) {
        birthdayCsv = cached.$1;
        ordinationCsv = cached.$2;
      } else {
        birthdayCsv = await rootBundle.loadString(_birthdayAsset);
        ordinationCsv = await rootBundle.loadString(_ordinationAsset);
      }
    }

    _priests = _mergeRecords(
      PriestCsvParser.parseBirthdayCsv(birthdayCsv),
      PriestCsvParser.parseOrdinationCsv(ordinationCsv),
    );
  }

  Future<bool> _shouldRefresh() async {
    if (_lastSync == null) return true;
    return DateTime.now().difference(_lastSync!) > const Duration(hours: 24);
  }

  Future<(String, String)?> _fetchRemoteCsvs() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(_birthdaySheetUrl)),
        http.get(Uri.parse(_ordinationSheetUrl)),
      ]);

      if (responses.any((response) => response.statusCode != 200)) {
        return null;
      }

      return (responses[0].body, responses[1].body);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String birthdayCsv, String ordinationCsv) async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_birthdayCacheFile').writeAsString(birthdayCsv);
    await File('${dir.path}/$_ordinationCacheFile')
        .writeAsString(ordinationCsv);
  }

  Future<(String, String)?> _readCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final birthdayFile = File('${dir.path}/$_birthdayCacheFile');
      final ordinationFile = File('${dir.path}/$_ordinationCacheFile');
      if (!birthdayFile.existsSync() || !ordinationFile.existsSync()) {
        return null;
      }
      return (
        await birthdayFile.readAsString(),
        await ordinationFile.readAsString(),
      );
    } catch (_) {
      return null;
    }
  }

  static List<PriestRecord> _mergeRecords(
    List<PriestRecord> birthdayRows,
    List<PriestRecord> ordinationRows,
  ) {
    final merged = <String, PriestRecord>{};

    for (final row in birthdayRows) {
      merged[row.key] = row;
    }

    for (final row in ordinationRows) {
      final existing = merged[row.key];
      merged[row.key] =
          existing == null ? row : existing.merge(row).copyWith(
                fullName: _preferLonger(existing.fullName, row.fullName),
              );
    }

    return merged.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  static String _preferLonger(String a, String b) => a.length >= b.length ? a : b;

  static DateTime? _readTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  List<AnniversaryEvent> eventsBetween(DateTime start, DateTime end) {
    final events = <AnniversaryEvent>[];
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    for (final priest in _priests) {
      if (priest.birthDate != null) {
        events.addAll(
          _occurrencesFor(
            type: AnniversaryType.birthday,
            priest: priest,
            sourceDate: priest.birthDate!,
            startDay: startDay,
            endDay: endDay,
          ),
        );
      }
      if (priest.ordinationDate != null) {
        events.addAll(
          _occurrencesFor(
            type: AnniversaryType.ordination,
            priest: priest,
            sourceDate: priest.ordinationDate!,
            startDay: startDay,
            endDay: endDay,
          ),
        );
      }
    }

    events.sort((a, b) => a.anniversaryOn.compareTo(b.anniversaryOn));
    return events;
  }

  List<AnniversaryEvent> eventsOn(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return eventsBetween(start, start);
  }

  List<AnniversaryEvent> eventsForNextMonths(int months) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month + months, now.day);
    return eventsBetween(start, end);
  }

  /// All upcoming birthdays and ordinations from today onward (no count limit).
  List<AnniversaryEvent> upcomingEvents({int yearsAhead = 10}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year + yearsAhead, now.month, now.day);
    return eventsBetween(start, end);
  }

  Future<PriestSheetSyncResult> updatePriest({
    required String originalKey,
    required PriestRecord updated,
    required AnniversaryType eventType,
  }) async {
    final index = _priests.indexWhere((p) => p.key == originalKey);
    if (index == -1) {
      return const PriestSheetSyncResult(
        syncedToSheet: false,
        message: 'Priest not found.',
      );
    }

    final existing = _priests[index];
    final merged = existing.copyWith(
      fullName: updated.fullName,
      designation: updated.designation,
      servingAt: updated.servingAt,
      address: updated.address,
      birthDate: eventType == AnniversaryType.birthday
          ? updated.birthDate ?? existing.birthDate
          : existing.birthDate,
      ordinationDate: eventType == AnniversaryType.ordination
          ? updated.ordinationDate ?? existing.ordinationDate
          : existing.ordinationDate,
    );

    _priests[index] = merged;
    _priests.sort((a, b) => a.fullName.compareTo(b.fullName));

    await _updateCachedCsvs(
      originalKey: originalKey,
      updated: merged,
      eventType: eventType,
    );

    return PriestSheetSync.instance.syncUpdate(
      originalKey: originalKey,
      updated: merged,
      eventType: eventType,
    );
  }

  Future<void> _updateCachedCsvs({
    required String originalKey,
    required PriestRecord updated,
    required AnniversaryType eventType,
  }) async {
    final cached = await _readCache();
    var birthdayCsv = cached?.$1;
    var ordinationCsv = cached?.$2;

    if (birthdayCsv == null || ordinationCsv == null) {
      try {
        birthdayCsv ??= await rootBundle.loadString(_birthdayAsset);
        ordinationCsv ??= await rootBundle.loadString(_ordinationAsset);
      } catch (_) {
        return;
      }
    }

    if (eventType == AnniversaryType.birthday) {
      birthdayCsv = PriestCsvParser.updateBirthdayRow(
        birthdayCsv,
        originalKey,
        name: updated.fullName,
        designation: updated.designation,
        servingAt: updated.servingAt,
        address: updated.address,
        birthDate: updated.birthDate,
      );
    } else {
      ordinationCsv = PriestCsvParser.updateOrdinationRow(
        ordinationCsv,
        originalKey,
        name: updated.fullName,
        designation: updated.designation,
        servingAt: updated.servingAt,
        address: updated.address,
        ordinationDate: updated.ordinationDate,
      );
    }

    await _writeCache(birthdayCsv, ordinationCsv);
  }

  PriestRecord? findByKey(String key) {
    for (final priest in _priests) {
      if (priest.key == key) return priest;
    }
    return null;
  }

  static List<AnniversaryEvent> _occurrencesFor({
    required AnniversaryType type,
    required PriestRecord priest,
    required DateTime sourceDate,
    required DateTime startDay,
    required DateTime endDay,
  }) {
    final events = <AnniversaryEvent>[];
    for (var year = startDay.year; year <= endDay.year; year++) {
      final occurrence = DateTime(year, sourceDate.month, sourceDate.day);
      if (occurrence.isBefore(startDay) || occurrence.isAfter(endDay)) {
        continue;
      }
      events.add(
        AnniversaryEvent(
          type: type,
          priest: priest,
          sourceDate: sourceDate,
          anniversaryOn: occurrence,
        ),
      );
    }
    return events;
  }
}
