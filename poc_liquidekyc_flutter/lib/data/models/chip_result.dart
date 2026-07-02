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
        return LiquidChipDataModel.fromMap(map[key] as Map<String, dynamic>);
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
    return LiquidChipDataModel(
      name: map?['name'] as String?,
      nameKana: map?['nameKana'] as String?,
      birthday: map?['birthday'] as String?,
      sex: Sex.fromString(map?['sex'] as String?),
      address: map?['address'] as String?,
      addressPref: map?['addressPref'] as String?,
      addressCity: map?['addressCity'] as String?,
      addressOther: map?['addressOther'] as String?,
      idNumber: map?['idNumber'] as String?,
      issueDate: map?['issueDate'] as String?,
      expireDate: map?['expireDate'] as String?,
      myNumber: map?['myNumber'] as String?,
      hasIdFacePhoto: map?['idFacePhoto'] != null,
      hasDocumentFrontImage: map?['documentImage'] != null,
      residenceCardType: map?['residenceCardType'] as String?,
      zipCode: map?['zipCode'] as String?,
    );
  }

  String get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : address ?? '-';
  }

  String get displayName => name ?? '-';
  String get displayNameKana => nameKana ?? '-';
  String get displayBirthday => _formatDate(birthday);
  String get displayExpireDate => _formatDate(expireDate);
  String get displayIssueDate => _formatDate(issueDate);
  String get displaySex => sex?.name.toUpperCase() ?? '-';
  String get displayIdNumber => idNumber ?? '-';

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    if (date.length == 8) {
      return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
    }
    return date;
  }
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
  final String? nameKana;
  final String? address;
  final String? dateOfBirth;
  final String? expiryDate;
  final String? documentNumber;
  final String? issueDate;
  final Sex? sex;
  final String? residenceStatus;
  final String? periodOfStay;

  OcrResult({
    this.name,
    this.nameKana,
    this.address,
    this.dateOfBirth,
    this.expiryDate,
    this.documentNumber,
    this.issueDate,
    this.sex,
    this.residenceStatus,
    this.periodOfStay,
  });

  factory OcrResult.fromMap(Map<String, dynamic>? map) {
    return OcrResult(
      name: map?['name'] as String?,
      nameKana: map?['nameKana'] as String?,
      address: map?['address'] as String?,
      dateOfBirth: map?['dateOfBirth'] as String?,
      expiryDate: map?['expiryDate'] as String?,
      documentNumber: map?['documentNumber'] as String?,
      issueDate: map?['issueDate'] as String?,
      sex: Sex.fromString(map?['sex'] as String?),
      residenceStatus: map?['residenceStatus'] as String?,
      periodOfStay: map?['periodOfStay'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameKana': nameKana,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'expiryDate': expiryDate,
      'documentNumber': documentNumber,
      'issueDate': issueDate,
      'sex': sex?.name,
      'residenceStatus': residenceStatus,
      'periodOfStay': periodOfStay,
    };
  }
}