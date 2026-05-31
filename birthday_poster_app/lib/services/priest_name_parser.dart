class ParsedPriestName {
  const ParsedPriestName({
    required this.designation,
    required this.givenName,
    required this.familyName,
  });

  final String designation;
  final String givenName;
  final String familyName;
}

class PriestNameParser {
  static final _prefixPattern = RegExp(
    r'^(?:(?:VERY\s+)?REV\.?\s+|REV\.?\s+|FR\.?\s+|DR\.?\s+|DDR\.?\s+|MSGR\.?\s+)+',
    caseSensitive: false,
  );

  static final _credentialPattern = RegExp(
    r'\b(?:B\.?\s*TH\.?|M\.?\s*A\.?|B\.?\s*PH\.?|B\.?\s*A\.?|B\.?\s*COM\.?|'
    r'B\.?\s*SC\.?|M\.?\s*TH\.?|S\.?\s*T\.?\s*D\.?|S\.?\s*T\.?\s*L\.?|'
    r'M\.?\s*PH\.?|M\.?\s*BA\.?|M\.?\s*HRM\.?|M\.?\s*C\.?\s*L\.?|D\.?\s*D\.?|'
    r'D\.?\s*C\.?\s*L\.?|M\.?\s*PHIL\.?|P\.?\s*G\.?\s*H\.?\s*A\.?|L\.?\s*S\.?\s*S\.?|'
    r'I\.?\s*S\.?\s*C\.?\s*L\.?|B\.?\s*D\.?|MBA|MCL)\.?\s*,?\s*',
    caseSensitive: false,
  );

  static ParsedPriestName parse(String fullName) {
    var working = fullName.trim();
    if (working.isEmpty) {
      return const ParsedPriestName(
        designation: '',
        givenName: '',
        familyName: '',
      );
    }

    final designation = _extractDesignation(working);
    working = working.replaceFirst(_prefixPattern, '').trim();
    working = working.replaceAll(_credentialPattern, ' ').trim();
    working = working.replaceAll(RegExp(r'\s+'), ' ');

    if (working.isEmpty) {
      return ParsedPriestName(
        designation: designation,
        givenName: fullName.toUpperCase(),
        familyName: '',
      );
    }

    final parts = working.split(' ');
    if (parts.length == 1) {
      return ParsedPriestName(
        designation: designation,
        givenName: parts.first.toUpperCase(),
        familyName: '',
      );
    }

    final familyName = _titleCase(parts.last);
    final givenName = parts.sublist(0, parts.length - 1).join(' ').toUpperCase();

    return ParsedPriestName(
      designation: designation,
      givenName: givenName,
      familyName: familyName,
    );
  }

  static String _extractDesignation(String fullName) {
    final match = _prefixPattern.firstMatch(fullName);
    if (match == null) return 'Rev. Fr.';

    final raw = match.group(0)!.toUpperCase();
    if (raw.contains('VERY') && raw.contains('MSGR')) return 'Very Rev. Msgr.';
    if (raw.contains('VERY')) return 'Very Rev. Fr.';
    if (raw.contains('MSGR')) return 'Rev. Msgr.';
    if (raw.contains('DDR') || raw.contains('DR')) return 'Rev. Dr.';
    return 'Rev. Fr.';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
