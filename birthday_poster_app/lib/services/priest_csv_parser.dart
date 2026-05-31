import 'package:csv/csv.dart';

import '../models/priest_record.dart';

class PriestCsvParser {
  static List<PriestRecord> parseBirthdayCsv(String csvText) {
    return _parseRows(
      csvText,
      dateColumn: 'Born',
      mapRecord: (row, date) => PriestRecord(
        fullName: _cell(row, 'Name'),
        designation: _cell(row, 'Designation'),
        servingAt: _cell(row, 'Serving At'),
        address: _cell(row, 'Address'),
        birthDate: date,
      ),
    );
  }

  static List<PriestRecord> parseOrdinationCsv(String csvText) {
    return _parseRows(
      csvText,
      dateColumn: 'Ordination',
      mapRecord: (row, date) => PriestRecord(
        fullName: _cell(row, 'Name'),
        designation: _cell(row, 'Designation'),
        servingAt: _cell(row, 'Serving At'),
        address: _cell(row, 'Address'),
        ordinationDate: date,
      ),
    );
  }

  static List<PriestRecord> _parseRows(
    String csvText, {
    required String dateColumn,
    required PriestRecord Function(Map<String, String> row, DateTime? date)
        mapRecord,
  }) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvText);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((cell) => cell.toString().trim()).toList();
    final records = <PriestRecord>[];

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      final mapped = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        final value = i < row.length ? row[i].toString().trim() : '';
        mapped[headers[i]] = value;
      }

      final name = _cell(mapped, 'Name');
      if (name.isEmpty) continue;

      final date = parseSheetDate(_cell(mapped, dateColumn));
      records.add(mapRecord(mapped, date));
    }

    return records;
  }

  static String _cell(Map<String, String> row, String key) => row[key] ?? '';

  static DateTime? parseSheetDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final parts = value.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }
}
