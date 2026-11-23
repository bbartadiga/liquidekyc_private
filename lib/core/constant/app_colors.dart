import 'package:flutter/material.dart';

/// Palet warna untuk flow registrasi akun (Account Registrations).
///
/// Mengikuti mockup "Account Registrations": aksen utama oranye, langkah
/// yang belum reached abu-abu, dan kalender oranye terang.
class AppColors {
  const AppColors._();

  /// Aksen utama: garis & lingkaran stepper, tombol utama.
  static const Color primary = Color(0xFFF15A23);

  /// Versi gelap aksen utama, dipakai untuk pressed state.
  static const Color primaryDark = Color(0xFFD4420D);

  /// Warna teks di atas permukaan aksen utama.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Lingkaran step yang belum/step berikutnya.
  static const Color stepInactive = Color(0xFFD9D9D9);

  /// Label step yang belum reached.
  static const Color stepInactiveText = Color(0xFFDADADA);

  /// Ikon kalender di field tanggal.
  static const Color accent = Color(0xFFFF4D00);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF707070);
  /// Placeholder / hint text.ajib ≥4.5:1 di atas surface (WCAG AA).
  static const Color textHint = Color(0xFF757575);

  static const Color border = Color(0xFFBFC3CC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  /// Pesan error — kontras ≥4.5:1 di atas surface (WCAG AA).
  static const Color error = Color(0xFFC62828);

  /// Hijau tombol utama. White text di atasnya 5.1:1 (WCAG AA) —
  /// `Colors.green` (#4CAF50) cuma 2.8:1, jadi nggak dipake.
  static const Color success = Color(0xFF2E7D32);
}
