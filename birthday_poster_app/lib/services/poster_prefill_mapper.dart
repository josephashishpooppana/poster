import 'package:intl/intl.dart';

import '../models/anniversary_event.dart';
import '../models/poster_data.dart';
import '../models/priest_record.dart';
import 'priest_name_parser.dart';

class PosterPrefillMapper {
  static PosterData fromEvent(AnniversaryEvent event) {
    return fromPriest(
      priest: event.priest,
      anniversaryDate: event.anniversaryOn,
    );
  }

  static PosterData fromPriest({
    required PriestRecord priest,
    required DateTime anniversaryDate,
  }) {
    final parsedName = PriestNameParser.parse(priest.fullName);
    final dateText = DateFormat('MMM dd').format(anniversaryDate).toUpperCase();

    final roleTitle = priest.designation.trim();
    final servingAt = priest.servingAt.trim();
    final address = priest.address.trim();

    String location = '';
    if (servingAt.isNotEmpty) {
      location = servingAt;
    } else if (roleTitle.isEmpty && address.isNotEmpty) {
      location = address;
    }

    return PosterData(
      dateText: dateText,
      designation: parsedName.designation,
      givenName: parsedName.givenName,
      familyName: parsedName.familyName,
      positions: [
        ChurchPosition(
          title: roleTitle,
          location: location,
        ),
      ],
    );
  }

  static String notificationBody(AnniversaryEvent event) {
    final priest = event.priest;
    final lines = <String>[
      priest.fullName,
      DateFormat('d MMM').format(event.anniversaryOn),
    ];

    if (priest.designation.trim().isNotEmpty) {
      lines.add(priest.designation.trim());
    }
    if (priest.servingAt.trim().isNotEmpty) {
      lines.add(priest.servingAt.trim());
    }
    if (priest.designation.trim().isEmpty &&
        priest.servingAt.trim().isEmpty &&
        priest.address.trim().isNotEmpty) {
      lines.add(priest.address.trim());
    }

    return lines.join('\n');
  }
}
