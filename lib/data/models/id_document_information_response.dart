/// Response API 007 — 本人確認書類情報取得 (id_document_information).
///
/// SUMBER: spec "LIQUID_eKYC_007_本人確認書類情報取得API_v1.6.8" hal.5-6.
/// Endpoint: `GET /v1/applicants/{applicant_id}/id_document_information`
///
/// Bedanya sama API 022 (ICカード読取情報取得): 007 ngasih field yang
/// di-register/di-koreksi di **eKYC Manager** — termasuk `stay_expire_date`
/// dan `resident_status` yang nggak ada di data chip.
///
/// Spec: "氏名 / 生年月日 / 住所 / 在留期間の満了日 / 在留資格 =
/// Manager データ修正機能で修正した値" → kalau nggak pernah dikoreksi di
/// Manager, nilainya null.
class IdDocumentInformationResponse {
  final bool isSuccess;
  final String? idDocumentType;
  final String? idNumber;
  final String? expireDate;
  final String? name;
  final String? birthday;
  final String? address;
  final String? stayExpireDate;
  final String? residentStatus;
  final int? statusCode;
  final String? errorMessage;

  IdDocumentInformationResponse({
    required this.isSuccess,
    this.idDocumentType,
    this.idNumber,
    this.expireDate,
    this.name,
    this.birthday,
    this.address,
    this.stayExpireDate,
    this.residentStatus,
    this.statusCode,
    this.errorMessage,
  });

  factory IdDocumentInformationResponse.fromMap(Map<String, dynamic> map) {
    return IdDocumentInformationResponse(
      isSuccess: true,
      idDocumentType: map['id_document_type']?.toString(),
      idNumber: map['id_number']?.toString(),
      expireDate: map['expire_date']?.toString(),
      name: map['name']?.toString(),
      birthday: map['birthday']?.toString(),
      address: map['address']?.toString(),
      stayExpireDate: map['stay_expire_date']?.toString(),
      residentStatus: map['resident_status']?.toString(),
    );
  }

  factory IdDocumentInformationResponse.error({
    required int statusCode,
    required String message,
  }) => IdDocumentInformationResponse(
        isSuccess: false,
        statusCode: statusCode,
        errorMessage: message,
      );
}
