class ChurchPosition {
  ChurchPosition({this.title = '', this.location = ''});

  String title;
  String location;

  ChurchPosition copyWith({String? title, String? location}) {
    return ChurchPosition(
      title: title ?? this.title,
      location: location ?? this.location,
    );
  }
}

class PosterData {
  PosterData({
    this.dateText = 'APR 24',
    this.designation = 'Rev. Fr.',
    this.givenName = 'JACOB ELYAS',
    this.familyName = 'Thundathil',
    this.familyOffsetX = 34,
    this.familyOffsetY = -0.15,
    this.familyFontSize = 3.2,
    this.photoPosX = 50,
    this.photoPosY = 50,
    this.photoZoom = 100,
    this.rolesLeft = 50.1,
    this.rolesTop = 60.4,
    this.rolesWidth = 44,
    this.rolesHeight = 16.5,
    this.rolesPadBottom = 0.25,
    this.rolesAlign = RolesVerticalAlign.bottom,
    this.rolesTextScale = 1.05,
    List<ChurchPosition>? positions,
  }) : positions = positions ??
            [
              ChurchPosition(
                title: 'Assistant Vicar',
                location: 'St. Thomas More Church, Palluruthy',
              ),
            ];

  String dateText;
  String designation;
  String givenName;
  String familyName;
  double familyOffsetX;
  double familyOffsetY;
  double familyFontSize;
  double photoPosX;
  double photoPosY;
  double photoZoom;
  double rolesLeft;
  double rolesTop;
  double rolesWidth;
  double rolesHeight;
  double rolesPadBottom;
  RolesVerticalAlign rolesAlign;
  double rolesTextScale;
  List<ChurchPosition> positions;

  ({String month, String day}) get parsedDate {
    final parts = dateText.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (month: 'APR', day: '24');
    if (parts.length == 1) return (month: parts[0].toUpperCase(), day: '');
    return (
      month: parts[0].toUpperCase(),
      day: parts.sublist(1).join(' '),
    );
  }

  List<ChurchPosition> get visiblePositions =>
      positions.where((p) => p.title.trim().isNotEmpty || p.location.trim().isNotEmpty).toList();

  double roleScaleForCount(int count) {
    if (count <= 1) return 1;
    if (count == 2) return 0.88;
    if (count == 3) return 0.76;
    if (count == 4) return 0.66;
    return 0.58;
  }
}

enum RolesVerticalAlign { top, center, bottom }
