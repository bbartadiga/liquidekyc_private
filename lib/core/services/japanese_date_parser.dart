/// Parser tanggal yang dipakai buat mengubah value mentah dari OCR / IC chip
/// jadi [DateTime].
///
/// Format yang sering muncul di data chip & OCR:
///
/// - `20300710` — 8 digit (YYYYMMDD)
/// - `2030年7月10日` — gaya Japan
/// - `2030-07-10` / `2030/07/10` / `2030 / 07 / 10` — hasil join manual
class JapaneseDateParser {
  const JapaneseDateParser._();

  static final RegExp _compact = RegExp(r'^\d{8}$');
  static final RegExp _japanese = RegExp(
    r'(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日',
  );
  static final RegExp _separated = RegExp(
    r'(\d{4})\s*[-/.]\s*(\d{1,2})\s*[-/.]\s*(\d{1,2})',
  );

  /// Ubah [raw] jadi [DateTime], atau null kalau formatnya nggak dikenali.
  static DateTime? parse(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (_compact.hasMatch(value)) {
      return _build(
        int.parse(value.substring(0, 4)),
        int.parse(value.substring(4, 6)),
        int.parse(value.substring(6, 8)),
      );
    }

    final japanese = _japanese.firstMatch(value);
    if (japanese != null) {
      return _build(
        int.parse(japanese.group(1)!),
        int.parse(japanese.group(2)!),
        int.parse(japanese.group(3)!),
      );
    }

    final separated = _separated.firstMatch(value);
    if (separated != null) {
      return _build(
        int.parse(separated.group(1)!),
        int.parse(separated.group(2)!),
        int.parse(separated.group(3)!),
      );
    }

    return null;
  }

  static DateTime? _build(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
}
