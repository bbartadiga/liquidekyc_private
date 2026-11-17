import '../../core/services/app_logger.dart';
import '../../core/services/japanese_romaji_helper.dart';
import '../../data/services/kyc_be_api.dart';

// ============================================================================
// Document Type ID Codes
// Refs:
//   - D5 (G05 APIGenericCode_v1.4.3) page 15-26
//   - D6 (folder 17) — Gen-2 Residence Card correspondence matrix
//   - D1/D2 (022 GetICCardInfo) — 022 API response code list
// ============================================================================
const Map<String, String> liquidIdDocumentTypeNames = {
  // ---- Comply to He (IC + OCR + Face), COMPLY_HE method ----
  '11': "Driver's Licence (IC)",
  '12': 'National Identity Card (My Number, IC)',
  '13': 'Residence Card (IC)',
  '15': 'Special Permanent Resident Certificate (IC)',

  // ---- MyNumber variants (Gen-2 era, since 2026/1) ----
  '01023': 'My Number Card (+My Number)',
  '01035': 'My Number Card (+License Information)',
  '01040': 'My Number Card (+JPKI Public Cert)',

  // ---- Gen-2 Residence Card (D5 page 17, D7 page 1) ----
  '01036': 'Gen-2 Residence Card',
  '01037': 'Gen-2 Special Permanent Resident Certificate',
  '01038': 'Specified Residence Card',
  '01039': 'Specified Special Permanent Resident Certificate',

  // ---- Legacy OCR codes (preserved for backward compat) ----
  '01': "Driver's Licence",
  '02': 'Individual Number Card (My Number)',
  '03': 'Residence Card',
  '04': 'Driving History Certificate',

  // ---- JPKI / Public Cert ----
  '42': 'JPKI Public Certification',
};

// ============================================================================
// Nationality — ISO 3166-1 alpha-2 (2-digit)
// Refs: D5 page 11 (対象地域コード)
// ============================================================================
const Map<String, String> liquidNationalityNames = {
  // Project scope (priority mapping)
  'ID': 'Indonesia',
  'JP': 'Jepang',
  // Common WNA in Japan residency use cases
  'PH': 'Filipina',
  'BR': 'Brasil',
  'CN': 'Tiongkok',
  'KR': 'Korea Selatan',
  'VN': 'Vietnam',
  'TH': 'Thailand',
  'MM': 'Myanmar',
  'KH': 'Kamboja',
  'LA': 'Laos',
  'MY': 'Malaysia',
  'SG': 'Singapura',
  'NP': 'Nepal',
  'IN': 'India',
  'BD': 'Bangladesh',
  'PK': 'Pakistan',
  'LK': 'Sri Lanka',
  'US': 'Amerika Serikat',
  'CA': 'Kanada',
  'GB': 'Inggris',
  'AU': 'Australia',
  'NZ': 'Selandia Baru',
  'DE': 'Jerman',
  'FR': 'Prancis',
  'NL': 'Belanda',
  'RU': 'Rusia',
  'TW': 'Taiwan',
  'HK': 'Hong Kong',
  'MO': 'Makau',
};

// ============================================================================
// Nationality — ISO 3166-1 alpha-3 (3-digit) for Gen-2 cards
// Refs: D5 page 14, 41 — 国籍コード表, page 41 国籍 (3桁)
// Light version: Indonesia & Jepang primary (project scope)
// ============================================================================
const Map<String, String> liquidNationalityNames3 = {
  'IDN': 'Indonesia',
  'JPN': 'Jepang',
  // Common neighbors untuk поддержка OCR fallback
  'PHL': 'Filipina',
  'CHN': 'Tiongkok',
  'KOR': 'Korea Selatan',
  'VNM': 'Vietnam',
  'THA': 'Thailand',
  'MMR': 'Myanmar',
  'KHM': 'Kamboja',
  'LAO': 'Laos',
  'MYS': 'Malaysia',
  'SGP': 'Singapura',
  'IND': 'India',
  'NPL': 'Nepal',
  'BGD': 'Bangladesh',
  'USA': 'Amerika Serikat',
  'CAN': 'Kanada',
  'GBR': 'Inggris',
  'AUS': 'Australia',
  'BRA': 'Brasil',
};

// ============================================================================
// Residence Card Card Type Code (在留カード／特別永住者証明書の種別)
// Refs: D7 page 6 (card type enum values)
// ============================================================================
const Map<String, String> liquidResidenceCardTypeNames = {
  '0': 'Not Detected',
  '1': 'Residence Card (現行)',
  '2': 'Special Permanent Resident Certificate (現行)',
  '5': 'Gen-2 Residence Card',            // 第2世代在留カード
  '6': 'Gen-2 Special Permanent Resident', // 第2世代特別永住者証明書
  '7': 'Specified Residence Card',        // 特定在留カード
  '8': 'Specified Special Permanent Resident', // 特定特別永住者証明書
};

// ============================================================================
// Employment Restriction Code (就労制限の有無)
// Refs: D5 page 13-14
// ============================================================================
const Map<String, String> liquidEmploymentRestrictionNames = {
  '1': 'No work restrictions',
  '2': 'Work activities based on status of residence only',
  '4': 'Work activities specified by designation only',
  '9': 'Not permitted to work',
};

// ============================================================================
// Helpers
// ============================================================================
String? resolveDocumentTypeName(String? code) {
  if (code == null || code.isEmpty) return null;
  final name = liquidIdDocumentTypeNames[code];
  if (name == null) {
    appLogger.w('[OCR-Mapping] Unknown id_document_type code: "$code" — add to liquidIdDocumentTypeNames');
    return 'Unknown ($code)';
  }
  return name;
}

String? resolveNationalityName(String? code) {
  if (code == null || code.isEmpty) return null;
  final upper = code.toUpperCase();
  final name = liquidNationalityNames[upper];
  if (name == null) {
    appLogger.w('[OCR-Mapping] Unknown nationality (2-digit) code: "$code" — add to liquidNationalityNames');
    return code;
  }
  return name;
}

String? resolveNationalityName3(String? code) {
  if (code == null || code.isEmpty) return null;
  final upper = code.toUpperCase();
  final name = liquidNationalityNames3[upper];
  if (name == null) {
    appLogger.w('[OCR-Mapping] Unknown nationality (3-digit) code: "$code" — add to liquidNationalityNames3');
    return code;
  }
  return name;
}

String? resolveResidenceCardTypeName(String? code) {
  if (code == null || code.isEmpty) return null;
  final name = liquidResidenceCardTypeNames[code];
  if (name == null) {
    appLogger.w('[OCR-Mapping] Unknown residence card type code: "$code" — add to liquidResidenceCardTypeNames');
    return 'Unknown ($code)';
  }
  return name;
}

String? resolveEmploymentRestrictionName(String? code) {
  if (code == null || code.isEmpty) return null;
  return liquidEmploymentRestrictionNames[code] ?? 'Unknown ($code)';
}

// ============================================================================
// Extension on OcrResultsBeResponse — add Gen-2 friendly getters
// ============================================================================
extension OcrResultsBeResponseMapping on OcrResultsBeResponse {
  String? get documentTypeName => resolveDocumentTypeName(idDocumentType);

  String? get documentTypeDisplay {
    if (idDocumentType == null) return null;
    final name = documentTypeName;
    return name == null ? null : '$name ($idDocumentType)';
  }

  String? get nationalityName => resolveNationalityName(nationality);

  String? get nationalityDisplay {
    if (nationality == null) return null;
    final name = nationalityName;
    return name == null ? null : '$name (${nationality!.toUpperCase()})';
  }

  String? get nationalityCode3Name =>
      resolveNationalityName3(nationalityCode3);

  String? get cardTypeName => resolveResidenceCardTypeName(cardType);

  // --------------------------------------------------------------------------
  // Romaji (latin) versions.
  // Sync: handles katakana/hiragana instant via kana_kit (cache-aware).
  // Async (suffix Async): full kanji support via jp_transliterate platform
  //                       channel (~50-100ms first call, instant after cache).
  // --------------------------------------------------------------------------
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
  String? get residentStatusRomaji =>
      JapaneseRomajiHelper.toTitleCaseRomajiSync(residentStatus);
  Future<String?> get residentStatusRomajiAsync =>
      JapaneseRomajiHelper.toTitleCaseRomajiAsync(residentStatus);
  String? get stayPeriodRomaji => JapaneseRomajiHelper.toRomajiSync(stayPeriod);
}
