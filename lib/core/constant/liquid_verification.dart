/// Metode verifikasi yang dipakai project ini.
///
/// Project ini HANYA pakai `COMPLY_HE` (IC Card NFC + Face, tanpa scan
/// dokumen terpisah). Method lain sengaja dihapus:
///
/// - Asumsi komposisi langkah (document / backside photo / offline) buat
///   method lain nggak akurat — bisa bikin flow bolong.
/// - Liquid server yang nentuin flow sebenarnya (lihat CE00030), jadi
///   method yang nggak dikonfigurasi di BE bakal ditolak.
///
/// Kalau someday butuh method lain, tambahin di sini BERSAMA implementasi
/// langkahnya (backside photo, offline, dll) — jangan cuma enum-nya.
enum VerificationMethod {
  /// IC Card (NFC) → Face. Tanpa scan dokumen terpisah.
  complyHe;

  static VerificationMethod get defaultMethod => VerificationMethod.complyHe;

  static VerificationMethod fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return VerificationMethod.complyHe;
    }
    final normalized = value.trim().toUpperCase();
    if (normalized != 'COMPLY_HE') {
      // Method lain sengaja nggak ada di project ini — jangan diam-diam
      // fallback, tapi tetap catat kalau ada yang ngoper string ngawur.
      assert(
        false,
        'VerificationMethod "$value" tidak dikenal — hanya COMPLY_HE yang didukung.',
      );
    }
    return VerificationMethod.complyHe;
  }

  String get value {
    switch (this) {
      case VerificationMethod.complyHe:
        return 'COMPLY_HE';
    }
  }

  String get displayName {
    switch (this) {
      case VerificationMethod.complyHe:
        return 'IC + OCR + Face (He Method)';
    }
  }

  /// COMPLY_HE nggak scan dokumen terpisah (dokumen backside masuk ke
  /// pembacaan chip).
  bool get requiresDocument => false;

  bool get requiresIcCard => true;

  bool get requiresFace => true;

  bool get isComplyHeMethod => true;

  /// COMPLY_HE: IC Card FIRST, lalu Face.
  List<String> get verificationOrder => ['icCard', 'face'];
}


enum FaceVerificationType {
  active,
  passive;

  static FaceVerificationType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PASSIVE':
        return FaceVerificationType.passive;
      case 'ACTIVE':
      default:
        return FaceVerificationType.active;
    }
  }

  String get value {
    switch (this) {
      case FaceVerificationType.active:
        return 'ACTIVE';
      case FaceVerificationType.passive:
        return 'PASSIVE';
    }
  }

  String get displayName {
    switch (this) {
      case FaceVerificationType.active:
        return 'Active Detection (Mouth movement + Flash)';
      case FaceVerificationType.passive:
        return 'Passive Detection (No action required)';
    }
  }
}

enum DisplayLanguage {
  auto,
  japanese,
  english,
  vietnamese,
  indonesian,
  simplifiedChinese,
  portuguese,
  korean,
  nepali,
  burmese,
  centralKhmer,
  mongolian,
  malay,
  thai;

  static DisplayLanguage fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'JAPANESE':
        return DisplayLanguage.japanese;
      case 'ENGLISH':
        return DisplayLanguage.english;
      case 'VIETNAMESE':
        return DisplayLanguage.vietnamese;
      case 'INDONESIAN':
        return DisplayLanguage.indonesian;
      case 'SIMPLIFIED_CHINESE':
        return DisplayLanguage.simplifiedChinese;
      case 'PORTUGUESE':
        return DisplayLanguage.portuguese;
      case 'KOREAN':
        return DisplayLanguage.korean;
      case 'NEPALI':
        return DisplayLanguage.nepali;
      case 'BURMESE':
        return DisplayLanguage.burmese;
      case 'CENTRAL_KHMER':
        return DisplayLanguage.centralKhmer;
      case 'MONGOLIAN':
        return DisplayLanguage.mongolian;
      case 'MALAY':
        return DisplayLanguage.malay;
      case 'THAI':
        return DisplayLanguage.thai;
      default:
        return DisplayLanguage.auto;
    }
  }

  String get value {
    switch (this) {
      case DisplayLanguage.auto:
        return 'AUTO';
      case DisplayLanguage.japanese:
        return 'JAPANESE';
      case DisplayLanguage.english:
        return 'ENGLISH';
      case DisplayLanguage.vietnamese:
        return 'VIETNAMESE';
      case DisplayLanguage.indonesian:
        return 'INDONESIAN';
      case DisplayLanguage.simplifiedChinese:
        return 'SIMPLIFIED_CHINESE';
      case DisplayLanguage.portuguese:
        return 'PORTUGUESE';
      case DisplayLanguage.korean:
        return 'KOREAN';
      case DisplayLanguage.nepali:
        return 'NEPALI';
      case DisplayLanguage.burmese:
        return 'BURMESE';
      case DisplayLanguage.centralKhmer:
        return 'CENTRAL_KHMER';
      case DisplayLanguage.mongolian:
        return 'MONGOLIAN';
      case DisplayLanguage.malay:
        return 'MALAY';
      case DisplayLanguage.thai:
        return 'THAI';
    }
  }

  String get displayName {
    switch (this) {
      case DisplayLanguage.auto:
        return 'Auto (Device setting)';
      case DisplayLanguage.japanese:
        return 'Japanese';
      case DisplayLanguage.english:
        return 'English';
      case DisplayLanguage.vietnamese:
        return 'Vietnamese';
      case DisplayLanguage.indonesian:
        return 'Indonesian';
      case DisplayLanguage.simplifiedChinese:
        return 'Simplified Chinese';
      case DisplayLanguage.portuguese:
        return 'Portuguese';
      case DisplayLanguage.korean:
        return 'Korean';
      case DisplayLanguage.nepali:
        return 'Nepali';
      case DisplayLanguage.burmese:
        return 'Burmese';
      case DisplayLanguage.centralKhmer:
        return 'Khmer';
      case DisplayLanguage.mongolian:
        return 'Mongolian';
      case DisplayLanguage.malay:
        return 'Malay';
      case DisplayLanguage.thai:
        return 'Thai';
    }
  }
}

