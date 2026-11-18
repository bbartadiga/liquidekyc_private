enum LiquidProcessingResultStatus {
  success,
  error,
  userCancel,
  communicationFailure,
  sessionTimeout,
  maintenance,
  termsDoNotAgree,
  unknown;

  static LiquidProcessingResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return LiquidProcessingResultStatus.success;
      case 'ERROR':
        return LiquidProcessingResultStatus.error;
      case 'USER_CANCEL':
        return LiquidProcessingResultStatus.userCancel;
      case 'COMMUNICATION_FAILURE':
        return LiquidProcessingResultStatus.communicationFailure;
      case 'SESSION_TIMEOUT':
        return LiquidProcessingResultStatus.sessionTimeout;
      case 'MAINTENANCE':
        return LiquidProcessingResultStatus.maintenance;
      case 'TERMS_DO_NOT_AGREE':
        return LiquidProcessingResultStatus.termsDoNotAgree;
      default:
        return LiquidProcessingResultStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case LiquidProcessingResultStatus.success:
        return 'Success';
      case LiquidProcessingResultStatus.error:
        return 'Error';
      case LiquidProcessingResultStatus.userCancel:
        return 'Cancelled by user';
      case LiquidProcessingResultStatus.communicationFailure:
        return 'Communication failed';
      case LiquidProcessingResultStatus.sessionTimeout:
        return 'Session expired';
      case LiquidProcessingResultStatus.maintenance:
        return 'Under maintenance';
      case LiquidProcessingResultStatus.termsDoNotAgree:
        return 'Terms not agreed';
      case LiquidProcessingResultStatus.unknown:
        return 'Unknown';
    }
  }
}


enum KycStep {
  idle,
  initializing,
  termsOfUse,
  documentScan,
  icCardRead,
  faceScan,
  activating,
  completed,
  error;

  String get displayName {
    switch (this) {
      case KycStep.idle:
        return 'Ready';
      case KycStep.initializing:
        return 'Initializing...';
      case KycStep.termsOfUse:
        return 'Accept Terms';
      case KycStep.documentScan:
        return 'Scanning Document';
      case KycStep.icCardRead:
        return 'Reading IC Card';
      case KycStep.faceScan:
        return 'Capturing Face';
      case KycStep.activating:
        return 'Activating...';
      case KycStep.completed:
        return 'Completed';
      case KycStep.error:
        return 'Error';
    }
  }
}

// ============================================================
// ============================================================
// LIQUID SDK ERROR CODES (v1.45.0)
// & BE COMMON ERROR CODES (G06 v1.3.0)
// ============================================================
