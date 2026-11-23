import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

/// Ukuran & spasi baku untuk flow registrasi akun.
class AppDimens {
  const AppDimens._();

  /// Margin kiri/kanan konten layar.
  static const double gutter = 24;

  /// Radius corners input field & dropdown.
  static const double fieldRadius = 8;

  /// Jarak label ke field.
  static const double labelGap = 8;

  /// Jarak antar field.
  static const double fieldGap = 20;

  /// Diameter lingkaran stepper.
  static const double stepCircle = 20;

  /// Tinggi area stepper (lingkaran + judul 2 baris).
  static const double stepperHeight = 62;

  /// Lebar ikon kalender.
  static const double calendarIcon = 26;

  /// Lebar ikon back di app bar.
  static const double backIcon = 26;
}

/// Dekorasi input (text field, dropdown, triplet tanggal) yang konsisten.
class AppTheme {
  const AppTheme._();

  static const double _fieldTextSize = 14;
  static const double _labelTextSize = 13;

  /// Border input normal.
  static OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
        borderSide: const BorderSide(color: AppColors.border),
      );

  /// Border input fokus.
  static OutlineInputBorder get _focusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      );

  /// Border input error.
  static OutlineInputBorder get _errorBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
        borderSide: const BorderSide(color: AppColors.error),
      );

  /// [InputDecoration] standar untuk semua field di flow registrasi.
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    bool filled = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textHint,
        fontSize: _fieldTextSize,
      ),
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: filled ? AppColors.background : AppColors.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: _border,
      enabledBorder: _border,
      focusedBorder: _focusedBorder,
      errorBorder: _errorBorder,
      focusedErrorBorder: _errorBorder,
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
    );
  }

  /// Pesan error standar untuk field wajib.
  static const String requiredMessage = 'This field is required';

  /// Style label field.
  static const TextStyle labelStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: _labelTextSize,
    fontWeight: FontWeight.w500,
  );

  /// Style judul seksi (mis. "Ordering Information").
  static const TextStyle sectionTitleStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Style input (isi & hint).
  static const TextStyle fieldTextStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: _fieldTextSize,
  );

  /// Theme untuk `showDatePicker` supaya konsisten dengan flow registrasi.
  static ThemeData datePickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
    );
  }
}
