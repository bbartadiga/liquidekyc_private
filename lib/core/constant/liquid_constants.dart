class LiquidConfig {
  static const String channelName = 'com.liquid.ekyc/channel';

  // ============================================================
  // MODE CONFIGURATION - GANTI TRUE/FALSE DISINI
  // ============================================================
  // DEBUG_MODE: 
  //   true  = mock response, no SDK call, no camera
  //   false = call actual SDK, camera works
  // BYPASS_BE:\
  //   true  = skip BE call, use hardcoded credentials
  //   false = call BE to get token (need BE accessible)
  // ============================================================
  static const bool DEBUG_MODE = false;
  static const bool BYPASS_BE = false;

  // ============================================================
  // ENVIRONMENT SWITCH
  //   false = STAGING (default)
  //   true  = PRODUCTION
  //
  // Catatan: 第2世代在留カード (Gen-2 Residence Card) BELUM bisa dites di
  // env staging. Sudah tersedia di env production.
  // Ref: "17. 2nd Generation Residence Card_Specified Residence Card/1. …対応のご案内.pdf"
  //      (IC読取方式: 正式版 2026年7〜8月頃提供予定)
  //
  // Kredensial production BELUM diisi — minta ke Liquid CS (cs@liquidinc.asia)
  // atau isi dari "18. APIKey and Credential for BNI" sheet (tab 本番環境).
  // ============================================================
  static const bool USE_PRODUCTION = false;

  // ---- STAGING ----
  // SDK API URL   : applicantsdk-api.stg-liquid-ekyc.com
  // Connector URL : https://connector-bni.stg-liquid-ekyc.com
  //   (app ini lewat proxy BNI: https://103.108.254.29:8066/inbound-liquid)
  static const String _stgUrl = 'https://applicantsdk-api.stg-liquid-ekyc.com';
  static const String _stgApiKey =
      'JDJhJDEwJFRIQTBRTXllRG9tdnNNVEx3dHlVcXV4YTdvUWRyczZpbTJNVkZkNFYuM1hlL0taWXlMSDVX';
  static const String _stgBeUrl = 'https://103.108.254.29:8066';
  static const String _stgConnectorApiKey =
      'JDJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD';

  // ---- PRODUCTION ---- (isi dari Liquid CS)
  static const String _prodUrl = 'https://applicantsdk-api.liquid-ekyc.com';
  static const String _prodApiKey = '';
  static const String _prodBeUrl = '';
  static const String _prodConnectorApiKey = '';

  static String get url => USE_PRODUCTION ? _prodUrl : _stgUrl;
  static String get apiKey => USE_PRODUCTION ? _prodApiKey : _stgApiKey;
  static String get beUrl => USE_PRODUCTION ? _prodBeUrl : _stgBeUrl;
  static String get connectorApiKey =>
      USE_PRODUCTION ? _prodConnectorApiKey : _stgConnectorApiKey;

  // Credentials - STAGING (BNI Staging Environment)
  //    applicantId/token di bawah ini HARDCODE & token hanya berlaku 90 menit
  //    (ref: 017 SDKApply API). Jangan dipakai sebagai sumber kebenaran —
  //    flow normal selalu ambil token baru dari BE saat user klik "Ambil Token".

  // ApplicantId & Token - dari backend (dynamic) atau set manual untuk dev
  static const String applicantId = '111902224425';
  static const String token = 'a35f3549a21cfa7150615e4fe5aa6b2bfcb8dbf7798a65d1a1ec400e96d4ee55';

  static const int minSdkVersion = 24;
  static const Duration networkTimeout = Duration(seconds: 90);

  static bool get isDebugMode => DEBUG_MODE;
  static bool get isRealMode => !DEBUG_MODE;
  static bool get isProduction => USE_PRODUCTION;
}

enum LiquidProcessingResultStatus {
  success,
  error,
  userCancel,
  communicationFailure,
  sessionTimeout,
  maintenance,
  termsDoNotAgree,
  unknown;

  static LiquidProcessingResultStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return LiquidProcessingResultStatus.success;
      case 'ERROR':
        return LiquidProcessingResultStatus.error;
      case 'USER_CANCEL':
        return LiquidProcessingResultStatus.userCancel;
      case 'COMMUNICATION_FAILURE':
        return LiquidProcessingResultStatus.communicationFailure;
      case 'SESSION_TIMEOUT':
        return LiquidProcessingResultStatus.sessionTimeout;
      case 'MAINTENANCE':
        return LiquidProcessingResultStatus.maintenance;
      case 'TERMS_DO_NOT_AGREE':
        return LiquidProcessingResultStatus.termsDoNotAgree;
      default:
        return LiquidProcessingResultStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case LiquidProcessingResultStatus.success:
        return 'Success';
      case LiquidProcessingResultStatus.error:
        return 'Error';
      case LiquidProcessingResultStatus.userCancel:
        return 'Cancelled by user';
      case LiquidProcessingResultStatus.communicationFailure:
        return 'Communication failed';
      case LiquidProcessingResultStatus.sessionTimeout:
        return 'Session expired';
      case LiquidProcessingResultStatus.maintenance:
        return 'Under maintenance';
      case LiquidProcessingResultStatus.termsDoNotAgree:
        return 'Terms not agreed';
      case LiquidProcessingResultStatus.unknown:
        return 'Unknown';
    }
  }
}

enum Nationality {
  indonesia,
  japan;

  String get displayName {
    switch (this) {
      case Nationality.indonesia:
        return 'Indonesia';
      case Nationality.japan:
        return 'Jepang';
    }
  }

  List<LiquidDocumentType> get allowedDocuments {
    switch (this) {
      case Nationality.indonesia:
        return [
          LiquidDocumentType.residenceCard,
          LiquidDocumentType.residenceDocumentGen2,
        ];
      case Nationality.japan:
        return [LiquidDocumentType.driverLicense, LiquidDocumentType.myNumberCard];
    }
  }
}

enum VerificationMethod {
  complyHo,
  complyHe,
  complyTo,
  complyChi,
  front,
  frontFace,
  frontBack,
  frontBackFace,
  read,
  readFace,
  readOffline;

  // Default untuk project ini: COMPLY_HE (IC + OCR + Face)
  static VerificationMethod get defaultMethod => VerificationMethod.complyHe;

  static VerificationMethod fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLY_HO':
        return VerificationMethod.complyHo;
      case 'COMPLY_HE':
        return VerificationMethod.complyHe;
      case 'COMPLY_TO':
        return VerificationMethod.complyTo;
      case 'COMPLY_CHI':
        return VerificationMethod.complyChi;
      case 'FRONT':
        return VerificationMethod.front;
      case 'FRONT_FACE':
        return VerificationMethod.frontFace;
      case 'FRONT_BACK':
        return VerificationMethod.frontBack;
      case 'FRONT_BACK_FACE':
        return VerificationMethod.frontBackFace;
      case 'READ':
        return VerificationMethod.read;
      case 'READ_FACE':
        return VerificationMethod.readFace;
      case 'READ_OFFLINE':
        return VerificationMethod.readOffline;
      default:
        return VerificationMethod.complyHo;
    }
  }

  String get value {
    switch (this) {
      case VerificationMethod.complyHo:
        return 'COMPLY_HO';
      case VerificationMethod.complyHe:
        return 'COMPLY_HE';
      case VerificationMethod.complyTo:
        return 'COMPLY_TO';
      case VerificationMethod.complyChi:
        return 'COMPLY_CHI';
      case VerificationMethod.front:
        return 'FRONT';
      case VerificationMethod.frontFace:
        return 'FRONT_FACE';
      case VerificationMethod.frontBack:
        return 'FRONT_BACK';
      case VerificationMethod.frontBackFace:
        return 'FRONT_BACK_FACE';
      case VerificationMethod.read:
        return 'READ';
      case VerificationMethod.readFace:
        return 'READ_FACE';
      case VerificationMethod.readOffline:
        return 'READ_OFFLINE';
    }
  }

  String get displayName {
    switch (this) {
      case VerificationMethod.complyHo:
        return 'Document + Face (Ho Method)';
      case VerificationMethod.complyHe:
        return 'IC + OCR + Face (He Method)';
      case VerificationMethod.complyTo:
        return 'Document Only (To Method)';
      case VerificationMethod.complyChi:
        return 'Document Only (Chi Method)';
      case VerificationMethod.front:
        return 'Front Document Only';
      case VerificationMethod.frontFace:
        return 'Front Document + Face';
      case VerificationMethod.frontBack:
        return 'Front + Back Document';
      case VerificationMethod.frontBackFace:
        return 'Front + Back Document + Face';
      case VerificationMethod.read:
        return 'IC Card Only (No Signature)';
      case VerificationMethod.readFace:
        return 'IC Card + Face (No Signature)';
      case VerificationMethod.readOffline:
        return 'IC Card Offline (No Signature)';
    }
  }

  bool get requiresDocument {
    return this == VerificationMethod.complyHo ||
        this == VerificationMethod.complyTo ||
        this == VerificationMethod.complyChi ||
        this == VerificationMethod.front ||
        this == VerificationMethod.frontFace ||
        this == VerificationMethod.frontBack ||
        this == VerificationMethod.frontBackFace;
  }

  bool get requiresIcCard {
    return this == VerificationMethod.complyHe ||
        this == VerificationMethod.read ||
        this == VerificationMethod.readFace ||
        this == VerificationMethod.readOffline;
  }

  bool get requiresFace {
    return this == VerificationMethod.complyHo ||
        this == VerificationMethod.complyHe ||
        this == VerificationMethod.frontFace ||
        this == VerificationMethod.frontBackFace ||
        this == VerificationMethod.readFace;
  }

  // COMPLY_HE flow: IC Card FIRST, then Face (NO document scan)
  bool get isComplyHeMethod {
    return this == VerificationMethod.complyHe;
  }

  // Get verification order for COMPLY_HE: IC → Face
  List<String> get verificationOrder {
    if (isComplyHeMethod) {
      return ['icCard', 'face'];
    }
    // Default order for other methods: Document → Face → IC
    final List<String> order = [];
    if (requiresDocument) order.add('document');
    if (requiresIcCard) order.add('icCard');
    if (requiresFace) order.add('face');
    return order;
  }
}

enum LiquidDocumentType {
  driverLicense,
  myNumberCard,
  myNumberCardWithMyNumber,
  myNumberCardIntegratedDriverLicense,
  passport,
  passportAllPeriods,
  nonJapanesePassport,
  residenceCard,
  specialPermanentResidentCertificate,
  residenceDocumentGen2,
  specifiedResidenceCard,
  specifiedSpecialPermanentResidentCertificate,
  healthInsuranceCard,
  employeeIdCard,
  pensionBook,
  drivingHistoryCard,
  basicPensionNumberNotification,
  basicResidentRegistrationCard;

  // Default untuk project ini: Residence Card
  static LiquidDocumentType get defaultType => LiquidDocumentType.residenceCard;

  static LiquidDocumentType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'DRIVER_LICENSE':
        return LiquidDocumentType.driverLicense;
      case 'MY_NUMBER_CARD':
        return LiquidDocumentType.myNumberCard;
      case 'MY_NUMBER_CARD_WITH_MY_NUMBER':
        return LiquidDocumentType.myNumberCardWithMyNumber;
      case 'MY_NUMBER_CARD_INTEGRATED_DRIVER_LICENSE':
        return LiquidDocumentType.myNumberCardIntegratedDriverLicense;
      case 'PASSPORT':
        return LiquidDocumentType.passport;
      case 'PASSPORT_ALL_PERIODS':
        return LiquidDocumentType.passportAllPeriods;
      case 'NON_JAPANESE_PASSPORT':
        return LiquidDocumentType.nonJapanesePassport;
      case 'RESIDENCE_CARD':
        return LiquidDocumentType.residenceCard;
      case 'SPECIAL_PERMANENT_RESIDENT_CERTIFICATE':
        return LiquidDocumentType.specialPermanentResidentCertificate;
      case 'RESIDENCE_DOCUMENT_GEN2':
        return LiquidDocumentType.residenceDocumentGen2;
      case 'SPECIFIED_RESIDENCE_CARD':
        return LiquidDocumentType.specifiedResidenceCard;
      case 'SPECIFIED_SPECIAL_PERMANENT_RESIDENT_CERTIFICATE':
        return LiquidDocumentType.specifiedSpecialPermanentResidentCertificate;
      case 'HEALTH_INSURANCE_CARD':
        return LiquidDocumentType.healthInsuranceCard;
      case 'EMPLOYEE_ID_CARD':
        return LiquidDocumentType.employeeIdCard;
      case 'PENSION_BOOK':
        return LiquidDocumentType.pensionBook;
      case 'DRIVING_HISTORY_CARD':
        return LiquidDocumentType.drivingHistoryCard;
      case 'BASIC_PENSION_NUMBER_NOTIFICATION':
        return LiquidDocumentType.basicPensionNumberNotification;
      case 'BASIC_RESIDENT_REGISTRATION_CARD':
        return LiquidDocumentType.basicResidentRegistrationCard;
      default:
        return LiquidDocumentType.defaultType;
    }
  }

  /// RESIDENCE_DOCUMENT_GEN2 bersifat payung: SDK membaca 4 jenis kartu
  /// (在留カード / 特別永住者証明書 / 第2世代在留カード / 第2世代特別永住者証明書).
  /// Selain itu harus cocok persis.
  bool isCompatibleWith(LiquidDocumentType actual) {
    if (this == actual) return true;
    if (this == LiquidDocumentType.residenceDocumentGen2) {
      return actual == LiquidDocumentType.residenceCard ||
          actual == LiquidDocumentType.specialPermanentResidentCertificate ||
          actual == LiquidDocumentType.residenceDocumentGen2;
    }
    return false;
  }

  String get value {
    switch (this) {
      case LiquidDocumentType.driverLicense:
        return 'DRIVER_LICENSE';
      case LiquidDocumentType.myNumberCard:
        return 'MY_NUMBER_CARD';
      case LiquidDocumentType.myNumberCardWithMyNumber:
        return 'MY_NUMBER_CARD_WITH_MY_NUMBER';
      case LiquidDocumentType.myNumberCardIntegratedDriverLicense:
        return 'MY_NUMBER_CARD_INTEGRATED_DRIVER_LICENSE';
      case LiquidDocumentType.passport:
        return 'PASSPORT';
      case LiquidDocumentType.passportAllPeriods:
        return 'PASSPORT_ALL_PERIODS';
      case LiquidDocumentType.nonJapanesePassport:
        return 'NON_JAPANESE_PASSPORT';
      case LiquidDocumentType.residenceCard:
        return 'RESIDENCE_CARD';
      case LiquidDocumentType.specialPermanentResidentCertificate:
        return 'SPECIAL_PERMANENT_RESIDENT_CERTIFICATE';
      case LiquidDocumentType.residenceDocumentGen2:
        return 'RESIDENCE_DOCUMENT_GEN2';
      case LiquidDocumentType.specifiedResidenceCard:
        return 'SPECIFIED_RESIDENCE_CARD';
      case LiquidDocumentType.specifiedSpecialPermanentResidentCertificate:
        return 'SPECIFIED_SPECIAL_PERMANENT_RESIDENT_CERTIFICATE';
      case LiquidDocumentType.healthInsuranceCard:
        return 'HEALTH_INSURANCE_CARD';
      case LiquidDocumentType.employeeIdCard:
        return 'EMPLOYEE_ID_CARD';
      case LiquidDocumentType.pensionBook:
        return 'PENSION_BOOK';
      case LiquidDocumentType.drivingHistoryCard:
        return 'DRIVING_HISTORY_CARD';
      case LiquidDocumentType.basicPensionNumberNotification:
        return 'BASIC_PENSION_NUMBER_NOTIFICATION';
      case LiquidDocumentType.basicResidentRegistrationCard:
        return 'BASIC_RESIDENT_REGISTRATION_CARD';
    }
  }

  String get displayName {
    switch (this) {
      case LiquidDocumentType.driverLicense:
        return 'Driver\'s License';
      case LiquidDocumentType.myNumberCard:
        return 'My Number Card';
      case LiquidDocumentType.myNumberCardWithMyNumber:
        return 'My Number Card (+ My Number)';
      case LiquidDocumentType.myNumberCardIntegratedDriverLicense:
        return 'My Number Card (+ License)';
      case LiquidDocumentType.passport:
        return 'Passport (Before Feb 2020)';
      case LiquidDocumentType.passportAllPeriods:
        return 'Passport (All Periods)';
      case LiquidDocumentType.nonJapanesePassport:
        return 'Foreign Passport';
      case LiquidDocumentType.residenceCard:
        return 'Residence Card';
      case LiquidDocumentType.specialPermanentResidentCertificate:
        return 'Special Permanent Resident Certificate';
      case LiquidDocumentType.residenceDocumentGen2:
        return 'Residence Card (Gen-2 / 第2世代在留カード等)';
      case LiquidDocumentType.specifiedResidenceCard:
        return 'Specified Residence Card';
      case LiquidDocumentType.specifiedSpecialPermanentResidentCertificate:
        return 'Specified Special Permanent Resident Certificate';
      case LiquidDocumentType.healthInsuranceCard:
        return 'Health Insurance Card';
      case LiquidDocumentType.employeeIdCard:
        return 'Employee ID Card';
      case LiquidDocumentType.pensionBook:
        return 'Pension Book';
      case LiquidDocumentType.drivingHistoryCard:
        return 'Driving History Card';
      case LiquidDocumentType.basicPensionNumberNotification:
        return 'Basic Pension Number Notification';
      case LiquidDocumentType.basicResidentRegistrationCard:
        return 'Basic Resident Registration Card';
    }
  }
}

enum FaceVerificationType {
  active,
  passive;

  static FaceVerificationType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PASSIVE':
        return FaceVerificationType.passive;
      case 'ACTIVE':
      default:
        return FaceVerificationType.active;
    }
  }

  String get value {
    switch (this) {
      case FaceVerificationType.active:
        return 'ACTIVE';
      case FaceVerificationType.passive:
        return 'PASSIVE';
    }
  }

  String get displayName {
    switch (this) {
      case FaceVerificationType.active:
        return 'Active Detection (Mouth movement + Flash)';
      case FaceVerificationType.passive:
        return 'Passive Detection (No action required)';
    }
  }
}

enum DisplayLanguage {
  auto,
  japanese,
  english,
  vietnamese,
  indonesian,
  simplifiedChinese,
  portuguese,
  korean,
  nepali,
  burmese,
  centralKhmer,
  mongolian,
  malay,
  thai;

  static DisplayLanguage fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'JAPANESE':
        return DisplayLanguage.japanese;
      case 'ENGLISH':
        return DisplayLanguage.english;
      case 'VIETNAMESE':
        return DisplayLanguage.vietnamese;
      case 'INDONESIAN':
        return DisplayLanguage.indonesian;
      case 'SIMPLIFIED_CHINESE':
        return DisplayLanguage.simplifiedChinese;
      case 'PORTUGUESE':
        return DisplayLanguage.portuguese;
      case 'KOREAN':
        return DisplayLanguage.korean;
      case 'NEPALI':
        return DisplayLanguage.nepali;
      case 'BURMESE':
        return DisplayLanguage.burmese;
      case 'CENTRAL_KHMER':
        return DisplayLanguage.centralKhmer;
      case 'MONGOLIAN':
        return DisplayLanguage.mongolian;
      case 'MALAY':
        return DisplayLanguage.malay;
      case 'THAI':
        return DisplayLanguage.thai;
      default:
        return DisplayLanguage.auto;
    }
  }

  String get value {
    switch (this) {
      case DisplayLanguage.auto:
        return 'AUTO';
      case DisplayLanguage.japanese:
        return 'JAPANESE';
      case DisplayLanguage.english:
        return 'ENGLISH';
      case DisplayLanguage.vietnamese:
        return 'VIETNAMESE';
      case DisplayLanguage.indonesian:
        return 'INDONESIAN';
      case DisplayLanguage.simplifiedChinese:
        return 'SIMPLIFIED_CHINESE';
      case DisplayLanguage.portuguese:
        return 'PORTUGUESE';
      case DisplayLanguage.korean:
        return 'KOREAN';
      case DisplayLanguage.nepali:
        return 'NEPALI';
      case DisplayLanguage.burmese:
        return 'BURMESE';
      case DisplayLanguage.centralKhmer:
        return 'CENTRAL_KHMER';
      case DisplayLanguage.mongolian:
        return 'MONGOLIAN';
      case DisplayLanguage.malay:
        return 'MALAY';
      case DisplayLanguage.thai:
        return 'THAI';
    }
  }

  String get displayName {
    switch (this) {
      case DisplayLanguage.auto:
        return 'Auto (Device setting)';
      case DisplayLanguage.japanese:
        return 'Japanese';
      case DisplayLanguage.english:
        return 'English';
      case DisplayLanguage.vietnamese:
        return 'Vietnamese';
      case DisplayLanguage.indonesian:
        return 'Indonesian';
      case DisplayLanguage.simplifiedChinese:
        return 'Simplified Chinese';
      case DisplayLanguage.portuguese:
        return 'Portuguese';
      case DisplayLanguage.korean:
        return 'Korean';
      case DisplayLanguage.nepali:
        return 'Nepali';
      case DisplayLanguage.burmese:
        return 'Burmese';
      case DisplayLanguage.centralKhmer:
        return 'Khmer';
      case DisplayLanguage.mongolian:
        return 'Mongolian';
      case DisplayLanguage.malay:
        return 'Malay';
      case DisplayLanguage.thai:
        return 'Thai';
    }
  }
}

enum KycStep {
  idle,
  initializing,
  termsOfUse,
  documentScan,
  icCardRead,
  faceScan,
  activating,
  completed,
  error;

  String get displayName {
    switch (this) {
      case KycStep.idle:
        return 'Ready';
      case KycStep.initializing:
        return 'Initializing...';
      case KycStep.termsOfUse:
        return 'Accept Terms';
      case KycStep.documentScan:
        return 'Scanning Document';
      case KycStep.icCardRead:
        return 'Reading IC Card';
      case KycStep.faceScan:
        return 'Capturing Face';
      case KycStep.activating:
        return 'Activating...';
      case KycStep.completed:
        return 'Completed';
      case KycStep.error:
        return 'Error';
    }
  }
}

// ============================================================
// ============================================================
// LIQUID SDK ERROR CODES (v1.45.0)
// & BE COMMON ERROR CODES (G06 v1.3.0)
// ============================================================
enum LiquidErrorCode {
  // ---- Session & Token Errors ----
  sessionTimeout('SE10022', 'Session expired after 90 minutes'),
  invalidToken('SE10001', 'Invalid Token'),
  screenTimeout('SE10021', 'Screen timeout - device inactive'),

  // ---- Camera Errors ----
  cameraDenied('SE10011', 'Camera access denied'),
  cameraNotAllowed('SE10012', 'Camera not allowed when SDK started'),

  // ---- IC Chip Errors ----
  icChipLocked('SE20001', 'IC Chip locked - PIN wrong multiple times'),
  incorrectPin('SE20015', 'Incorrect PIN'),
  pinErrorExceeded('SE20005', 'Pin error count exceeded'),
  icChipReadError('SE21001', 'IC Chip could not be read'),
  icChipUnusual('SE21011', 'IC chip has unusual updated information'),
  under16YearsOld('SE21101', 'Card belongs to person under 16 years old'),
  chipExpired('SE21205', 'Invalid chip - expired'),
  nfcOff('SE22001', 'NFC setting is turned off'),
  movingCard('SE22051', 'Moving card away during reading'),
  externalCharImages('SE23001', 'Card has more than 7 external characters'),

  // ---- JPKI & Mynaportal Errors ----
  jpkiRejected('SE25001', 'Public Certifications rejected - certificate revoked or identity changed'),
  jpkiError('SE25011', 'JPKI error - fake card or manipulated communication'),
  mynaportalNotInstalled('SE26000', 'Mynaportal application not installed'),
  mynaportalError('SE26201', 'Unknown error in Mynaportal application'),
  invalidDateOfBirth('SE91025', 'Invalid date of birth format'),

  // ---- Special Feature Errors ----
  mynaIntegrated('SE27001', 'MyNumber integrated with Driving History Certificate'),
  mynaLicenseExpired('SE27205', 'MyNa Driver\'s License has expired'),
  appleWalletNotAvailable('SE28001', 'National Identity Card on iPhone cannot be used'),
  iosVersionIssue('SE28010', 'iOS version not supported (need iOS 18.5+)'),
  biometricNotSupported('SE28011', 'Touch ID and Face ID not supported'),

  // ---- Communication Errors ----
  communicationFailure('SE05001', 'Communication failure - network error'),
  serverError('SE05002', 'Server error'),
  
  // OCR Errors
  ocrInProgress('SE70001', 'OCR in progress - please wait'),
  ocrUnsupported('SE71001', 'OCR not supported for this process'),
  
  // User Actions
  userCancel('SE80001', 'Cancelled by user'),
  
  // Implementation Errors
  implementationError('SE90001', 'Implementation error - called before initialization'),
  invalidArguments('SE90002', 'Invalid arguments passed'),
  invalidArgumentsBase64('SE90004', 'Arguments must be in BASE64 format'),
  operatorNotRegistered('SE90005', 'Application not registered in white list for JPKI'),
  multiWindowNotSupported('SE90006', 'SDK not available in multi-window mode'),
  termsNotAgreed('SE60001', 'Terms do not agree before activation'),
  
  // Device Errors
  cameraUnsupported('SE99991', 'Device not supported - camera issue'),
  deviceUnsupported('SE99999', 'User\'s device is unsupported'),
  iosCameraError('SE91029', 'Unable to use camera on iOS device'),
  
  // Document Errors
  documentScanTimeout('SE90003', 'Document scan failed - quality too low or timeout'),
  
  // Maintenance
  serverMaintenance('SE10002', 'Server under maintenance'),
  
  // Undefined
  undefinedError('SE90000', 'Undefined error'),

  // ============================================================
  // BE Common Error Codes (G06 v1.3.0) — Connector API errors
  // ============================================================
  beInvalidRequest('CE09999', 'BE: Invalid request parameters'),
  beAuthError('CE02401', 'BE: API authentication error (Invalid API Key)'),
  beApiNotAllowed('CE00023', 'BE: API cannot be used due to business settings'),
  beApplicantNotFound('CE00001', 'BE: Applicant ID is not found'),
  beApplicantAlreadyUsed('CE00002', 'BE: Specified Applicant ID is already used'),
  beCannotResubmit('CE00003', 'BE: Cannot resubmit due to current application status'),
  beKycIncomplete('CE00004', 'BE: KYC operation has not been completed yet'),
  beApplicationIncompleteOrExpired('CE00005', 'BE: Application incomplete or expired'),
  beKycResultRegistered('CE00006', 'BE: KYC result is already registered'),
  bePhotoNotCollected('CE00007', 'BE: Photo collection is not done'),
  beKycAppNotCompleted('CE00008', 'BE: KYC application is not completed yet'),
  beKycOperationInProgress('CE00009', 'BE: KYC operation is in progress'),
  beAppExpired('CE00011', 'BE: KYC application has expired (URL expired)'),
  beUnacceptableIdDocument('CE00012', 'BE: Unacceptable ID document type'),
  beOcrOrVerificationNotRun('CE00017', 'BE: OCR or verification has not been run'),
  beApplicantInfoDuplicate('CE00018', 'BE: Application info cannot be registered to the Applicant ID'),
  beNoResponseValue('CE00019', 'BE: ID document with no response value'),
  beWebApplicantId('CE00021', 'BE: Applicant ID is for WEB (not for SDK)'),
  beNoImageResponse('CE00022', 'BE: Image number with no response value'),
  beUnacceptableRegion('CE00026', 'BE: Unacceptable region code'),
  beIncorrectRedirectUrl('CE00027', 'BE: Incorrect redirect URL'),
  beAdditionalDocNoResponse('CE00028', 'BE: Additional document without a response value'),
  beMyNumberScanPending('CE00029', 'BE: My number scanning is not completed yet'),
  beAuthenticityMethodNotAllowed('CE00030', 'BE: Authenticity methods for personal appearance not available'),
  bePfDuplicateUserId('CE00031', 'BE: Duplicate user ID for KYC by PF company'),
  beApplicationInfoNotRegistered('CE00032', 'BE: No application information registered'),
  beMethodNotAllowed('CE09405', 'BE: Method not allowed'),
  beSystemMaintenance('CE01000', 'BE: System in maintenance'),

  // Unknown
  unknown('', 'Unknown Error');

  final String code;
  final String description;

  const LiquidErrorCode(this.code, this.description);

  static LiquidErrorCode fromCode(String? errorCode) {
    if (errorCode == null || errorCode.isEmpty) {
      return LiquidErrorCode.unknown;
    }
    for (final error in values) {
      if (error.code == errorCode) {
        return error;
      }
    }
    return LiquidErrorCode.unknown;
  }

  String get userFriendlyMessage {
    switch (this) {
      case LiquidErrorCode.sessionTimeout:
        return 'Session expired after 90 minutes.';
      case LiquidErrorCode.invalidToken:
        return 'Token is invalid.';
      case LiquidErrorCode.screenTimeout:
        return 'Screen inactive for 10 minutes. Restart verification.';
      case LiquidErrorCode.cameraDenied:
        return 'Camera access denied. Enable camera permission in settings.';
      case LiquidErrorCode.cameraNotAllowed:
        return 'Camera not allowed when SDK started. Change device settings.';
      case LiquidErrorCode.icChipLocked:
        return 'IC Chip locked. Must be unlocked at relevant office.';
      case LiquidErrorCode.incorrectPin:
        return 'PIN entered is incorrect.';
      case LiquidErrorCode.pinErrorExceeded:
        return 'PIN error count exceeded.';
      case LiquidErrorCode.icChipReadError:
        return 'IC Chip could not be read.';
      case LiquidErrorCode.icChipUnusual:
        return 'IC Chip has unusual updated information not supported.';
      case LiquidErrorCode.under16YearsOld:
        return 'Card belongs to person under 16 years old.';
      case LiquidErrorCode.chipExpired:
        return 'IC Chip has expired.';
      case LiquidErrorCode.nfcOff:
        return 'NFC setting is turned off. Enable NFC.';
      case LiquidErrorCode.movingCard:
        return 'Card moved during reading. Hold card steady.';
      case LiquidErrorCode.externalCharImages:
        return 'Card has more than 7 external characters.';
      case LiquidErrorCode.jpkiRejected:
        return 'Digital certificate rejected or identity changed.';
      case LiquidErrorCode.jpkiError:
        return 'JPKI error - fake card or manipulated communication.';
      case LiquidErrorCode.mynaportalNotInstalled:
        return 'Mynaportal application not found.';
      case LiquidErrorCode.mynaportalError:
        return 'Error in Mynaportal application.';
      case LiquidErrorCode.invalidDateOfBirth:
        return 'Date of birth format is invalid.';
      case LiquidErrorCode.mynaIntegrated:
        return 'MyNumber integrated with Driving History Certificate.';
      case LiquidErrorCode.mynaLicenseExpired:
        return 'MyNa Driver\'s License has expired.';
      case LiquidErrorCode.appleWalletNotAvailable:
        return 'Card not added to Apple Wallet or has expired.';
      case LiquidErrorCode.iosVersionIssue:
        return 'iOS version not supported. Requires iOS 18.5+.';
      case LiquidErrorCode.biometricNotSupported:
        return 'Device does not have required biometric.';
      case LiquidErrorCode.communicationFailure:
        return 'Communication failure. Try in place with better signal.';
      case LiquidErrorCode.serverError:
        return 'Server error. Try again later.';
      case LiquidErrorCode.ocrInProgress:
        return 'OCR process in progress.';
      case LiquidErrorCode.ocrUnsupported:
        return 'OCR not supported for this process.';
      case LiquidErrorCode.userCancel:
        return 'Verification cancelled by user.';
      case LiquidErrorCode.implementationError:
        return 'System error - SDK not properly initialized.';
      case LiquidErrorCode.invalidArguments:
        return 'Invalid arguments passed.';
      case LiquidErrorCode.invalidArgumentsBase64:
        return 'Arguments must be in BASE64 format.';
      case LiquidErrorCode.operatorNotRegistered:
        return 'Application not registered in JPKI white list.';
      case LiquidErrorCode.multiWindowNotSupported:
        return 'SDK not available in multi-window mode.';
      case LiquidErrorCode.termsNotAgreed:
        return 'Terms and conditions not agreed.';
      case LiquidErrorCode.cameraUnsupported:
        return 'Device not supported due to camera issue.';
      case LiquidErrorCode.deviceUnsupported:
        return 'Device not supported.';
      case LiquidErrorCode.iosCameraError:
        return 'iOS camera error. Try restarting device.';
      case LiquidErrorCode.documentScanTimeout:
        return 'Document scan timeout or quality too low.';
      case LiquidErrorCode.serverMaintenance:
        return 'Server under maintenance.';
      case LiquidErrorCode.beInvalidRequest:
        return 'Invalid request sent to server.';
      case LiquidErrorCode.beAuthError:
        return 'BE API key authentication failed.';
      case LiquidErrorCode.beApiNotAllowed:
        return 'This API is not enabled for your account.';
      case LiquidErrorCode.beApplicantNotFound:
        return 'Applicant ID not found in server.';
      case LiquidErrorCode.beApplicantAlreadyUsed:
        return 'Applicant ID is already in use.';
      case LiquidErrorCode.beCannotResubmit:
        return 'Cannot re-apply — current application is in operational state.';
      case LiquidErrorCode.beKycIncomplete:
        return 'KYC operation has not been completed. Wait or restart.';
      case LiquidErrorCode.beApplicationIncompleteOrExpired:
        return 'Application is incomplete or expired.';
      case LiquidErrorCode.beKycResultRegistered:
        return 'KYC result is already registered for this applicant.';
      case LiquidErrorCode.bePhotoNotCollected:
        return 'Photos have not been collected yet.';
      case LiquidErrorCode.beKycAppNotCompleted:
        return 'KYC application has not been completed yet.';
      case LiquidErrorCode.beKycOperationInProgress:
        return 'KYC operation is in progress. Please wait.';
      case LiquidErrorCode.beAppExpired:
        return 'Application URL has expired. Restart verification.';
      case LiquidErrorCode.beUnacceptableIdDocument:
        return 'ID document type not supported for your account.';
      case LiquidErrorCode.beOcrOrVerificationNotRun:
        return 'OCR or verification has not been run yet.';
      case LiquidErrorCode.beApplicantInfoDuplicate:
        return 'Application info is already registered for this applicant.';
      case LiquidErrorCode.beNoResponseValue:
        return 'ID document has no response data available.';
      case LiquidErrorCode.beWebApplicantId:
        return 'Applicant ID is for WEB, not SDK.';
      case LiquidErrorCode.beNoImageResponse:
        return 'Image number has no response value.';
      case LiquidErrorCode.beUnacceptableRegion:
        return 'Region code not accepted for this organization.';
      case LiquidErrorCode.beIncorrectRedirectUrl:
        return 'Redirect URL does not match allowed FQDN.';
      case LiquidErrorCode.beAdditionalDocNoResponse:
        return 'Additional document has no response value.';
      case LiquidErrorCode.beMyNumberScanPending:
        return 'My Number scanning is still in progress.';
      case LiquidErrorCode.beAuthenticityMethodNotAllowed:
        return 'Authenticity method not allowed for this verification type.';
      case LiquidErrorCode.bePfDuplicateUserId:
        return 'Duplicate user ID detected for PF provider.';
      case LiquidErrorCode.beApplicationInfoNotRegistered:
        return 'Application info has not been registered yet.';
      case LiquidErrorCode.beMethodNotAllowed:
        return 'HTTP method not allowed for this endpoint.';
      case LiquidErrorCode.beSystemMaintenance:
        return 'BE server is under maintenance. Try later.';
      case LiquidErrorCode.undefinedError:
        return 'Undefined error occurred.';
      case LiquidErrorCode.unknown:
        return 'Unknown error occurred.';
    }
  }
}