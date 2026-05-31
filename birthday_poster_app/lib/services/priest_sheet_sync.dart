import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/anniversary_event.dart';
import '../models/priest_record.dart';
import 'priest_csv_parser.dart';

/// Syncs priest edits back to Google Sheets via a deployed Apps Script web app.
///
/// Deploy [google_apps_script/update_priest.gs] and set [_webAppUrl] to the
/// script URL (ending in /exec).
class PriestSheetSync {
  PriestSheetSync._();
  static final PriestSheetSync instance = PriestSheetSync._();

  /// Set this to your deployed Google Apps Script web app URL.
  static const String webAppUrl = 'https://script.google.com/macros/s/AKfycbxAZtFm2-pdsi3nPmQtjzZEaaBR_24yAUipGc9s9BgF3sI4A3-UHn_LbyqPiPtHeeW-Bw/exec';

  bool get isConfigured => webAppUrl.isNotEmpty;

  Future<PriestSheetSyncResult> syncUpdate({
    required String originalKey,
    required PriestRecord updated,
    required AnniversaryType eventType,
  }) async {
    if (!isConfigured) {
      return const PriestSheetSyncResult(
        syncedToSheet: false,
        message: 'Saved locally. Configure Apps Script URL to sync to Google Sheets.',
      );
    }

    try {
      final date = eventType == AnniversaryType.birthday
          ? updated.birthDate
          : updated.ordinationDate;

      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'originalKey': originalKey,
          'sheet': eventType == AnniversaryType.birthday ? 'birthday' : 'ordination',
          'name': updated.fullName,
          'designation': updated.designation,
          'servingAt': updated.servingAt,
          'address': updated.address,
          if (date != null) 'date': PriestCsvParser.formatSheetDate(date),
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body['success'] == true) {
          return const PriestSheetSyncResult(
            syncedToSheet: true,
            message: 'Updated in Google Sheet.',
          );
        }
      }

      return PriestSheetSyncResult(
        syncedToSheet: false,
        message: 'Saved locally. Sheet sync failed (${response.statusCode}).',
      );
    } catch (_) {
      return const PriestSheetSyncResult(
        syncedToSheet: false,
        message: 'Saved locally. Could not reach Google Sheet.',
      );
    }
  }
}

class PriestSheetSyncResult {
  const PriestSheetSyncResult({
    required this.syncedToSheet,
    required this.message,
  });

  final bool syncedToSheet;
  final String message;
}
