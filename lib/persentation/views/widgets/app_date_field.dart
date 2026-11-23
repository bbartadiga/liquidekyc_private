import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../data/models/ordering_information_draft.dart';
import '../../styles/app_theme.dart';
import 'app_field_label.dart';

/// Field tanggal format YYYY / MM / DD plus ikon kalender untuk memilih
/// tanggal lewat date picker.
///
/// Ketiga kotak isinya read-only; satu-satunya cara mengisi adalah lewat
/// tombol kalender.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.yearController,
    required this.monthController,
    required this.dayController,
    required this.onPickDate,
    this.required = false,
    this.source,
  });

  final String label;
  final TextEditingController yearController;
  final TextEditingController monthController;
  final TextEditingController dayController;
  final VoidCallback onPickDate;
  final bool required;

  /// Sumber data field ini (badge kecil di sebelah label).
  final OrderingFieldSource? source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(
          label: label,
          required: required,
          source: source,
        ),
        const SizedBox(height: AppDimens.labelGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: _DateBox(
                label: '$label year',
                controller: yearController,
                hint: 'YYYY',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _DateBox(
                label: '$label month',
                controller: monthController,
                hint: 'MM',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _DateBox(
                label: '$label day',
                controller: dayController,
                hint: 'DD',
              ),
            ),
            const SizedBox(width: 4),
            // Tombol bener (bukan GestureDetector) → bisa dipakai keyboard &
            // dibacakan screen reader sebagai "Pilih tanggal".
            IconButton(
              onPressed: onPickDate,
              tooltip: 'Pilih tanggal',
              icon: const Icon(Icons.calendar_month),
              color: AppColors.accent,
              iconSize: AppDimens.calendarIcon,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppFieldSemantics(
      label: label,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        showCursor: false,
        enableInteractiveSelection: false,
        style: AppTheme.fieldTextStyle,
        decoration: AppTheme.inputDecoration(hintText: hint),
      ),
    );
  }
}
