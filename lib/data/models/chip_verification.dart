import '../../core/constant/liquid_constants.dart';
import '../../core/services/app_logger.dart';
import 'chip_data.dart';

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


class ChipVerificationResult {
  final ChipVerificationResultStatus status;
  final String? errorCode;
  final String? additionalDataTitle;
  final String? additionalDataMessage;
  final DocumentImage? documentImage;
  final AutoVerificationResult? autoVerificationResult;
  final LiquidChipDataModel? chipData;
  /// true = kartu yang dibaca dari chip tidak sesuai dokumen yang diminta
  final bool documentTypeMismatch;
  /// Sisa percobaan sebelum chip kartu terkunci (null = SDK nggak kirim).
  ///
  /// My Number Card punya contador percobaan di chip; habis habis kartu
  /// terkunci dan harus dibuka di kantor kecamatan.
  final int? attemptsRemainingUntilChipLocked;
  /// Jenis kredensial yang dicocokkan saat baca chip (PIN, 12-digit, dll).
  final String? chipErrorCredentialType;

  ChipVerificationResult({
    required this.status,
    this.errorCode,
    this.additionalDataTitle,
    this.additionalDataMessage,
    this.documentImage,
    this.autoVerificationResult,
    this.chipData,
    this.documentTypeMismatch = false,
    this.attemptsRemainingUntilChipLocked,
    this.chipErrorCredentialType,
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
      documentTypeMismatch: map?['documentTypeMismatch'] == true,
      attemptsRemainingUntilChipLocked:
          (map?['chipErrorData'] as Map?)?['attemptsRemainingUntilChipLocked'] as int?,
      chipErrorCredentialType:
          (map?['chipErrorData'] as Map?)?['credentialType'] as String?,
    );
  }

  bool get isSuccess => status == ChipVerificationResultStatus.success;
  bool get isCancelled => status == ChipVerificationResultStatus.userCancel;

  LiquidErrorCode get liquidError => LiquidErrorCode.fromCode(errorCode);

  String get userFriendlyMessage {
    final base = (additionalDataMessage != null && additionalDataMessage!.isNotEmpty)
        ? additionalDataMessage!
        : liquidError.userFriendlyMessage;

    // Error yang bisa bikin kartu fisik terkunci → wajib kasih tahu user
    // jumlah sisa percobaannya, supaya dia nggak asal retry.
    if (liquidError.canLockCard) {
      return '$base\n\n$lockWarning';
    }
    return base;
  }

  /// Peringatan risiko kunci kartu + sisa percobaan.
  String get lockWarning {
    final attempts = attemptsRemainingUntilChipLocked;
    final attemptsText = (attempts != null && attempts >= 0)
        ? 'Sisa percobaan: $attempts kali.'
        : 'Jumlah sisa percobaan tidak dilaporkan.';
    return 'Penting: kartu ini punya batas percobaan baca. $attemptsText '
        'Kalau habis, kartu terkunci dan hanya bisa dibuka di kantor kecamatan.';
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
      'attemptsRemainingUntilChipLocked': attemptsRemainingUntilChipLocked,
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
        final chipData = LiquidChipDataModel.fromMap(convertedMap);
        appLogger.i(
          '[ChipParse] doc=${chipData.liquidDocumentType ?? "-"} | '
          'card_type=${chipData.residenceCardType ?? "-"} | '
          'my_number=${chipData.displayMyNumber ?? "-"} | '
          'name=${chipData.name ?? "-"} | '
          'id_number=${chipData.idNumber ?? "-"} | '
          'expire=${chipData.expireDate ?? "-"} | '
          'drivers_license_types=${chipData.driversLicenseTypes?.join(",") ?? "-"}',
        );
        return chipData;
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
      case Sex.others:
        return 'Others';
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


extension ChipVerificationResultDebug on ChipVerificationResult {
  String toDebugString() {
    final buffer = StringBuffer();
    buffer.writeln('ChipVerificationResult {');
    buffer.writeln('  status: ${status.name}');
    buffer.writeln('  errorCode: $errorCode');
    buffer.writeln('  additionalDataTitle: $additionalDataTitle');
    buffer.writeln('  additionalDataMessage: $additionalDataMessage');
    buffer.writeln('  attemptsRemainingUntilChipLocked: $attemptsRemainingUntilChipLocked');
    buffer.writeln('  chipErrorCredentialType: $chipErrorCredentialType');
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
  final String? faceResult;
  final int? faceScore;
  final String? photoResult;
  final int? photoScore;
  final bool? passiveResult;

  AutoVerificationResult({
    required this.result,
    this.message,
    this.faceResult,
    this.faceScore,
    this.photoResult,
    this.photoScore,
    this.passiveResult,
  });

  factory AutoVerificationResult.fromMap(Map<String, dynamic>? map) {
    return AutoVerificationResult(
      result: AutoVerificationResultStatus.fromString(map?['result']),
      message: map?['message'] as String?,
      faceResult: map?['faceResult'] as String?,
      faceScore: (map?['faceScore'] as num?)?.toInt(),
      photoResult: map?['photoResult'] as String?,
      photoScore: (map?['photoScore'] as num?)?.toInt(),
      passiveResult: map?['passiveResult'] as bool?,
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

