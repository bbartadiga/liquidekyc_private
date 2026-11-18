import '../../core/services/app_logger.dart';
import '../../core/services/japanese_romaji_helper.dart';

class OcrResult {
  final String? name;
  final String? birthday;
  final String? sex;
  final String? address;
  final String? addressPref;
  final String? addressCity;
  final String? addressOther;
  final String? zipCode;
  final String? expireDate;
  final String? idNumber;
  final String? issueDate;
  final String? nationality;
  final String? residentStatus;
  final String? stayPeriod;
  final String? stayExpireDate;
  final String? issuingAuthority;
  final String? addressChanged;
  final String? nameChanged;
  final String? remarksExist;
  final String? employmentRestriction;
  final String? permittedDate;
  final String? kindOfPermission;
  final List<String>? driversLicenseTypes;
  // Gen-2 / Specified Residence Card fields (SDK)
  final String? cardType;
  final String? residentStatusCode;
  final String? kindOfPermissionCode;
  final String? employmentRestrictionCode;
  final String? nationalityCode3;

  OcrResult({
    this.name,
    this.birthday,
    this.sex,
    this.address,
    this.addressPref,
    this.addressCity,
    this.addressOther,
    this.zipCode,
    this.expireDate,
    this.idNumber,
    this.issueDate,
    this.nationality,
    this.residentStatus,
    this.stayPeriod,
    this.stayExpireDate,
    this.issuingAuthority,
    this.addressChanged,
    this.nameChanged,
    this.remarksExist,
    this.employmentRestriction,
    this.permittedDate,
    this.kindOfPermission,
    this.driversLicenseTypes,
    this.cardType,
    this.residentStatusCode,
    this.kindOfPermissionCode,
    this.employmentRestrictionCode,
    this.nationalityCode3,
  });

  factory OcrResult.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      appLogger.w('[OCR-Parse-SDK] empty/null map');
      return OcrResult();
    }

    final result = OcrResult(
      name: map['name'] as String?,
      birthday: (map['birthday'] ?? map['dateOfBirth']) as String?,
      sex: map['sex'] as String?,
      address: map['address'] as String?,
      addressPref: map['addressPref'] as String?,
      addressCity: map['addressCity'] as String?,
      addressOther: map['addressOther'] as String?,
      zipCode: map['zipCode'] as String?,
      expireDate: (map['expireDate'] ?? map['expiryDate']) as String?,
      idNumber: (map['idNumber'] ?? map['documentNumber']) as String?,
      issueDate: map['issueDate'] as String?,
      nationality: map['nationality'] as String?,
      residentStatus: (map['residentStatus'] ?? map['residenceStatus']) as String?,
      stayPeriod: (map['stayPeriod'] ?? map['periodOfStay']) as String?,
      stayExpireDate: map['stayExpireDate'] as String?,
      issuingAuthority: map['issuingAuthority'] as String?,
      addressChanged: map['addressChanged'] as String?,
      nameChanged: map['nameChanged'] as String?,
      remarksExist: map['remarksExist'] as String?,
      employmentRestriction: map['employmentRestriction'] as String?,
      permittedDate: map['permittedDate'] as String?,
      kindOfPermission: map['kindOfPermission'] as String?,
      driversLicenseTypes: (map['driversLicenseTypes'] as List<dynamic>?)?.cast<String>(),
      // Gen-2 fields
      cardType: map['card_type']?.toString(),
      residentStatusCode: map['resident_status_code']?.toString(),
      kindOfPermissionCode: map['kind_of_permission_code']?.toString(),
      employmentRestrictionCode:
          map['employment_restriction_code']?.toString(),
      nationalityCode3: map['nationality_code3']?.toString(),
    );

    appLogger.i(
      '[OCR-Parse-SDK] '
      'card_type=${result.cardType ?? "-"} | '
      'name=${result.name ?? "-"} | '
      'birthday=${result.birthday ?? "-"} | '
      'sex=${result.sex ?? "-"} | '
      'nationality_2=${result.nationality ?? "-"} | '
      'nationality_3=${result.nationalityCode3 ?? "-"} | '
      'id_number=${result.idNumber ?? "-"} | '
      'resident_status=${result.residentStatus ?? "-"} | '
      'resident_status_code=${result.residentStatusCode ?? "-"} | '
      'kind_of_permission=${result.kindOfPermissionCode ?? "-"} | '
      'employment_restriction=${result.employmentRestrictionCode ?? "-"} | '
      'stay_period=${result.stayPeriod ?? "-"} | '
      'expire_date=${result.expireDate ?? "-"} | '
      'address=${result.address != null ? "***MASKED***" : "-"}',
    );

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthday': birthday,
      'sex': sex,
      'address': address,
      'addressPref': addressPref,
      'addressCity': addressCity,
      'addressOther': addressOther,
      'zipCode': zipCode,
      'expireDate': expireDate,
      'idNumber': idNumber,
      'issueDate': issueDate,
      'nationality': nationality,
      'residentStatus': residentStatus,
      'stayPeriod': stayPeriod,
      'stayExpireDate': stayExpireDate,
      'issuingAuthority': issuingAuthority,
      'addressChanged': addressChanged,
      'nameChanged': nameChanged,
      'remarksExist': remarksExist,
      'employmentRestriction': employmentRestriction,
      'permittedDate': permittedDate,
      'kindOfPermission': kindOfPermission,
      'driversLicenseTypes': driversLicenseTypes,
    };
  }

  String get dateOfBirth => birthday ?? '';

  /// Alamat lengkap gabungan pref + city + other + address.
  ///
  /// Dipakai sebagai sumber data applicant ke BE kalau flow-nya nggak
  /// baca chip (method FRONT / COMPLY_TO).
  String? get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
  String get expiryDate => expireDate ?? '';
  String get documentNumber => idNumber ?? '';
  String get residenceStatus => residentStatus ?? '';
  String get periodOfStay => stayPeriod ?? '';
}

// ============================================================================
// Extension on OcrResult (SDK model) — Romaji (latin) versions
// ============================================================================
extension OcrResultMapping on OcrResult {
  String? get nameRomaji => JapaneseRomajiHelper.toTitleCaseRomajiSync(name);
  Future<String?> get nameRomajiAsync =>
      JapaneseRomajiHelper.toTitleCaseRomajiAsync(name);
  String? get addressRomaji => JapaneseRomajiHelper.toRomajiSync(address);
  Future<String?> get addressRomajiAsync =>
      JapaneseRomajiHelper.toRomajiAsync(address);
  String? get addressPrefRomaji => JapaneseRomajiHelper.toRomajiSync(addressPref);
  Future<String?> get addressPrefRomajiAsync =>
      JapaneseRomajiHelper.toRomajiAsync(addressPref);
  String? get addressCityRomaji => JapaneseRomajiHelper.toRomajiSync(addressCity);
  Future<String?> get addressCityRomajiAsync =>
      JapaneseRomajiHelper.toRomajiAsync(addressCity);
  String? get addressOtherRomaji => JapaneseRomajiHelper.toRomajiSync(addressOther);
  Future<String?> get addressOtherRomajiAsync =>
      JapaneseRomajiHelper.toRomajiAsync(addressOther);
  String? get nationalityRomaji => JapaneseRomajiHelper.toRomajiSync(nationality);
  Future<String?> get nationalityRomajiAsync =>
      JapaneseRomajiHelper.toRomajiAsync(nationality);
  String? get residentStatusRomaji =>
      JapaneseRomajiHelper.toTitleCaseRomajiSync(residentStatus);
  Future<String?> get residentStatusRomajiAsync =>
      JapaneseRomajiHelper.toTitleCaseRomajiAsync(residentStatus);
}
