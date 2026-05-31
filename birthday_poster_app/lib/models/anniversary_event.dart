import 'priest_record.dart';

enum AnniversaryType { birthday, ordination }

class AnniversaryEvent {
  const AnniversaryEvent({
    required this.type,
    required this.priest,
    required this.sourceDate,
    required this.anniversaryOn,
  });

  final AnniversaryType type;
  final PriestRecord priest;
  final DateTime sourceDate;
  final DateTime anniversaryOn;

  String get id => '${type.name}-${priest.key}-${anniversaryOn.year}';

  String get title => switch (type) {
        AnniversaryType.birthday => 'Birthday Anniversary',
        AnniversaryType.ordination => 'Ordination Anniversary',
      };
}
