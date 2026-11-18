class KycRequestInformationResponse {
  final bool isSuccess;
  final String? applicantId;
  final String? status;
  final int? statusCode;
  final String? errorMessage;

  KycRequestInformationResponse({
    required this.isSuccess,
    this.applicantId,
    this.status,
    this.statusCode,
    this.errorMessage,
  });

  factory KycRequestInformationResponse.fromMap(Map<String, dynamic> map) {
    return KycRequestInformationResponse(
      isSuccess: map['applicant_id'] != null,
      applicantId: map['applicant_id'],
      status: map['status'],
      statusCode: map['status_code'],
    );
  }

  factory KycRequestInformationResponse.error({
    required int statusCode,
    required String message,
  }) => KycRequestInformationResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}
