import '../../core/constant/liquid_constants.dart';
import '../../data/models/chip_data.dart';
import '../../data/models/ocr_result.dart';

/// Payload RegisterApplicationInfo (016) — sesuai spec
/// `LIQUID_eKYC_016_申請情報登録API_v1.3.4`.
///
/// Required (○): `applicant_id`, `first_name`, `birthday`, `address1`.
/// Sisanya opsional tapi disarankan diisi kalau datanya ada.
///
/// Batasan format dari spec:
/// - `birthday` → `yyyyMMdd`, reject kalau < 1900-01-01
/// - `nationality` → 2 char (ISO 3166-1 alpha-2)
/// - `sex` → 1 char
/// - `zip_code` → 2-9 digit
/// - `phone_number` → 10 atau 11 digit, tanpa strip
/// - `address1` = pref, `address2` = city, `address3` = town, `address4` = sisanya
class ApplicantInfoPayload {
  final String applicantId;
  final String firstName;
  final String? lastName;
  final String? middleName;
  final String? firstNameKana;
  final String? lastNameKana;
  final String? middleNameKana;

  /// `yyyyMMdd`
  final String birthday;

  /// 2 char, ISO 3166-1 alpha-2 (JP / ID / ...)
  final String? nationality;

  /// 1 char: 1 = male, 2 = female, 3 = others
  final String? sex;

  final String? zipCode;

  /// Digit saja (10 atau 11), tanpa strip
  final String? phoneNumber;

  final String address1;
  final String? address2;
  final String? address3;
  final String? address4;

  /// 本人確認書類番号 (dipakai untuk auto-judgment option)
  final String? idNumber;

  const ApplicantInfoPayload({
    required this.applicantId,
    required this.firstName,
    required this.birthday,
    required this.address1,
    this.lastName,
    this.middleName,
    this.firstNameKana,
    this.lastNameKana,
    this.middleNameKana,
    this.nationality,
    this.sex,
    this.zipCode,
    this.phoneNumber,
    this.address2,
    this.address3,
    this.address4,
    this.idNumber,
  });

  /// Body request — field null/kosong dibuang (semua opsional di spec).
  Map<String, dynamic> toBody() {
    return {
      'applicant_id': applicantId,
      'last_name': ?lastName,
      'first_name': firstName,
      'middle_name': ?middleName,
      'last_name_kana': ?lastNameKana,
      'first_name_kana': ?firstNameKana,
      'middle_name_kana': ?middleNameKana,
      'birthday': birthday,
      'nationality': ?nationality,
      'sex': ?sex,
      'zip_code': ?zipCode,
      'phone_number': ?phoneNumber,
      'address1': address1,
      'address2': ?address2,
      'address3': ?address3,
      'address4': ?address4,
      'id_number': ?idNumber,
    };
  }

  /// Susun payload dari data chip (prioritas utama) + OCR (fallback).
  ///
  /// Chip lebih otoritatif (signed JPKI) → dipakai duluan; OCR dipakai
  /// untuk field yang nggak ada di chip (mis. nationality untuk My Number).
  factory ApplicantInfoPayload.fromKycData({
    required String applicantId,
    required LiquidChipDataModel? chipData,
    required OcrResult? ocrResult,
    required Nationality selectedNationality,
    String? phoneNumber,
  }) {
    final chipName = _splitName(chipData?.name);
    final kanaName = _splitName(chipData?.nameKana);
    final ocrName = _splitName(ocrResult?.name);

    // Nama: chip dulu (signed JPKI), fallback OCR.
    final lastName = chipName.last ?? ocrName.last;
    final firstName = chipName.first ?? ocrName.first ?? 'User';

    // Kana: My Number Card cuma nyimpen nama kana, jadi nameKana bisa null
    // sementara `name` isinya kana. Kalau nameKana ada → pakai itu.
    final lastNameKana = kanaName.last ?? chipName.last;
    final firstNameKana = kanaName.first ?? chipName.first;

    final birthday = _normalizeBirthday(chipData?.birthday ?? ocrResult?.birthday);
    final address = _splitAddress(chipData, ocrResult);
    final nationality = _resolveNationality(
      ocrResult?.nationality,
      selectedNationality,
    );
    final sex = _resolveSex(chipData?.sex?.name, ocrResult?.sex);

    return ApplicantInfoPayload(
      applicantId: applicantId,
      firstName: firstName,
      lastName: lastName,
      firstNameKana: firstNameKana,
      lastNameKana: lastNameKana,
      birthday: birthday,
      nationality: nationality,
      sex: sex,
      zipCode: _normalizeZipCode(chipData?.zipCode ?? ocrResult?.zipCode),
      phoneNumber: _normalizePhoneNumber(phoneNumber),
      address1: address.address1,
      address2: address.address2,
      address3: address.address3,
      address4: address.address4,
      idNumber: chipData?.idNumber ?? ocrResult?.idNumber,
    );
  }

  /// Pisah nama jadi (lastName, firstName) — aksara Jepang: marga di depan.
  ///
  /// Nama My Number Card_full-width dengan spasi full-width (U+3000):
  /// `ＤＨＩＫＡ　ＰＲＡＴＡＭＡ` → last=ＤＨＩＫＡ, first=ＰＲＡＴＡＭＡ
  static ({String? last, String? first}) _splitName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return (last: null, first: null);
    final tokens = raw
        .split(RegExp(r'[\s　]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return (last: null, first: null);
    if (tokens.length == 1) return (last: null, first: tokens.first);
    return (last: tokens.first, first: tokens.sublist(1).join(' '));
  }

  /// `yyyyMMdd`. Spec reject tanggal sebelum 1900-01-01.
  static String _normalizeBirthday(String? raw) {
    if (raw == null || raw.isEmpty) return '19000101';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return '19000101';
    final year = int.parse(digits.substring(0, 4));
    if (year < 1900) return '19000101';
    return digits;
  }

  /// Address1..4 sesuai spec: pref / city / town / sisanya.
  static ({
    String address1,
    String? address2,
    String? address3,
    String? address4,
  }) _splitAddress(LiquidChipDataModel? chipData, OcrResult? ocrResult) {
    final pref = _nonEmpty(chipData?.addressPref ?? ocrResult?.addressPref);
    final city = _nonEmpty(chipData?.addressCity ?? ocrResult?.addressCity);
    final other = _nonEmpty(chipData?.addressOther ?? ocrResult?.addressOther);
    final rest = _nonEmpty(chipData?.address ?? ocrResult?.address);

    if (pref != null) {
      return (
        address1: pref,
        address2: city,
        address3: other ?? rest,
        address4: null,
      );
    }

    // Tidak dipisah → seluruhnya masuk address1 (lihat ※1 di spec).
    return (
      address1: rest ?? 'Unknown',
      address2: null,
      address3: null,
      address4: null,
    );
  }

  static String? _resolveNationality(String? ocrCode, Nationality selected) {
    final code = _nonEmpty(ocrCode);
    if (code != null && code.length == 2) return code.toUpperCase();
    return switch (selected) {
      Nationality.japan => 'JP',
      Nationality.indonesia => 'ID',
    };
  }

  /// Sex: 1 = male, 2 = female, 3 = others.
  static String? _resolveSex(String? chipSex, String? ocrSex) {
    final ocr = _nonEmpty(ocrSex);
    if (ocr != null && ocr.length == 1 && int.tryParse(ocr) != null) {
      return ocr;
    }
    return switch (chipSex?.toUpperCase()) {
      'MALE' => '1',
      'FEMALE' => '2',
      'OTHERS' => '3',
      _ => null,
    };
  }

  static String? _normalizeZipCode(String? raw) {
    final code = _nonEmpty(raw);
    if (code == null) return null;
    final digits = code.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    if (digits.length < 2 || digits.length > 9) return null;
    return digits;
  }

  static String? _normalizePhoneNumber(String? raw) {
    final value = _nonEmpty(raw);
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10 && digits.length != 11) return null;
    return digits;
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
