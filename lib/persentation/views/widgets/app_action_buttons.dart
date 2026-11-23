import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';

/// Tombol "Selesai" — hijau, full width.
///
/// Dipakai di halaman OCR Result dan di halaman Ordering Information.
class AppFinishButton extends StatelessWidget {
  const AppFinishButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Selesai',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Tombol "Lihat Log" — outline abu-abu + ikon bug.
///
/// Default-nya membuka halaman debug log (`/debug`).
class AppLogButton extends StatelessWidget {
  const AppLogButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed ?? () => Navigator.pushNamed(context, '/debug'),
        icon: const Icon(Icons.bug_report, size: 18),
        label: const Text('Lihat Log'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade600,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
