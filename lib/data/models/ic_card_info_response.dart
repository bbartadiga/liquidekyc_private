import '../../core/services/japanese_romaji_helper.dart';

class ICCardInfoResponse {
  final bool isSuccess;
  final String? name;
  final String? nameKana;
  final String? birthday;
  final String? sex;
  final String? address;
  final String? addressPref;
  final String? addressCity;
  final String? addressOther;
  final String? idNumber;
  final String? issueDate;
  final String? expireDate;
  final String? myNumber;
  final String? idFacePhoto;
  // Gen-2 / Specified Residence Card fields (D7 page 6-22)
  final String? cardType;                   // 在留カード／特別永住者証明書の種別 0/1/2/5/6/7/8
  final String? residentStatusCode;         // 在留資格 (コード) 3-digit
  final String? kindOfPermissionCode;       // 許可の種類 (コード) 2-digit
  final String? employmentRestrictionCode;  // 就労制限の有無 1-digit
  final String? nationalityCode3;           // 国籍 (3桁) ISO 3166-1 alpha-3
  final String? nationalityCode3Alt;       // 国籍 (3桁) 第二候補
  // Stay period split (Gen-2 specific)
  final int? stayPeriodYear;                // YY 形式
  final int? stayPeriodMonth;               // MM 形式
  final int? stayPeriodDay;                 // DDD 形式 (max 999)
  final int? statusCode;
  final String? errorMessage;

  ICCardInfoResponse({
    required this.isSuccess,
    this.name,
    this.nameKana,
    this.birthday,
    this.sex,
    this.address,
    this.addressPref,
    this.addressCity,
    this.addressOther,
    this.idNumber,
    this.issueDate,
    this.expireDate,
    this.myNumber,
    this.idFacePhoto,
    this.cardType,
    this.residentStatusCode,
    this.kindOfPermissionCode,
    this.employmentRestrictionCode,
    this.nationalityCode3,
    this.nationalityCode3Alt,
    this.stayPeriodYear,
    this.stayPeriodMonth,
    this.stayPeriodDay,
    this.statusCode,
    this.errorMessage,
  });

  String get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : (address ?? '');
  }

  // Getters untuk display - return null kalau kosong (agar placeholder bisa tampil)
  String? get displayName => name;
  String? get displayNameKana => nameKana;
  String? get displayBirthday {
    if (birthday == null || birthday!.isEmpty) return null;
    if (birthday!.length == 8) {
      return '${birthday!.substring(0, 4)}-${birthday!.substring(4, 6)}-${birthday!.substring(6, 8)}';
    }
    return birthday;
  }
  String? get displayExpireDate {
    if (expireDate == null || expireDate!.isEmpty) return null;
    if (expireDate!.length == 8) {
      return '${expireDate!.substring(0, 4)}-${expireDate!.substring(4, 6)}-${expireDate!.substring(6, 8)}';
    }
    return expireDate;
  }
  String? get displayIssueDate {
    if (issueDate == null || issueDate!.isEmpty) return null;
    if (issueDate!.length == 8) {
      return '${issueDate!.substring(0, 4)}-${issueDate!.substring(4, 6)}-${issueDate!.substring(6, 8)}';
    }
    return issueDate;
  }
  String? get displaySex => sex?.toUpperCase();
  String? get displayIdNumber => idNumber;

  factory ICCardInfoResponse.fromMap(Map<String, dynamic> map) {
    String? idFacePhoto;
    final facePhotoData = map['id_face_photo'];
    if (facePhotoData is Map) {
      idFacePhoto = facePhotoData['image'] as String?;
    } else if (facePhotoData is String) {
      idFacePhoto = facePhotoData;
    }

    // Stay period split — accepted as int or string ("3年"/"030" formats)
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      final s = v.toString().replaceAll(RegExp(r'[^0-9-]'), '');
      return s.isEmpty ? null : int.tryParse(s);
    }

    return ICCardInfoResponse(
      isSuccess: true,
      name: map['name'],
      nameKana: map['name_kana'],
      birthday: map['birthday'],
      sex: map['sex'],
      address: map['address'],
      addressPref: map['address_pref'],
      addressCity: map['address_city'],
      addressOther: map['address_other'],
      idNumber: map['id_number'],
      issueDate: map['issue_date'],
      expireDate: map['expire_date'],
      myNumber: map['my_number'],
      idFacePhoto: idFacePhoto,
      // Gen-2 fields
      cardType: map['card_type']?.toString() ??
                map['residence_card_type']?.toString(),
      residentStatusCode: map['resident_status_code']?.toString(),
      kindOfPermissionCode: map['kind_of_permission_code']?.toString(),
      employmentRestrictionCode:
          map['employment_restriction_code']?.toString(),
      nationalityCode3: map['nationality_code3']?.toString() ??
                        map['nationality_3digit']?.toString(),
      nationalityCode3Alt: map['nationality_code3_alt']?.toString() ??
                            map['nationality_3digit_alt']?.toString(),
      stayPeriodYear: toInt(map['stay_period_year']),
      stayPeriodMonth: toInt(map['stay_period_month']),
      stayPeriodDay: toInt(map['stay_period_day']),
      statusCode: map['status_code'],
    );
  }

  factory ICCardInfoResponse.error({
    required int statusCode,
    required String message,
  }) => ICCardInfoResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

// ============================================================================
// Extension on ICCardInfoResponse — Romaji (latin) versions
// name_kana (katakana) instant via kana_kit; name (kanji) needs async
// ============================================================================
extension ICCardInfoResponseMapping on ICCardInfoResponse {
  String? get nameRomaji => JapaneseRomajiHelper.toTitleCaseRomajiSync(nameKana);
  Future<String?> get nameRomajiAsync =>
      JapaneseRomajiHelper.toTitleCaseRomajiAsync(nameKana);
  String? get nameKanjiRomaji => JapaneseRomajiHelper.toTitleCaseRomajiSync(name);
  Future<String?> get nameKanjiRomajiAsync =>
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
}
