import 'package:flutter/material.dart';
import '../../../data/models/ordering_information_draft.dart';
import '../../styles/app_theme.dart';
import 'app_field_label.dart';

/// Text field standar: label di atas, input full width di bawahnya.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.source,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;

  /// Jumlah baris input. >1 untuk field yang isinya panjang (mis. alamat),
  /// supaya teksnya nggak kepotong di tepi field.
  final int maxLines;
  final TextCapitalization textCapitalization;

  /// Sumber data field ini (badge kecil di sebelah label).
  final OrderingFieldSource? source;

  @override
  Widget build(BuildContext context) {
    final input = AppFieldSemantics(
      label: label ?? '',
      required: required,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        onChanged: onChanged,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLength: maxLength,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: AppTheme.fieldTextStyle,
        decoration: AppTheme.inputDecoration(hintText: hintText),
      ),
    );

    if (label == null) return input;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(
          label: label!,
          required: required,
          source: source,
        ),
        const SizedBox(height: AppDimens.labelGap),
        input,
      ],
    );
  }
}
