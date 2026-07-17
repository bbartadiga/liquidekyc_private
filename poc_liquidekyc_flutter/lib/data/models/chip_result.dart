import '../../core/constant/liquid_constants.dart';
import '../../core/services/app_logger.dart';

enum ChipVerificationResultStatus {
  success,
  error,
  userCancel,
  unknown;

  static ChipVerificationResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return ChipVerificationResultStatus.success;
      case 'ERROR':
        return ChipVerificationResultStatus.error;
      case 'USER_CANCEL':
        return ChipVerificationResultStatus.userCancel;
      default:
        return ChipVerificationResultStatus.unknown;
    }
  }
}

enum ChipIdentificationResultStatus {
  success,
  error,
  userCancel,
  unknown;

  static ChipIdentificationResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return ChipIdentificationResultStatus.success;
      case 'ERROR':
        return ChipIdentificationResultStatus.error;
      case 'USER_CANCEL':
        return ChipIdentificationResultStatus.userCancel;
      default:
        return ChipIdentificationResultStatus.unknown;
    }
  }
}

enum Sex {
  male,
  female,
  unknown;

  static Sex fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MALE':
        return Sex.male;
      case 'FEMALE':
        return Sex.female;
      default:
        return Sex.unknown;
    }
  }
}

class ChipVerificationResult {
  final ChipVerificationResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;
  final DocumentImage? documentImage;
  final AutoVerificationResult? autoVerificationResult;
  final LiquidChipDataModel? chipData;

  ChipVerificationResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
    this.documentImage,
    this.autoVerificationResult,
    this.chipData,
  });

  factory ChipVerificationResult.fromMap(Map<String, dynamic>? map) {
    return ChipVerificationResult(
      status: ChipVerificationResultStatus.fromString(map?['resultStatus']),
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
      chipData: _parseChipData(map),
    );
  }

  bool get isSuccess => status == ChipVerificationResultStatus.success;
  bool get isCancelled => status == ChipVerificationResultStatus.userCancel;

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
    };
  }

  static LiquidChipDataModel? _parseChipData(Map<String, dynamic>? map) {
    if (map == null) return null;
    
    final possibleKeys = [
      'liquidChipData',
      'chipData', 
      'icCardData',
      'idChipData',
    ];
    
    for (final key in possibleKeys) {
      if (map[key] != null && map[key] is Map) {
        appLogger.i('[ChipParse] ✓ Found at key: $key');
        // Handle Map<Object?, Object?> → Map<String, dynamic>
        final rawMap = map[key] as Map;
        final convertedMap = <String, dynamic>{};
        for (final k in rawMap.keys) {
          final keyStr = k?.toString();
          if (keyStr != null) {
            convertedMap[keyStr] = rawMap[k];
          }
        }
        return LiquidChipDataModel.fromMap(convertedMap);
      }
    }
    
    appLogger.e('[ChipParse] ✗ Not found. Keys: ${map.keys.toList()}');
    return null;
  }
}

class ChipIdentificationResult {
  final ChipIdentificationResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;
  final String? municipalityName;
  final String? serialNumber;
  final String? myNumber;
  final String? name;
  final String? address;
  final String? dateOfBirth;
  final Sex? sex;

  ChipIdentificationResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
    this.municipalityName,
    this.serialNumber,
    this.myNumber,
    this.name,
    this.address,
    this.dateOfBirth,
    this.sex,
  });

  factory ChipIdentificationResult.fromMap(Map<String, dynamic>? map) {
    return ChipIdentificationResult(
      status:
          ChipIdentificationResultStatus.fromString(map?['resultStatus']),
      errorCode: map?['errorCode'] as String?,
      additionalDataTitle: map?['additionalDataTitle'] as String?,
      additionalDataMessage: map?['additionalDataMessage'] as String?,
      municipalityName: map?['municipalityName'] as String?,
      serialNumber: map?['serialNumber'] as String?,
      myNumber: map?['myNumber'] as String?,
      name: map?['name'] as String?,
      address: map?['address'] as String?,
      dateOfBirth: map?['dateOfBirth'] as String?,
      sex: Sex.fromString(map?['sex'] as String?),
    );
  }

  bool get isSuccess => status == ChipIdentificationResultStatus.success;
  bool get isCancelled => status == ChipIdentificationResultStatus.userCancel;

  LiquidErrorCode get liquidError => LiquidErrorCode.fromCode(errorCode);

  String get userFriendlyMessage {
    if (additionalDataMessage != null && additionalDataMessage!.isNotEmpty) {
      return additionalDataMessage!;
    }
    return liquidError.userFriendlyMessage;
  }

  String get sexDisplayName {
    switch (sex) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'resultStatus': status.name.toUpperCase(),
      'errorCode': errorCode,
      'municipalityName': municipalityName,
      'serialNumber': serialNumber,
      'myNumber': myNumber,
      'name': name,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'sex': sex?.name,
    };
  }

  @override
  String toString() {
    return 'ChipIdentificationResult(status: ${status.name}, name: $name, address: $address)';
  }
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
      hasIdFacePhoto: map['idFacePhoto'] != null,
      hasDocumentFrontImage: map['documentImage'] != null,
      residenceCardType: map['residenceCardType']?.toString(),
      zipCode: map['zipCode']?.toString(),
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
}

extension ChipVerificationResultDebug on ChipVerificationResult {
  String toDebugString() {
    final buffer = StringBuffer();
    buffer.writeln('ChipVerificationResult {');
    buffer.writeln('  status: ${status.name}');
    buffer.writeln('  errorCode: $errorCode');
    buffer.writeln('  additionalDataTitle: $additionalDataTitle');
    buffer.writeln('  additionalDataMessage: $additionalDataMessage');
    buffer.writeln('  documentImage: ${documentImage != null ? "present (${documentImage!.base64Data?.length ?? 0} chars)" : "null"}');
    if (autoVerificationResult != null) {
      buffer.writeln('  autoVerificationResult: {');
      buffer.writeln('    result: ${autoVerificationResult!.result.name}');
      buffer.writeln('    message: ${autoVerificationResult!.message}');
      buffer.writeln('  }');
    } else {
      buffer.writeln('  autoVerificationResult: null');
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}

class AutoVerificationResult {
  final AutoVerificationResultStatus result;
  final String? message;

  AutoVerificationResult({
    required this.result,
    this.message,
  });

  factory AutoVerificationResult.fromMap(Map<String, dynamic>? map) {
    return AutoVerificationResult(
      result: AutoVerificationResultStatus.fromString(map?['result']),
      message: map?['message'] as String?,
    );
  }
}

enum AutoVerificationResultStatus {
  pass,
  fail,
  notApplicable,
  unknown;

  static AutoVerificationResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PASS':
        return AutoVerificationResultStatus.pass;
      case 'FAIL':
        return AutoVerificationResultStatus.fail;
      case 'NOT_APPLICABLE':
        return AutoVerificationResultStatus.notApplicable;
      default:
        return AutoVerificationResultStatus.unknown;
    }
  }
}

class DocumentImage {
  final String? base64Data;

  DocumentImage({this.base64Data});

  factory DocumentImage.fromMap(Map<String, dynamic>? map) {
    return DocumentImage(
      base64Data: map?['data'] as String?,
    );
  }
}

class MynaIdentificationResult {
  final ChipIdentificationResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;
  final String? name;
  final String? address;
  final String? dateOfBirth;
  final Sex? sex;

  MynaIdentificationResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
    this.name,
    this.address,
    this.dateOfBirth,
    this.sex,
  });

  factory MynaIdentificationResult.fromMap(Map<String, dynamic>? map) {
    return MynaIdentificationResult(
      status:
          ChipIdentificationResultStatus.fromString(map?['resultStatus']),
      errorCode: map?['errorCode'] as String?,
      additionalDataTitle: map?['additionalDataTitle'] as String?,
      additionalDataMessage: map?['additionalDataMessage'] as String?,
      name: map?['name'] as String?,
      address: map?['address'] as String?,
      dateOfBirth: map?['dateOfBirth'] as String?,
      sex: Sex.fromString(map?['sex'] as String?),
    );
  }

  bool get isSuccess => status == ChipIdentificationResultStatus.success;
  bool get isCancelled => status == ChipIdentificationResultStatus.userCancel;

  LiquidErrorCode get liquidError => LiquidErrorCode.fromCode(errorCode);

  String get userFriendlyMessage {
    if (additionalDataMessage != null && additionalDataMessage!.isNotEmpty) {
      return additionalDataMessage!;
    }
    return liquidError.userFriendlyMessage;
  }

  Map<String, dynamic> toMap() {
    return {
      'resultStatus': status.name.toUpperCase(),
      'errorCode': errorCode,
      'name': name,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'sex': sex?.name,
    };
  }
}

class OcrResult {
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
  final String? issuingAuthority;
  final String? addressChanged;
  final String? nameChanged;
  final String? remarksExist;
  final String? employmentRestriction;
  final String? permittedDate;
  final String? kindOfPermission;
  final List<String>? driversLicenseTypes;

  OcrResult({
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
    this.issuingAuthority,
    this.addressChanged,
    this.nameChanged,
    this.remarksExist,
    this.employmentRestriction,
    this.permittedDate,
    this.kindOfPermission,
    this.driversLicenseTypes,
  });

  factory OcrResult.fromMap(Map<String, dynamic>? map) {
    return OcrResult(
      name: map?['name'] as String?,
      birthday: (map?['birthday'] ?? map?['dateOfBirth']) as String?,
      sex: map?['sex'] as String?,
      address: map?['address'] as String?,
      addressPref: map?['addressPref'] as String?,
      addressCity: map?['addressCity'] as String?,
      addressOther: map?['addressOther'] as String?,
      zipCode: map?['zipCode'] as String?,
      expireDate: (map?['expireDate'] ?? map?['expiryDate']) as String?,
      idNumber: (map?['idNumber'] ?? map?['documentNumber']) as String?,
      issueDate: map?['issueDate'] as String?,
      nationality: map?['nationality'] as String?,
      residentStatus: (map?['residentStatus'] ?? map?['residenceStatus']) as String?,
      stayPeriod: (map?['stayPeriod'] ?? map?['periodOfStay']) as String?,
      stayExpireDate: map?['stayExpireDate'] as String?,
      issuingAuthority: map?['issuingAuthority'] as String?,
      addressChanged: map?['addressChanged'] as String?,
      nameChanged: map?['nameChanged'] as String?,
      remarksExist: map?['remarksExist'] as String?,
      employmentRestriction: map?['employmentRestriction'] as String?,
      permittedDate: map?['permittedDate'] as String?,
      kindOfPermission: map?['kindOfPermission'] as String?,
      driversLicenseTypes: (map?['driversLicenseTypes'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthday': birthday,
      'sex': sex,
      'address': address,
      'addressPref': addressPref,
      'addressCity': addressCity,
      'addressOther': addressOther,
      'zipCode': zipCode,
      'expireDate': expireDate,
      'idNumber': idNumber,
      'issueDate': issueDate,
      'nationality': nationality,
      'residentStatus': residentStatus,
      'stayPeriod': stayPeriod,
      'stayExpireDate': stayExpireDate,
      'issuingAuthority': issuingAuthority,
      'addressChanged': addressChanged,
      'nameChanged': nameChanged,
      'remarksExist': remarksExist,
      'employmentRestriction': employmentRestriction,
      'permittedDate': permittedDate,
      'kindOfPermission': kindOfPermission,
      'driversLicenseTypes': driversLicenseTypes,
    };
  }

  String get dateOfBirth => birthday ?? '';
  String get expiryDate => expireDate ?? '';
  String get documentNumber => idNumber ?? '';
  String get residenceStatus => residentStatus ?? '';
  String get periodOfStay => stayPeriod ?? '';
}