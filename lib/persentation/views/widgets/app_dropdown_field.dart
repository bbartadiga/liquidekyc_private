import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../data/models/ordering_information_draft.dart';
import '../../styles/app_theme.dart';
import 'app_field_label.dart';

/// Dropdown standar: label di atas, dropdown full width di bawahnya.
///
/// [items] berisi nilai dropdown, [itemLabel] mengubah nilai itu jadi teks
/// yang ditampilkan. `hintText` dipakai saat belum ada nilai terpilih.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.required = false,
    this.itemLabel,
    this.validator,
    this.source,
  });

  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final bool required;
  final String Function(T item)? itemLabel;
  final FormFieldValidator<T>? validator;

  /// Sumber data field ini (badge kecil di sebelah label).
  final OrderingFieldSource? source;

  String _labelOf(T item) => itemLabel?.call(item) ?? '$item';

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
        AppFieldSemantics(
          label: label,
          required: required,
          child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.surface,
          iconSize: 20,
          iconEnabledColor: AppColors.textSecondary,
          iconDisabledColor: AppColors.textHint,
          focusColor: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          style: AppTheme.fieldTextStyle,
          hint: hintText == null
              ? null
              : Text(
                  hintText!,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    _labelOf(item),
                    style: AppTheme.fieldTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: AppTheme.inputDecoration(),
          ),
        ),
      ],
    );
  }
}
