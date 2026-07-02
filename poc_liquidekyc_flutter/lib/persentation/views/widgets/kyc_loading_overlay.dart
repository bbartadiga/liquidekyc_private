import 'package:flutter/material.dart';
import '../../../core/constant/liquid_constants.dart';

class KycLoadingOverlay extends StatelessWidget {
  final String title;
  final String? message;
  final KycStep? step;

  const KycLoadingOverlay({
    super.key,
    required this.title,
    this.message,
    this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (step != null && step != KycStep.idle) ...[
                const SizedBox(height: 16),
                _buildStepIndicator(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final steps = [
      (KycStep.initializing, 'Menginisialisasi'),
      (KycStep.termsOfUse, 'Menampilkan Syarat'),
      (KycStep.documentScan, 'Memindai Dokumen'),
      (KycStep.icCardRead, 'Membaca Chip IC'),
      (KycStep.faceScan, 'Memindai Wajah'),
      (KycStep.activating, 'Mengaktifkan'),
    ];

    final currentIndex = steps.indexWhere((s) => s.$1 == step);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final stepName = entry.value.$2;
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                size: 16,
                color: isCompleted || isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                stepName,
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class KycLoadingDialog extends StatelessWidget {
  final String title;
  final String? message;

  const KycLoadingDialog({
    super.key,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KycLoadingDialog(
        title: title,
        message: message,
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}