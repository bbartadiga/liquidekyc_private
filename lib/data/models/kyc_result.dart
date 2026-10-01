import '../../core/constant/liquid_constants.dart';

class KycResult {
  final LiquidProcessingResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;

  KycResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
  });

  factory KycResult.fromMap(Map<String, dynamic>? map) {
    return KycResult(
      status: LiquidProcessingResultStatus.fromString(map?['resultStatus'] ?? map?['result']),
      errorCode: map?['errorCode'] as String?,
      additionalDataTitle: map?['additionalDataTitle'] as String?,
      additionalDataMessage: map?['additionalDataMessage'] as String?,
    );
  }

  factory KycResult.success() {
    return KycResult(status: LiquidProcessingResultStatus.success);
  }

  factory KycResult.error({
    required String errorCode,
    String? title,
    String? message,
  }) {
    return KycResult(
      status: LiquidProcessingResultStatus.error,
      errorCode: errorCode,
      additionalDataTitle: title,
      additionalDataMessage: message,
    );
  }

  bool get isSuccess => status == LiquidProcessingResultStatus.success;
  bool get isCancelled => status == LiquidProcessingResultStatus.userCancel;
  bool get isMaintenance => status == LiquidProcessingResultStatus.maintenance;
  bool get isTermsNotAgreed =>
      status == LiquidProcessingResultStatus.termsDoNotAgree;
  bool get isSessionTimeout =>
      status == LiquidProcessingResultStatus.sessionTimeout;
  bool get isCommunicationFailure =>
      status == LiquidProcessingResultStatus.communicationFailure;

  LiquidErrorCode get liquidError => LiquidErrorCode.fromCode(errorCode);

  bool get isImplementationError => 
      liquidError == LiquidErrorCode.implementationError ||
      liquidError == LiquidErrorCode.invalidArguments ||
      liquidError == LiquidErrorCode.invalidArgumentsBase64;

  bool get isSessionExpired =>
      liquidError == LiquidErrorCode.sessionTimeout ||
      liquidError == LiquidErrorCode.invalidToken;

  bool get isChipLocked =>
      liquidError == LiquidErrorCode.icChipLocked;

  String get userFriendlyMessage {
    if (additionalDataMessage != null && additionalDataMessage!.isNotEmpty) {
      return additionalDataMessage!;
    }
    return liquidError.userFriendlyMessage;
  }

  String get fullErrorDescription {
    return '[${errorCode ?? 'UNKNOWN'}] ${liquidError.description}';
  }

  Map<String, dynamic> toMap() {
    return {
      'result': status.name.toUpperCase(),
      'errorCode': errorCode,
      'additionalDataTitle': additionalDataTitle,
      'additionalDataMessage': additionalDataMessage,
    };
  }

  @override
  String toString() {
    return 'KycResult(status: ${status.name}, errorCode: $errorCode, message: $additionalDataMessage)';
  }
}