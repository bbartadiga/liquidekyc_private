import 'package:flutter/material.dart';
import '../../../core/constant/liquid_constants.dart';

class KycStatusScreen extends StatelessWidget {
  final KycStep step;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const KycStatusScreen({
    super.key,
    required this.step,
    this.isLoading = false,
    this.errorMessage,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepIcon(),
            const SizedBox(height: 24),
            _buildStepTitle(context),
            const SizedBox(height: 12),
            _buildStepDescription(context),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(context),
            ],
            if (isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 32),
            _buildActions(context),
            const SizedBox(height: 24),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon() {
    if (isLoading) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.blue,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
        ),
      );
    }

    IconData icon;
    Color color;

    switch (step) {
      case KycStep.initializing:
        icon = Icons.settings;
        color = Colors.blue;
        break;
      case KycStep.termsOfUse:
        icon = Icons.description;
        color = Colors.orange;
        break;
      case KycStep.documentScan:
        icon = Icons.camera_alt;
        color = Colors.green;
        break;
      case KycStep.icCardRead:
        icon = Icons.nfc;
        color = Colors.purple;
        break;
      case KycStep.faceScan:
        icon = Icons.face;
        color = Colors.teal;
        break;
      case KycStep.activating:
        icon = Icons.verified;
        color = Colors.indigo;
        break;
      case KycStep.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 50,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStepTitle(BuildContext context) {
    String title;
    switch (step) {
      case KycStep.initializing:
        title = 'Initializing';
        break;
      case KycStep.termsOfUse:
        title = 'Terms of Use';
        break;
      case KycStep.documentScan:
        title = 'Document Scanning';
        break;
      case KycStep.icCardRead:
        title = 'Reading IC Card';
        break;
      case KycStep.faceScan:
        title = 'Face Capture';
        break;
      case KycStep.activating:
        title = 'Activating';
        break;
      case KycStep.completed:
        title = 'Completed';
        break;
      default:
        title = step.displayName;
    }

    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStepDescription(BuildContext context) {
    String description;
    switch (step) {
      case KycStep.initializing:
        description = 'Setting up secure connection...';
        break;
      case KycStep.termsOfUse:
        description = 'Please review and accept the terms of use';
        break;
      case KycStep.documentScan:
        description = 'Position your ID document within the frame';
        break;
      case KycStep.icCardRead:
        description = 'Hold your device near the IC card';
        break;
      case KycStep.faceScan:
        description = 'Look at the camera and follow the instructions';
        break;
      case KycStep.activating:
        description = 'Finalizing verification on secure server...';
        break;
      case KycStep.completed:
        description = 'Verification completed successfully!';
        break;
      default:
        description = 'Please wait...';
    }

    return Text(
      description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onCancel != null && step != KycStep.activating && step != KycStep.completed)
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        if (onRetry != null && errorMessage != null) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [
      KycStep.initializing,
      KycStep.termsOfUse,
      KycStep.documentScan,
      KycStep.icCardRead,
      KycStep.faceScan,
      KycStep.activating,
    ];

    final currentIndex = steps.indexOf(step);
    if (currentIndex == -1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? Colors.blue
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrent ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (index < steps.length - 1)
              Container(
                width: 24,
                height: 2,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        );
      }).toList(),
    );
  }
}

class KycStepIndicator extends StatelessWidget {
  final KycStep currentStep;
  final List<KycStep> steps;
  final Map<KycStep, String> stepLabels;

  const KycStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(currentStep);

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final stepItem = entry.value;
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.blue
                          : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isCurrent ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stepLabels[stepItem] ?? stepItem.displayName,
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent ? Colors.blue : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}