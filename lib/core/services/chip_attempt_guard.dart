import 'package:shared_preferences/shared_preferences.dart';

/// Pengaman percobaan baca chip.
///
/// Kenapa perlu: pada My Number Card, **counter percobaan-nya ada di IC chip
/// kartunya**, bukan di server. Setiap credential yang nggak cocok (tanggal
/// lahir / tanggal berlaku / kode keamanan) memotong sisa percobaan kartu.
/// Habis habis → kartu terkunci dan harus dibuka di kantor kecamatan.
///
/// Staging tidak melindungi kartu sama sekali: pembacaan chip + validasi
/// JPKI terjadi on-device, jadi efeknya ke kartu fisik identik dengan
/// production.
///
/// Karena itu counter disimpan di perangkat (SharedPreferences) supaya:
/// - nggak bisa di-reset dengan restart app
/// - app bisa berhenti sebelum channel Continuer dan menguras sisa percobaan
class ChipAttemptGuard {
  static const String _failedKey = 'chip_read_failed_attempts';
  static const String _lastCodeKey = 'chip_read_last_error_code';

  /// Batas percobaan gagal sebelum app berhentitotal dan menyuruh user berhenti.
  ///
  /// 3 dipilih karena batas terkunci kartu di sisi SDK juga kecil
  /// (3× gagal PIN 4-digit sudah mengunci isi kartu).
  static const int maxAttempts = 3;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefsInstance {
    if (_prefs == null) {
      throw Exception('ChipAttemptGuard not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Jumlah percobaan gagal yang tercatat di perangkat ini.
  static int get failedAttempts => _prefs?.getInt(_failedKey) ?? 0;

  /// Error code terakhir yang memblokir percobaan (untuk pesan).
  static String? get lastErrorCode => _prefs?.getString(_lastCodeKey);

  /// Sisa percobaan sebelum app berhenti total.
  static int get attemptsLeft => (maxAttempts - failedAttempts).clamp(0, maxAttempts);

  /// true kalau masih boleh mencoba baca chip.
  static bool get canAttempt => failedAttempts < maxAttempts;

  /// Catat satu percobaan yang benar-benar memotong sisa percobaan kartu.
  ///
  /// Hanya dipanggil untuk error yang bisa mengunci kartu — cancel user,
  /// error jaringan, atau timeout nggak memotong apa pun.
  static Future<void> recordFailure(String errorCode) async {
    await init();
    await _prefsInstance.setInt(_failedKey, failedAttempts + 1);
    await _prefsInstance.setString(_lastCodeKey, errorCode);
  }

  /// Reset setelah baca chip berhasil.
  static Future<void> reset() async {
    await init();
    await _prefsInstance.remove(_failedKey);
    await _prefsInstance.remove(_lastCodeKey);
  }

  /// Pesan kalau percobaan sudah habis.
  static String get blockedMessage {
    return 'Percobaan baca kartu sudah $failedAttempts kali gagal. '
        'Kartu My Number Card punya batas percobaan dan bisa terkunci, '
        'yang harus dibuka di kantor kecamatan.\n\n'
        'Demi keamanan kartu, proses dihentikan. '
        'Pastikan data pada kartu (tanggal lahir, tanggal berlaku, kode keamanan) '
        'benar sebelum mencoba lagi.';
  }
}
