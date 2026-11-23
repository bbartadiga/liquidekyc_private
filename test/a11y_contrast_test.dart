import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/app_colors.dart';

/// Guard kontras warna (WCAG 2.2 AA).
///
/// Teks normal butuh 4.5:1, komponen UI (ikon, border fokus) butuh 3:1.
/// Warna yang gagal biasanya kelihatan "bagus" di mockup tapi nggak kebaca
/// di layar HP atau mata tired.
void main() {
  group('Kontras warna (WCAG AA)', () {
    test('teks form di atas surface', () {
      expect(_contrast(AppColors.textPrimary, AppColors.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.textHint, AppColors.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.error, AppColors.surface),
          greaterThanOrEqualTo(4.5));
    });

    test('badge sumber data di atas background', () {
      expect(_contrast(AppColors.textSecondary, AppColors.background),
          greaterThanOrEqualTo(4.5));
    });

    test('komponen UI (ikon kalender, border fokus)', () {
      expect(_contrast(AppColors.accent, AppColors.surface),
          greaterThanOrEqualTo(3));
      expect(_contrast(AppColors.primary, AppColors.surface),
          greaterThanOrEqualTo(3));
    });

    test('tombol utama: teks putih di atas hijau', () {
      expect(_contrast(AppColors.onPrimary, AppColors.success),
          greaterThanOrEqualTo(4.5));
    });
  });
}

/// Rasio kontras WCAG antara dua warna.
double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}
