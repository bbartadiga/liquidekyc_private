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

