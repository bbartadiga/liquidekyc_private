class KycOrchestrationResponse {
  final bool isSuccess;
  final String? applicantId;
  final Map<String, dynamic>? registerInfo;
  final Map<String, dynamic>? icCardInfo;
  final List<dynamic>? photos;
  final List<dynamic>? livenessImages;
  final Map<String, dynamic>? verificationResults;
  final int? statusCode;
  final String? errorMessage;

  KycOrchestrationResponse({
    required this.isSuccess,
    this.applicantId,
    this.registerInfo,
    this.icCardInfo,
    this.photos,
    this.livenessImages,
    this.verificationResults,
    this.statusCode,
    this.errorMessage,
  });

  factory KycOrchestrationResponse.fromMap(Map<String, dynamic> map) {
    return KycOrchestrationResponse(
      isSuccess: true,
      applicantId: map['applicant_id'],
      registerInfo: map['register_info'] as Map<String, dynamic>?,
      icCardInfo: map['ic_card_info'] as Map<String, dynamic>?,
      photos: map['photos'] as List<dynamic>?,
      livenessImages: map['liveness_images'] as List<dynamic>?,
      verificationResults: map['verification_results'] as Map<String, dynamic>?,
      statusCode: map['status_code'],
    );
  }

  factory KycOrchestrationResponse.error({
    required int statusCode,
    required String message,
  }) => KycOrchestrationResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class KycTokenResponse {
  final bool isSuccess;
  final String? applicantId;
  final String? token;
  final int? statusCode;
  final String? errorMessage;

  KycTokenResponse({
    required this.isSuccess,
    this.applicantId,
    this.token,
    this.statusCode,
    this.errorMessage,
  });

  factory KycTokenResponse.fromMap(Map<String, dynamic> map) {
    return KycTokenResponse(
      isSuccess: map['token'] != null,
      applicantId: map['applicant_id'],
      token: map['token'],
      statusCode: map['status_code'],
      errorMessage: map['error_message'],
    );
  }

  factory KycTokenResponse.error({
    required int statusCode,
    required String message,
  }) => KycTokenResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}
