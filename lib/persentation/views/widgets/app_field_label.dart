import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../data/models/ordering_information_draft.dart';
import '../../styles/app_theme.dart';

/// Label field dengan penanda wajib (`*`) + badge sumber data.
///
/// Label ini murni visual — teksnya di-exclude dari semantics supaya
/// nggak dibacakan dua kali. Pembacaan label (dan info "wajib")-nya
/// dilewatkan ke input lewat [AppFieldSemantics].
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({
    super.key,
    required this.label,
    this.required = false,
    this.source,
  });

  final String label;
  final bool required;

  /// Sumber data field ini — kalau ada, badge kecil muncul di kanan label.
  final OrderingFieldSource? source;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              style: AppTheme.labelStyle,
            ),
          ),
        ),
        if (source != null && source!.label.isNotEmpty) ...[
          const SizedBox(width: 6),
          _SourceBadge(label: source!.label),
        ],
      ],
    );
  }
}

/// Label semantik untuk input: nama field + penanda wajib.
///
/// Dipakai bareng [AppFieldLabel] (yang visual) supaya screen reader
/// tetap tahu field ini field apa dan wajib atau nggak.
class AppFieldSemantics extends StatelessWidget {
  const AppFieldSemantics({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: required ? '$label, required' : label,
      child: child,
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
