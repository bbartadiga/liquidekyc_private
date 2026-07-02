import '../../core/constant/liquid_constants.dart';
import 'chip_result.dart';

enum FaceVerificationResultStatus {
  success,
  error,
  userCancel,
  unknown;

  static FaceVerificationResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return FaceVerificationResultStatus.success;
      case 'ERROR':
        return FaceVerificationResultStatus.error;
      case 'USER_CANCEL':
        return FaceVerificationResultStatus.userCancel;
      default:
        return FaceVerificationResultStatus.unknown;
    }
  }
}

class FaceAutoVerificationResult {
  final AutoVerificationResultStatus result;
  final String? message;

  FaceAutoVerificationResult({
    required this.result,
    this.message,
  });

  factory FaceAutoVerificationResult.fromMap(Map<String, dynamic>? map) {
    return FaceAutoVerificationResult(
      result: AutoVerificationResultStatus.fromString(map?['result']),
      message: map?['message'] as String?,
    );
  }
}

class FaceResult {
  final FaceVerificationResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;
  final FaceAutoVerificationResult? autoVerificationResult;

  FaceResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
    this.autoVerificationResult,
  });

  factory FaceResult.fromMap(Map<String, dynamic>? map) {
    return FaceResult(
      status: FaceVerificationResultStatus.fromString(map?['resultStatus']),
      errorCode: map?['errorCode'] as String?,
      additionalDataTitle: map?['additionalDataTitle'] as String?,
      additionalDataMessage: map?['additionalDataMessage'] as String?,
      autoVerificationResult: map?['autoVerificationResult'] != null
          ? FaceAutoVerificationResult.fromMap(
              map?['autoVerificationResult'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => status == FaceVerificationResultStatus.success;
  bool get isCancelled => status == FaceVerificationResultStatus.userCancel;
  bool get isAutoVerified =>
      autoVerificationResult?.result == AutoVerificationResultStatus.pass;

  LiquidErrorCode get liquidError => LiquidErrorCode.fromCode(errorCode);

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
      'resultStatus': status.name.toUpperCase(),
      'errorCode': errorCode,
      'additionalDataTitle': additionalDataTitle,
      'additionalDataMessage': additionalDataMessage,
      'autoVerificationResult': autoVerificationResult?.result.name,
    };
  }

  @override
  String toString() {
    return 'FaceResult(status: ${status.name}, autoVerify: ${autoVerificationResult?.result.name})';
  }
}