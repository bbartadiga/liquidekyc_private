class VerificationResultsResponse {
  final bool isSuccess;
  final double? faceMatchScore;
  final String? autoVerificationStatus;
  final String? livenessResult;
  final int? statusCode;
  final String? errorMessage;

  VerificationResultsResponse({
    required this.isSuccess,
    this.faceMatchScore,
    this.autoVerificationStatus,
    this.livenessResult,
    this.statusCode,
    this.errorMessage,
  });

  factory VerificationResultsResponse.fromMap(Map<String, dynamic> map) {
    return VerificationResultsResponse(
      isSuccess: true,
      faceMatchScore: map['face_match_score'] != null
          ? (map['face_match_score'] as num).toDouble()
          : null,
      autoVerificationStatus: map['auto_verification_status'] ?? map['status'],
      livenessResult: map['liveness_result'],
      statusCode: map['status_code'],
    );
  }

  factory VerificationResultsResponse.error({
    required int statusCode,
    required String message,
  }) => VerificationResultsResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}
