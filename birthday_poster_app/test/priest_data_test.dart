import 'package:birthday_poster_app/models/anniversary_event.dart';
import 'package:birthday_poster_app/services/poster_prefill_mapper.dart';
import 'package:birthday_poster_app/services/priest_csv_parser.dart';
import 'package:birthday_poster_app/services/priest_name_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses birthday csv row', () {
    const csv = '''
Name,Designation,Serving At,Address,Born,Phone,Email
REV. FR. ANOOP PAUL BLAMPARAMBIL,Assistant Vicar,"St Sebastian's Church, Chellanam",,04/01/1992,123,test@example.com
''';

    final records = PriestCsvParser.parseBirthdayCsv(csv);
    expect(records, hasLength(1));
    expect(records.first.fullName, contains('ANOOP PAUL'));
    expect(records.first.designation, 'Assistant Vicar');
    expect(records.first.birthDate, DateTime(1992, 1, 4));
  });

  test('parses priest name into poster fields', () {
    final parsed = PriestNameParser.parse('REV. FR. JACOB ELYAS THUNDATHIL');
    expect(parsed.designation, 'Rev. Fr.');
    expect(parsed.givenName, 'JACOB ELYAS');
    expect(parsed.familyName, 'Thundathil');
  });

  test('builds notification body with designation and serving at', () {
    final records = PriestCsvParser.parseBirthdayCsv('''
Name,Designation,Serving At,Address,Born,Phone,Email
REV. FR. ANOOP PAUL BLAMPARAMBIL,Assistant Vicar,"St Sebastian Church",,04/01/1992,,
''');
    final priest = records.first;
    final body = PosterPrefillMapper.notificationBody(
      AnniversaryEvent(
        type: AnniversaryType.birthday,
        priest: priest,
        sourceDate: priest.birthDate!,
        anniversaryOn: DateTime(2026, 1, 4),
      ),
    );

    expect(body, contains('ANOOP PAUL'));
    expect(body, contains('Assistant Vicar'));
    expect(body, contains('St Sebastian Church'));
  });
}
