import '../../core/constant/liquid_constants.dart';
import 'chip_result.dart';

enum DocumentVerificationResultStatus {
  success,
  error,
  userCancel,
  unknown;

  static DocumentVerificationResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return DocumentVerificationResultStatus.success;
      case 'ERROR':
        return DocumentVerificationResultStatus.error;
      case 'USER_CANCEL':
        return DocumentVerificationResultStatus.userCancel;
      default:
        return DocumentVerificationResultStatus.unknown;
    }
  }
}

class DocumentResult {
  final DocumentVerificationResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;
  final DocumentImage? documentImage;
  final AutoVerificationResult? autoVerificationResult;

  DocumentResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
    this.documentImage,
    this.autoVerificationResult,
  });

  factory DocumentResult.fromMap(Map<String, dynamic>? map) {
    return DocumentResult(
      status: DocumentVerificationResultStatus.fromString(map?['resultStatus']),
      errorCode: map?['errorCode'] as String?,
      additionalDataTitle: map?['additionalDataTitle'] as String?,
      additionalDataMessage: map?['additionalDataMessage'] as String?,
      documentImage: map?['documentImage'] != null
          ? DocumentImage.fromMap(map?['documentImage'] as Map<String, dynamic>)
          : null,
      autoVerificationResult: map?['autoVerificationResult'] != null
          ? AutoVerificationResult.fromMap(
              map?['autoVerificationResult'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => status == DocumentVerificationResultStatus.success;
  bool get isCancelled => status == DocumentVerificationResultStatus.userCancel;
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
      'documentImage': documentImage?.base64Data,
      'autoVerificationResult': autoVerificationResult?.result.name,
    };
  }

  @override
  String toString() {
    return 'DocumentResult(status: ${status.name}, errorCode: $errorCode, autoVerified: $isAutoVerified)';
  }
}