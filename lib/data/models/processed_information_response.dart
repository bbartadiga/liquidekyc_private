/// Response API 027 — kyc追加データ取得 (processed_information).
///
/// SUMBER: spec "LIQUID_eKYC_027_kyc追加データ取得API_v1.0.0" hal.3-4.
/// Endpoint: `GET /v1/applicants/{applicant_id}/processed_information`
///
/// Isinya data yang sudah diproses Liquid dari applicant info yang kita
/// daftar di 016 — termasuk **romanisasi nama** (yang dilakukan server,
/// jadi lebih akurat daripada transliterasi lokal).
class ProcessedInformationResponse {
  final bool isSuccess;
  final bool? latinNameAvailable;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final int? statusCode;
  final String? errorMessage;

  ProcessedInformationResponse({
    required this.isSuccess,
    this.latinNameAvailable,
    this.lastName,
    this.firstName,
    this.middleName,
    this.statusCode,
    this.errorMessage,
  });

  factory ProcessedInformationResponse.fromMap(Map<String, dynamic> map) {
    final latin = map['latin_name'];
    final latinMap = latin is Map<String, dynamic> ? latin : null;

    return ProcessedInformationResponse(
      isSuccess: true,
      latinNameAvailable: latinMap?['is_available'] as bool?,
      lastName: latinMap?['last_name']?.toString(),
      firstName: latinMap?['first_name']?.toString(),
      middleName: latinMap?['middle_name']?.toString(),
    );
  }

  factory ProcessedInformationResponse.error({
    required int statusCode,
    required String message,
  }) => ProcessedInformationResponse(
        isSuccess: false,
        statusCode: statusCode,
        errorMessage: message,
      );

  /// Nama latin "LAST FIRST" (UPPERCASE), null kalau belum tersedia.
  ///
  /// Spec: latin_name is_available=false → last_name/first_name = null.
  String? get latinFullName {
    if (latinNameAvailable != true) return null;
    final parts = <String>[
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ').toUpperCase();
  }
}
