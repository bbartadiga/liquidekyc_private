class ApplicantInfoResponse {
  final bool isSuccess;
  final String? applicationId;
  final String? status;
  final String? registeredAt;
  final int? statusCode;
  final String? errorMessage;

  ApplicantInfoResponse({
    required this.isSuccess,
    this.applicationId,
    this.status,
    this.registeredAt,
    this.statusCode,
    this.errorMessage,
  });

  factory ApplicantInfoResponse.fromMap(Map<String, dynamic> map) {
    return ApplicantInfoResponse(
      isSuccess: map['application_id'] != null || map['id'] != null,
      applicationId: map['application_id'] ?? map['id'],
      status: map['status'],
      registeredAt: map['registered_at'],
      statusCode: map['status_code'],
      errorMessage: map['error_message'],
    );
  }

  factory ApplicantInfoResponse.error({
    required int statusCode,
    required String message,
  }) => ApplicantInfoResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class RegisterApplicationInfoResponse {
  final bool isSuccess;
  final String? applicationId;
  final String? status;
  final String? registeredAt;
  final int? statusCode;
  final String? errorMessage;

  RegisterApplicationInfoResponse({
    required this.isSuccess,
    this.applicationId,
    this.status,
    this.registeredAt,
    this.statusCode,
    this.errorMessage,
  });

  factory RegisterApplicationInfoResponse.fromMap(Map<String, dynamic> map) {
    return RegisterApplicationInfoResponse(
      isSuccess: true,
      applicationId: map['application_id'] ?? map['id'],
      status: map['status'],
      registeredAt: map['registered_at'],
      statusCode: map['status_code'],
    );
  }

  factory RegisterApplicationInfoResponse.error({
    required int statusCode,
    required String message,
  }) => RegisterApplicationInfoResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}
