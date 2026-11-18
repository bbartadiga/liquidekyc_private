enum Sex {
  male,
  female,
  /// SDK LiquidChipData Sex: MALE / FEMALE / OTHERS
  others,
  unknown;

  static Sex fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MALE':
        return Sex.male;
      case 'FEMALE':
        return Sex.female;
      case 'OTHERS':
        return Sex.others;
      default:
        return Sex.unknown;
    }
  }
}


/// Data SIM terintegrasi pada My Number Card.
/// (asia.liquidinc.ekyc.applicant.external.result.chip.MyNumberCardIntegratedDriverLicenseData)
class MyNumberCardIntegratedDriverLicense {
  final String? colorCategory;
  final List<String>? conditions;
  final List<String>? types;
  final List<String>? remarks;
  final List<String>? acquisitionDates;
  final String? recordNumber;
  final String? validUntil;

  const MyNumberCardIntegratedDriverLicense({
    this.colorCategory,
    this.conditions,
    this.types,
    this.remarks,
    this.acquisitionDates,
    this.recordNumber,
    this.validUntil,
  });

  factory MyNumberCardIntegratedDriverLicense.fromMap(
    Map<String, dynamic>? map,
  ) {
    if (map == null) return const MyNumberCardIntegratedDriverLicense();
    return MyNumberCardIntegratedDriverLicense(
      colorCategory: map['colorCategory']?.toString(),
      conditions: (map['conditions'] as List<dynamic>?)?.cast<String>(),
      types: (map['types'] as List<dynamic>?)?.cast<String>(),
      remarks: (map['remarks'] as List<dynamic>?)?.cast<String>(),
      acquisitionDates:
          (map['acquisitionDates'] as List<dynamic>?)?.cast<String>(),
      recordNumber: map['recordNumber']?.toString(),
      validUntil: map['validUntil']?.toString(),
    );
  }

  bool get isEmpty =>
      colorCategory == null &&
      (types == null || types!.isEmpty) &&
      (conditions == null || conditions!.isEmpty);
}

/// Detail kartu tinggal Gen-2.
/// (asia.liquidinc.ekyc.applicant.external.result.chip.ResidenceDocumentGen2Data)
///
/// PENTING: untuk Gen-2, field izin tinggal TIDAK ada di level atas
/// `residenceCardIndividualPermission` — semuanya ada di sini.
class ResidenceDocumentGen2 {
  final String? comprehensivePermissionCode;
  final String? expireDateOfComprehensivePermission;
  final String? individualPermission;
  final String? residenceDocumentGen2InfoType;
  final String? nationalityCode;
  final String? residenceStatusCode;
  final String? stayPeriodYear;
  final String? stayPeriodMonths;
  final String? stayPeriodDay;
  final String? kindOfPermissionCode;
  final String? permittedDate;
  final String? employmentRestriction;
  final String? stayExpireDate;
  final String? stayUpdateStatus;
  final String? immigrationCommissionerStatement;

  const ResidenceDocumentGen2({
    this.comprehensivePermissionCode,
    this.expireDateOfComprehensivePermission,
    this.individualPermission,
    this.residenceDocumentGen2InfoType,
    this.nationalityCode,
    this.residenceStatusCode,
    this.stayPeriodYear,
    this.stayPeriodMonths,
    this.stayPeriodDay,
    this.kindOfPermissionCode,
    this.permittedDate,
    this.employmentRestriction,
    this.stayExpireDate,
    this.stayUpdateStatus,
    this.immigrationCommissionerStatement,
  });

  factory ResidenceDocumentGen2.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ResidenceDocumentGen2();
    return ResidenceDocumentGen2(
      comprehensivePermissionCode: map['comprehensivePermissionCode']?.toString(),
      expireDateOfComprehensivePermission:
          map['expireDateOfComprehensivePermission']?.toString(),
      individualPermission: map['individualPermission']?.toString(),
      residenceDocumentGen2InfoType:
          map['residenceDocumentGen2InfoType']?.toString(),
      nationalityCode: map['nationalityCode']?.toString(),
      residenceStatusCode: map['residenceStatusCode']?.toString(),
      stayPeriodYear: map['stayPeriodYear']?.toString(),
      stayPeriodMonths: map['stayPeriodMonths']?.toString(),
      stayPeriodDay: map['stayPeriodDay']?.toString(),
      kindOfPermissionCode: map['kindOfPermissionCode']?.toString(),
      permittedDate: map['permittedDate']?.toString(),
      employmentRestriction: map['employmentRestriction']?.toString(),
      stayExpireDate: map['stayExpireDate']?.toString(),
      stayUpdateStatus: map['stayUpdateStatus']?.toString(),
      immigrationCommissionerStatement:
          map['immigrationCommissionerStatement']?.toString(),
    );
  }

  /// Masa izin dalam format "Y年M月D日" (tahun/bulan/hari dari chip).
  String? get stayPeriod {
    final y = stayPeriodYear;
    final m = stayPeriodMonths;
    final d = stayPeriodDay;
    if (y == null && m == null && d == null) return null;
    return '${y ?? '-'} / ${m ?? '-'} / ${d ?? '-'}';
  }

  bool get isEmpty =>
      comprehensivePermissionCode == null &&
      individualPermission == null &&
      residenceDocumentGen2InfoType == null &&
      nationalityCode == null;
}

class LiquidChipDataModel {
  final String? name;
  final String? nameKana;
  final String? birthday;
  final Sex? sex;
  final String? address;
  final String? addressPref;
  final String? addressCity;
  final String? addressOther;
  final String? idNumber;
  final String? issueDate;
  final String? expireDate;
  final String? myNumber;
  final bool? hasIdFacePhoto;
  final bool? hasDocumentFrontImage;
  final String? residenceCardType;
  final String? zipCode;
  // Dokumen aktual yang dibaca dari chip (bukan pilihan user)
  final String? liquidDocumentType;
  final String? residenceCardInfoType;
  final List<String>? driversLicenseTypes;
  final List<String>? driversLicenseConditions;
  final List<String>? driversLicenseAcquisitionDates;
  final String? residenceCardComprehensivePermission;
  final String? residenceCardIndividualPermission;

  // --- Nama (lanjutan) ---
  final String? nameHalfWidthKana;
  final List<String>? lastNameKanaCandidates;
  final List<String>? lastNameHalfWidthKanaCandidates;
  final List<String>? firstNameKanaCandidates;
  final List<String>? firstNameHalfWidthKanaCandidates;
  final String? previousName;
  final List<String>? previousLastNameKanaCandidates;
  final List<String>? previousLastNameHalfWidthKanaCandidates;
  final String? aliasName;

  // --- Alamat (lanjutan) ---
  final List<String>? addressModificationHistories;

  // --- Status tinggal ---
  final String? movedAbroad;
  final String? plannedAbroadMoveDate;
  final String? japaneseForeignerJudgment;
  final String? pscName;
  final List<String>? pscNames;

  // --- Dokumen-integrated ---
  final MyNumberCardIntegratedDriverLicense? myNumberCardIntegratedDriverLicense;
  final ResidenceDocumentGen2? residenceDocumentGen2;

  final bool? hasAddressImage;

  LiquidChipDataModel({
    this.name,
    this.nameKana,
    this.birthday,
    this.sex,
    this.address,
    this.addressPref,
    this.addressCity,
    this.addressOther,
    this.idNumber,
    this.issueDate,
    this.expireDate,
    this.myNumber,
    this.hasIdFacePhoto,
    this.hasDocumentFrontImage,
    this.residenceCardType,
    this.zipCode,
    this.liquidDocumentType,
    this.residenceCardInfoType,
    this.driversLicenseTypes,
    this.driversLicenseConditions,
    this.driversLicenseAcquisitionDates,
    this.residenceCardComprehensivePermission,
    this.residenceCardIndividualPermission,
    this.nameHalfWidthKana,
    this.lastNameKanaCandidates,
    this.lastNameHalfWidthKanaCandidates,
    this.firstNameKanaCandidates,
    this.firstNameHalfWidthKanaCandidates,
    this.previousName,
    this.previousLastNameKanaCandidates,
    this.previousLastNameHalfWidthKanaCandidates,
    this.aliasName,
    this.addressModificationHistories,
    this.movedAbroad,
    this.plannedAbroadMoveDate,
    this.japaneseForeignerJudgment,
    this.pscName,
    this.pscNames,
    this.myNumberCardIntegratedDriverLicense,
    this.residenceDocumentGen2,
    this.hasAddressImage,
  });

  factory LiquidChipDataModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return LiquidChipDataModel();
    
    // Handle sex - bisa int (1/2) atau string
    final sexValue = map['sex'];
    Sex? sex;
    if (sexValue != null) {
      if (sexValue is int) {
        sex = sexValue == 1 ? Sex.male : (sexValue == 2 ? Sex.female : Sex.unknown);
      } else {
        sex = Sex.fromString(sexValue.toString());
      }
    }
    
    return LiquidChipDataModel(
      name: map['name']?.toString(),
      nameKana: map['nameKana']?.toString(),
      birthday: map['birthday']?.toString(),
      sex: sex,
      address: map['address']?.toString(),
      addressPref: map['addressPref']?.toString(),
      addressCity: map['addressCity']?.toString(),
      addressOther: map['addressOther']?.toString(),
      idNumber: map['idNumber']?.toString(),
      issueDate: map['issueDate']?.toString(),
      expireDate: map['expireDate']?.toString(),
      myNumber: map['myNumber']?.toString(),
      hasIdFacePhoto: map['hasIdFacePhoto'] == true || map['idFacePhoto'] != null,
      hasDocumentFrontImage:
          map['hasDocumentFrontImage'] == true || map['documentImage'] != null,
      residenceCardType: map['residenceCardType']?.toString(),
      zipCode: map['zipCode']?.toString(),
      liquidDocumentType: map['liquidDocumentType']?.toString(),
      residenceCardInfoType: map['residenceCardInfoType']?.toString(),
      driversLicenseTypes:
          (map['driversLicenseTypes'] as List<dynamic>?)?.cast<String>(),
      driversLicenseConditions:
          (map['driversLicenseConditions'] as List<dynamic>?)?.cast<String>(),
      driversLicenseAcquisitionDates:
          (map['driversLicenseAcquisitionDates'] as List<dynamic>?)?.cast<String>(),
      residenceCardComprehensivePermission:
          map['residenceCardComprehensivePermission']?.toString(),
      residenceCardIndividualPermission:
          map['residenceCardIndividualPermission']?.toString(),

      // --- Nama (lanjutan) ---
      nameHalfWidthKana: map['nameHalfWidthKana']?.toString(),
      lastNameKanaCandidates:
          (map['lastNameKanaCandidates'] as List<dynamic>?)?.cast<String>(),
      lastNameHalfWidthKanaCandidates:
          (map['lastNameHalfWidthKanaCandidates'] as List<dynamic>?)?.cast<String>(),
      firstNameKanaCandidates:
          (map['firstNameKanaCandidates'] as List<dynamic>?)?.cast<String>(),
      firstNameHalfWidthKanaCandidates:
          (map['firstNameHalfWidthKanaCandidates'] as List<dynamic>?)?.cast<String>(),
      previousName: map['previousName']?.toString(),
      previousLastNameKanaCandidates:
          (map['previousLastNameKanaCandidates'] as List<dynamic>?)?.cast<String>(),
      previousLastNameHalfWidthKanaCandidates:
          (map['previousLastNameHalfWidthKanaCandidates'] as List<dynamic>?)
              ?.cast<String>(),
      aliasName: map['aliasName']?.toString(),

      // --- Alamat (lanjutan) ---
      addressModificationHistories:
          (map['addressModificationHistories'] as List<dynamic>?)?.cast<String>(),

      // --- Status tinggal ---
      movedAbroad: map['movedAbroad']?.toString(),
      plannedAbroadMoveDate: map['plannedAbroadMoveDate']?.toString(),
      japaneseForeignerJudgment: map['japaneseForeignerJudgment']?.toString(),
      pscName: map['pscName']?.toString(),
      pscNames: (map['pscNames'] as List<dynamic>?)?.cast<String>(),

      // --- Dokumen-integrated ---
      myNumberCardIntegratedDriverLicense:
          MyNumberCardIntegratedDriverLicense.fromMap(
        map['myNumberCardIntegratedDriverLicense'] as Map<String, dynamic>?,
      ),
      residenceDocumentGen2: ResidenceDocumentGen2.fromMap(
        map['residenceDocumentGen2'] as Map<String, dynamic>?,
      ),

      hasAddressImage: map['hasAddressImage'] == true,
    );
  }

  String get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : (address ?? '');
  }

  // Getters untuk display - return null kalau kosong (agar placeholder bisa tampil)
  String? get displayName => name;
  String? get displayNameKana => nameKana;
  String? get displayBirthday {
    if (birthday == null || birthday!.isEmpty) return null;
    if (birthday!.length == 8) {
      return '${birthday!.substring(0, 4)}-${birthday!.substring(4, 6)}-${birthday!.substring(6, 8)}';
    }
    return birthday;
  }
  String? get displayExpireDate {
    if (expireDate == null || expireDate!.isEmpty) return null;
    if (expireDate!.length == 8) {
      return '${expireDate!.substring(0, 4)}-${expireDate!.substring(4, 6)}-${expireDate!.substring(6, 8)}';
    }
    return expireDate;
  }
  String? get displayIssueDate {
    if (issueDate == null || issueDate!.isEmpty) return null;
    if (issueDate!.length == 8) {
      return '${issueDate!.substring(0, 4)}-${issueDate!.substring(4, 6)}-${issueDate!.substring(6, 8)}';
    }
    return issueDate;
  }
  String? get displaySex => sex?.name.toUpperCase();
  String? get displayIdNumber => idNumber;

  /// Izin tinggal individual — Gen-2 menyimpan datanya di [residenceDocumentGen2].
  String? get displayIndividualPermission =>
      residenceDocumentGen2?.individualPermission ?? residenceCardIndividualPermission;

  /// Izin tinggal menyeluruh — Gen-2 menyimpan datanya di [residenceDocumentGen2].
  String? get displayComprehensivePermission =>
      residenceDocumentGen2?.comprehensivePermissionCode ??
      residenceCardComprehensivePermission;

  /// Tipe info kartu Gen-2 (GENERAL / INFANT), null untuk kartu non Gen-2.
  String? get displayGen2InfoType => residenceDocumentGen2?.residenceDocumentGen2InfoType;

  /// True kalau kartu ini residence card Gen-2.
  bool get isResidenceDocumentGen2 =>
      residenceDocumentGen2 != null && !residenceDocumentGen2!.isEmpty;

  /// 個人番号 ditampilkan hanya 4 digit terakhir
  String? get displayMyNumber {
    final value = myNumber;
    if (value == null || value.isEmpty) return null;
    if (value.length <= 4) return '*******${value.substring(value.length - 4)}';
    return '*******${value.substring(value.length - 4)}';
  }
}

