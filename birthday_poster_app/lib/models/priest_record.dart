class PriestRecord {
  PriestRecord({
    required this.fullName,
    this.designation = '',
    this.servingAt = '',
    this.address = '',
    this.birthDate,
    this.ordinationDate,
  });

  final String fullName;
  final String designation;
  final String servingAt;
  final String address;
  final DateTime? birthDate;
  final DateTime? ordinationDate;

  String get key => normalizePriestKey(fullName);

  static String normalizePriestKey(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .where((part) => !_credentialTokens.contains(part))
        .join('-');
  }

  static const _credentialTokens = {
    'rev',
    'fr',
    'dr',
    'ddr',
    'msgr',
    'very',
    'b',
    'th',
    'm',
    'a',
    'ph',
    'stl',
    'std',
    'scl',
    'isc',
    'dcl',
    'dd',
    'bd',
    'mba',
    'mth',
    'mph',
    'mphil',
    'ma',
    'ba',
    'bcom',
    'bsc',
    'soc',
    'com',
    'mcj',
    'mhrm',
    'lss',
    'pg',
    'gha',
    'dh',
    'hm',
    'llb',
  };

  PriestRecord merge(PriestRecord other) {
    return PriestRecord(
      fullName: fullName.isNotEmpty ? fullName : other.fullName,
      designation: designation.isNotEmpty ? designation : other.designation,
      servingAt: servingAt.isNotEmpty ? servingAt : other.servingAt,
      address: address.isNotEmpty ? address : other.address,
      birthDate: birthDate ?? other.birthDate,
      ordinationDate: ordinationDate ?? other.ordinationDate,
    );
  }

  PriestRecord copyWith({
    String? fullName,
    String? designation,
    String? servingAt,
    String? address,
    DateTime? birthDate,
    DateTime? ordinationDate,
  }) {
    return PriestRecord(
      fullName: fullName ?? this.fullName,
      designation: designation ?? this.designation,
      servingAt: servingAt ?? this.servingAt,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      ordinationDate: ordinationDate ?? this.ordinationDate,
    );
  }
}
