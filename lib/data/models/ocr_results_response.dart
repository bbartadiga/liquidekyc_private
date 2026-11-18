import '../../core/services/app_logger.dart';

class OcrResultsBeResponse {
  final bool isSuccess;
  final String? name;
  final String? birthday;
  final String? sex;
  final String? address;
  final String? addressPref;
  final String? addressCity;
  final String? addressOther;
  final String? zipCode;
  final String? expireDate;
  final String? idNumber;
  final String? issueDate;
  final String? nationality;
  final String? residentStatus;
  final String? stayPeriod;
  final String? stayExpireDate;
  final String? idDocumentType;
  // Gen-2 / Specified Residence Card fields (D7 page 6-22)
  final String? cardType;
  final String? residentStatusCode;
  final String? kindOfPermissionCode;
  final String? employmentRestrictionCode;
  final String? nationalityCode3;
  // Address change detection + change flags (D1 page 6)
  final String? addressChanged;             // 0/1 — recently changed
  final String? nameChanged;               // 0/1 — recently changed
  final String? remarksExist;              // 0/1 — has remarks content
  // Driver's License multi-category (D1 page ~10)
  final List<String>? driversLicenseTypes;
  // 個人番号 (My Number) — hanya untuk My Number Card
  final String? myNumber;
  final int? statusCode;
  final String? errorMessage;

  OcrResultsBeResponse({
    required this.isSuccess,
    this.name,
    this.birthday,
    this.sex,
    this.address,
    this.addressPref,
    this.addressCity,
    this.addressOther,
    this.zipCode,
    this.expireDate,
    this.idNumber,
    this.issueDate,
    this.nationality,
    this.residentStatus,
    this.stayPeriod,
    this.stayExpireDate,
    this.idDocumentType,
    this.cardType,
    this.residentStatusCode,
    this.kindOfPermissionCode,
    this.employmentRestrictionCode,
    this.nationalityCode3,
    this.addressChanged,
    this.nameChanged,
    this.remarksExist,
    this.driversLicenseTypes,
    this.myNumber,
    this.statusCode,
    this.errorMessage,
  });

  String get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : address ?? '-';
  }

  factory OcrResultsBeResponse.fromMap(Map<String, dynamic> map) {
    final idDocumentType = map['id_document_type']?.toString();
    final nationality2 = map['nationality'];
    final residentStatus = map['resident_status'];

    // Gen-2 fields
    final cardType = map['card_type']?.toString();
    final residentStatusCode = map['resident_status_code']?.toString();
    final kindOfPermissionCode =
        map['kind_of_permission_code']?.toString();
    final employmentRestrictionCode =
        map['employment_restriction_code']?.toString();
    final nationalityCode3 =
        map['nationality_code3']?.toString();

    final addressChanged = map['address_changed']?.toString();
    final nameChanged = map['name_changed']?.toString();
    final remarksExist = map['remarks_exist']?.toString();
    final driversLicenseTypes =
        (map['drivers_license_types'] as List<dynamic>?)?.cast<String>();
    final myNumber = map['my_number']?.toString();

    appLogger.i(
      '[OCR-Parse-BE] '
      'id_document_type=$idDocumentType | '
      'card_type=$cardType | '
      'nationality_2=$nationality2 | '
      'nationality_3=$nationalityCode3 | '
      'resident_status=$residentStatus | '
      'resident_status_code=$residentStatusCode | '
      'kind_of_permission=$kindOfPermissionCode | '
      'employment_restriction=$employmentRestrictionCode | '
      'address_changed=${addressChanged ?? "-"} | '
      'name_changed=${nameChanged ?? "-"} | '
      'remarks_exist=${remarksExist ?? "-"} | '
      'license_types=${driversLicenseTypes?.join(",") ?? "-"} | '
      'my_number=${myNumber != null && myNumber.length >= 4 ? "*******${myNumber.substring(myNumber.length - 4)}" : "-"} | '
      'name=${map['name'] ?? "-"} | '
      'birthday=${map['birthday'] ?? "-"} | '
      'sex=${map['sex'] ?? "-"} | '
      'id_number=${map['id_number'] ?? "-"} | '
      'expire_date=${map['expire_date'] ?? "-"} | '
      'issue_date=${map['issue_date'] ?? "-"} | '
      'stay_period=${map['stay_period'] ?? "-"} | '
      'address=${map['address'] != null ? "***MASKED***" : "-"}',
    );

    return OcrResultsBeResponse(
      isSuccess: true,
      name: map['name'],
      birthday: map['birthday'],
      sex: map['sex'],
      address: map['address'],
      addressPref: map['address_pref'],
      addressCity: map['address_city'],
      addressOther: map['address_other'],
      zipCode: map['zip_code'],
      expireDate: map['expire_date'],
      idNumber: map['id_number'],
      issueDate: map['issue_date'],
      nationality: nationality2,
      residentStatus: residentStatus,
      stayPeriod: map['stay_period'],
      stayExpireDate: map['stay_expire_date'],
      idDocumentType: idDocumentType,
      cardType: cardType,
      residentStatusCode: residentStatusCode,
      kindOfPermissionCode: kindOfPermissionCode,
      employmentRestrictionCode: employmentRestrictionCode,
      nationalityCode3: nationalityCode3,
      addressChanged: addressChanged,
      nameChanged: nameChanged,
      remarksExist: remarksExist,
      driversLicenseTypes: driversLicenseTypes,
      myNumber: myNumber,
      statusCode: map['status_code'],
    );
  }

  factory OcrResultsBeResponse.error({
    required int statusCode,
    required String message,
  }) => OcrResultsBeResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}
