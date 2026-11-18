enum LiquidErrorCode {
  // ---- Session & Token Errors ----
  sessionTimeout('SE10022', 'Session expired after 90 minutes'),
  invalidToken('SE10001', 'Invalid Token'),
  screenTimeout('SE10021', 'Screen timeout - device inactive'),

  // ---- Camera Errors ----
  cameraDenied('SE10011', 'Camera access denied'),
  cameraNotAllowed('SE10012', 'Camera not allowed when SDK started'),

  // ---- IC Chip Errors ----
  // Mapping kode <-> status mengikuti Liquid SDK 1.47.0
  // (ResultHandler -> ChipVerificationResultStatus). Jangan diubah tanpa
  // cek SDK: user lihat pesan sesuai kode yang dikirim server.
  icChipLocked('SE20001', 'IC Chip locked - must be unlocked at the relevant office'),
  pinErrorExceeded('SE20005', 'PIN / credential mismatch - limited attempts before the card locks', aliases: ['SE20011']),
  incorrectPin('SE20015', 'PIN or credential entered does not match the card'),
  icChipSpecial('SE21001', 'Special residence card type cannot be read'),
  icChipUnusual('SE21011', 'IC chip has unusual updated information'),
  under16YearsOld('SE21101', 'Card belongs to person under 16 years old'),
  icChipSpecialResidence('SE21102', 'Special residence card cannot be read', aliases: ['SE21103']),
  icChipVerificationFailure('SE21201', 'IC chip verification failed', aliases: ['SE21202', 'SE21203']),
  chipExpired('SE21205', 'Invalid chip - expired'),
  nfcOff('SE22001', 'NFC setting is turned off'),
  icChipReadError('SE22051', 'IC Chip could not be read - card may have moved or not been placed correctly', aliases: ['SE22052']),
  externalCharImages('SE23001', 'Card has more than 7 external characters'),

  // ---- JPKI & Mynaportal Errors ----
  jpkiRejected('SE25001', 'Public Certifications rejected - certificate revoked or identity changed'),
  jpkiError('SE25011', 'JPKI error - fake card or manipulated communication'),
  mynaportalNotInstalled('SE26000', 'Mynaportal application not installed'),
  mynaportalError('SE26201', 'Unknown error in Mynaportal application'),
  invalidDateOfBirth('SE91025', 'Invalid date of birth format'),

  // ---- Special Feature Errors ----
  mynaIntegrated('SE27001', 'MyNumber integrated with Driving History Certificate'),
  mynaIntegratedDriverLicenseVerifyFailure(
    'SE27101',
    'My Number Card integrated with Driving License could not be verified',
    aliases: ['SE27102', 'SE27103'],
  ),
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
  unsupportedDeviceNfc('SE99998', 'This device does not support NFC'),
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

  /// Kode lain di SDK yang pakai status/pesan yang sama.
  ///
  /// SDK kadang punya beberapa kode untuk satu status yang sama
  /// (mis. SE21101/2/3 untuk IC_CHIP_SPECIAL_RESIDENCE).
  final List<String> aliases;

  const LiquidErrorCode(this.code, this.description, {this.aliases = const []});

  static LiquidErrorCode fromCode(String? errorCode) {
    if (errorCode == null || errorCode.isEmpty) {
      return LiquidErrorCode.unknown;
    }
    for (final error in values) {
      if (error.code == errorCode || error.aliases.contains(errorCode)) {
        return error;
      }
    }
    return LiquidErrorCode.unknown;
  }

  /// True kalau error ini bisa bikin kartu fisik terkunci.
  ///
  /// Chip My Number Card punya contador percobaan; habis beberapa kali gagal
  /// kartu terkunci dan harus dibuka di kantor kecamatan.
  bool get canLockCard {
    switch (this) {
      case LiquidErrorCode.icChipLocked:
      case LiquidErrorCode.pinErrorExceeded:
      case LiquidErrorCode.incorrectPin:
        return true;
      default:
        return false;
    }
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
        return 'PIN or credential does not match the card. Be careful - too many failed attempts can lock the card permanently.';
      case LiquidErrorCode.icChipSpecial:
        return 'This special residence card type cannot be read.';
      case LiquidErrorCode.icChipSpecialResidence:
        return 'Special residence card cannot be read.';
      case LiquidErrorCode.icChipVerificationFailure:
        return 'IC chip verification failed. Please try again.';
      case LiquidErrorCode.icChipReadError:
        return 'IC Chip could not be read. Ensure the card is placed flat on the NFC reader.';
      case LiquidErrorCode.icChipUnusual:
        return 'IC Chip has unusual updated information not supported.';
      case LiquidErrorCode.under16YearsOld:
        return 'Card belongs to person under 16 years old.';
      case LiquidErrorCode.chipExpired:
        return 'IC Chip has expired.';
      case LiquidErrorCode.nfcOff:
        return 'NFC setting is turned off. Enable NFC.';
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
      case LiquidErrorCode.mynaIntegratedDriverLicenseVerifyFailure:
        return 'My Number Card integrated with Driving License could not be verified.';
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
      case LiquidErrorCode.unsupportedDeviceNfc:
        return 'This device does not support NFC.';
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
