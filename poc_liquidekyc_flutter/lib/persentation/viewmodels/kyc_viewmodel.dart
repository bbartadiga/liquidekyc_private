import 'package:flutter/foundation.dart';
import '../../core/constant/liquid_constants.dart';
import '../../core/services/app_logger.dart';
import '../../data/models/kyc_result.dart';
import '../../data/models/document_result.dart';
import '../../data/models/face_results.dart';
import '../../data/models/chip_result.dart';
import '../../data/repositories/kyc_repository.dart';
import '../../data/services/kyc_be_api.dart';

class KycViewModel extends ChangeNotifier {
  final KycRepository _repository;
  final KycBeApi _beApi = KycBeApi();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[KycViewModel] $message');
    }
  }

  KycViewModel({KycRepository? repository})
      : _repository = repository ?? KycRepository() {
    _initSdk();
    if (LiquidConfig.applicantId.isNotEmpty && LiquidConfig.token.isNotEmpty) {
      setCredentials(
        applicantId: LiquidConfig.applicantId,
        token: LiquidConfig.token,
        sdkUrl: LiquidConfig.url,
      );
    }
  }

  KycStep _currentStep = KycStep.idle;
  KycResult? _lastResult;
  DocumentResult? _documentResult;
  FaceResult? _faceResult;
  ChipVerificationResult? _chipVerificationResult;
  ChipIdentificationResult? _chipIdentificationResult;
  OcrResult? _ocrResult;
  ICCardInfoResponse? _beICCardInfo;
  String? _errorMessage;
  bool _isLoading = false;
  bool _nfcAvailable = false;
  String? _sdkVersion;
  String _language = 'AUTO';
  String _buttonColor = '#000000';

  KycStep get currentStep => _currentStep;
  KycResult? get lastResult => _lastResult;
  DocumentResult? get documentResult => _documentResult;
  FaceResult? get faceResult => _faceResult;
  ChipVerificationResult? get chipVerificationResult => _chipVerificationResult;
  ChipIdentificationResult? get chipIdentificationResult => _chipIdentificationResult;
  OcrResult? get ocrResult => _ocrResult;
  ICCardInfoResponse? get beICCardInfo => _beICCardInfo;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get nfcAvailable => _nfcAvailable;
  String? get sdkVersion => _sdkVersion;
  DisplayLanguage get currentLanguage => DisplayLanguage.fromString(_language);
  String get buttonColor => _buttonColor;

  VerificationMethod _selectedMethod = VerificationMethod.defaultMethod;  // COMPLY_HE
  LiquidDocumentType _selectedDocumentType = LiquidDocumentType.defaultType;  // Residence Card
  FaceVerificationType _selectedFaceType = FaceVerificationType.active;

  // Dynamic credentials dari Backend (Production Mode)
  String? _dynamicApplicantId;
  String? _dynamicToken;
  String? _dynamicSdkUrl;
  bool _hasDynamicCredentials = false;

  VerificationMethod get selectedMethod => _selectedMethod;
  LiquidDocumentType get selectedDocumentType => _selectedDocumentType;
  FaceVerificationType get selectedFaceType => _selectedFaceType;

  // Getters untuk credentials
  bool get hasDynamicCredentials => _hasDynamicCredentials;
  String? get currentApplicantId => _dynamicApplicantId ?? LiquidConfig.applicantId;
  String? get currentToken => _dynamicToken ?? LiquidConfig.token;
  String? get currentSdkUrl => _dynamicSdkUrl ?? LiquidConfig.url;

  Future<void> _initSdk() async {
    _sdkVersion = await _repository.getSdkVersion();
    _nfcAvailable = await _repository.checkNfcAvailability();
    notifyListeners();
  }

  void setVerificationMethod(VerificationMethod method) {
    _selectedMethod = method;
    _updateDocumentTypeForMethod();
    notifyListeners();
  }

  void setDocumentType(LiquidDocumentType documentType) {
    _selectedDocumentType = documentType;
    notifyListeners();
  }

  void setFaceType(FaceVerificationType faceType) {
    _selectedFaceType = faceType;
    notifyListeners();
  }

  void setLanguage(DisplayLanguage language) {
    _language = language.value;
    _repository.changeLanguage(language);
    notifyListeners();
  }

  void setButtonColor(String color) {
    _buttonColor = color;
    _repository.customizeDesign(buttonColor: color);
    notifyListeners();
  }

  /// Set credentials dari Backend (Production Mode)
  /// Panggil method ini sebelum startKyc() jika menggunakan production mode
  void setCredentials({
    required String applicantId,
    required String token,
    String? sdkUrl,
  }) {
    _dynamicApplicantId = applicantId;
    _dynamicToken = token;
    _dynamicSdkUrl = sdkUrl;
    _hasDynamicCredentials = true;
    _log('Credentials set from backend - applicantId: $applicantId');
    notifyListeners();
  }

  /// Clear credentials (kembali ke trial mode atau defaults)
  void clearCredentials() {
    _dynamicApplicantId = null;
    _dynamicToken = null;
    _dynamicSdkUrl = null;
    _hasDynamicCredentials = false;
    _log('Credentials cleared - using default/trial mode');
    notifyListeners();
  }

  /// Fetch credentials (applicantId + token) dari Backend
  /// Panggil sebelum startKyc() untuk production mode
  Future<bool> fetchCredentialsFromBe({
    String? applicantId,
    String? beBaseUrl,
    String? applicantName,
    String? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? email,
  }) async {
    final targetApplicantId = applicantId ?? LiquidConfig.applicantId;
    _log('===== FETCH CREDENTIALS FROM BE =====');
    _log('ApplicantId: $targetApplicantId');
    _log('BE URL: ${beBaseUrl ?? LiquidConfig.url}');
    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Get token dari BE
      _log('[STEP 1] Requesting token from BE...');
      final tokenResponse = await _beApi.applyForSdkToken(
        applicantId: targetApplicantId,
      );

      if (tokenResponse?.isSuccess != true || tokenResponse?.token == null) {
        _isLoading = false;
        _errorMessage = tokenResponse?.errorMessage ?? 'Failed to get token from BE';
        _log('[ERROR] Failed to get token: $_errorMessage');
        notifyListeners();
        return false;
      }

      _log('[OK] Token received from BE');
      _log('Token: ${tokenResponse!.token}');

      setCredentials(
        applicantId: tokenResponse.applicantId ?? targetApplicantId,
        token: tokenResponse.token!,
        sdkUrl: beBaseUrl ?? LiquidConfig.url,
      );

      // Step 2: Register applicant info ke BE
      _log('[STEP 2] Registering applicant info to BE...');
      final registerResponse = await _beApi.registerApplicantInfo(
        applicantId: tokenResponse.applicantId ?? targetApplicantId,
        applicantName: applicantName ?? 'TARO YAMADA',
        dateOfBirth: dateOfBirth ?? '1990-05-15',
        address: address ?? 'Tokyo-to, Chiyoda-ku, Marunouchi 1-1-1',
        phoneNumber: phoneNumber ?? '08123456789',
        email: email ?? 'taro.yamada@example.com',
      );

      if (registerResponse?.isSuccess == true) {
        _log('[OK] Applicant registered: ${registerResponse!.applicationId}');
      } else {
        _log('[WARN] Failed to register applicant info (optional step)');
        _log('Error: ${registerResponse?.errorMessage}');
      }

      _isLoading = false;
      _log('Credentials saved to ViewModel');
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching credentials: $e';
      _log('[ERROR] $e');
      notifyListeners();
      return false;
    }
  }

  /// Create new applicant via BE (BE akan generate applicantId baru)
  Future<bool> createNewApplicant({String? beBaseUrl}) async {
    _log('Creating new applicant via BE...');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _beApi.applyNewApplicant();

      _isLoading = false;

      if (response?.isSuccess == true && response?.token != null) {
        setCredentials(
          applicantId: response!.applicantId ?? '',
          token: response.token!,
          sdkUrl: beBaseUrl ?? LiquidConfig.url,
        );
        _log('New applicant created successfully - ID: ${response.applicantId}');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response?.errorMessage ?? 'Failed to create applicant';
        _log('Failed to create applicant: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error creating applicant: $e';
      _log('Error creating applicant: $e');
      notifyListeners();
      return false;
    }
  }

  void _updateDocumentTypeForMethod() {
    switch (_selectedMethod) {
      case VerificationMethod.complyHe:
      case VerificationMethod.read:
      case VerificationMethod.readFace:
if (_selectedDocumentType == LiquidDocumentType.driverLicense ||
            _selectedDocumentType == LiquidDocumentType.myNumberCard ||
            _selectedDocumentType == LiquidDocumentType.residenceCard ||
            _selectedDocumentType == LiquidDocumentType.specialPermanentResidentCertificate) {
          // These document types support IC Card reading
          // Keep the current method if it supports IC card
        } else {
          // Fall back to residence card for unsupported types (project default)
          _selectedDocumentType = LiquidDocumentType.defaultType;
        }
        break;
      default:
        break;
    }
  }

  Future<KycResult> startKyc() async {
    appLogger.i('[STEP 7] startKyc() called');
    appLogger.i('  Mode: ${LiquidConfig.isDebugMode ? "DEBUG" : "REAL"}');
    appLogger.i('  Method: ${_selectedMethod.value}');
    appLogger.i('  Document: ${_selectedDocumentType.value}');
    appLogger.i('  Face Type: ${_selectedFaceType.value}');
    appLogger.i('  Has credentials: $_hasDynamicCredentials');
    appLogger.i('  ApplicantId: $_dynamicApplicantId');
    appLogger.i('  Token length: ${_dynamicToken?.length ?? 0}');
    appLogger.i('  SDK URL: ${currentSdkUrl ?? LiquidConfig.url}');

    debugPrint('[STEP 7] START | mode:${LiquidConfig.isDebugMode?"DEBUG":"REAL"} | method:${_selectedMethod.value} | doc:${_selectedDocumentType.value} | face:${_selectedFaceType.value} | creds:$_hasDynamicCredentials | applicantId:$_dynamicApplicantId | tokenLen:${_dynamicToken?.length??0} | sdkUrl:${currentSdkUrl ?? LiquidConfig.url}');
    appLogger.i('[STEP 7] START | mode:${LiquidConfig.isDebugMode?"DEBUG":"REAL"} | method:${_selectedMethod.value} | doc:${_selectedDocumentType.value} | face:${_selectedFaceType.value} | creds:$_hasDynamicCredentials | applicantId:$_dynamicApplicantId | tokenLen:${_dynamicToken?.length??0} | sdkUrl:${currentSdkUrl ?? LiquidConfig.url}');
    
    _isLoading = true;
    _errorMessage = null;
    _currentStep = KycStep.initializing;
    notifyListeners();

    KycResult initResult;
    final sdkUrl = currentSdkUrl ?? LiquidConfig.url;
    
    // Priority 1: Debug mode (mock)
    if (LiquidConfig.isDebugMode) {
      _log('[STEP 7] Using DEBUG mode (mock responses)');
      appLogger.i('[STEP 7] Using DEBUG mode (mock responses)');
      initResult = await _repository.initialize(
        url: sdkUrl,
        apiKey: LiquidConfig.apiKey,
      );
    }
    // Priority 2: Dynamic credentials dari backend (Production Mode)
    else if (_hasDynamicCredentials && 
             _dynamicApplicantId != null && 
             _dynamicToken != null) {
      appLogger.i('[STEP 7] Using PRODUCTION mode with BE credentials');
      appLogger.i('  applicantId: $_dynamicApplicantId');
      appLogger.i('  token: $_dynamicToken');
      appLogger.i('  sdkUrl: $sdkUrl');
      _log('[STEP 7] Using PRODUCTION mode with BE credentials');
      _log('  applicantId: $_dynamicApplicantId');
      _log('  token: $_dynamicToken');
      _log('  sdkUrl: $sdkUrl');
      initResult = await _repository.initializeWithCredentials(
        url: sdkUrl,
        applicantId: _dynamicApplicantId!,
        token: _dynamicToken!,
      );
    }
    // Priority 3: Trial mode (API Key only)
    else if (LiquidConfig.apiKey.isNotEmpty &&
        LiquidConfig.apiKey != 'YOUR_API_KEY_FOR_TRIAL') {
      _log('[STEP 7] Using TRIAL mode with API Key');
      initResult = await _repository.initialize(
        url: sdkUrl,
        apiKey: LiquidConfig.apiKey,
      );
    }
    // No valid credentials
    else {
      _log('[STEP 7] ERROR - No valid credentials!');
      _log('  DEBUG_MODE: ${LiquidConfig.isDebugMode}');
      _log('  hasDynamicCredentials: $_hasDynamicCredentials');
      _log('  apiKey: ${LiquidConfig.apiKey.isNotEmpty ? "SET" : "EMPTY"}');
      appLogger.e('[STEP 7] ERROR - No valid credentials!');
      appLogger.e('  DEBUG_MODE: ${LiquidConfig.isDebugMode}');
      appLogger.e('  hasDynamicCredentials: $_hasDynamicCredentials');
      appLogger.e('  apiKey: ${LiquidConfig.apiKey.isNotEmpty ? "SET" : "EMPTY"}');
      _isLoading = false;
      _currentStep = KycStep.error;
      _errorMessage = 'No valid credentials. Use DEBUG mode or set dynamic credentials from backend.';
      notifyListeners();
      return KycResult.error(
        errorCode: 'NO_CREDENTIALS',
        message: 'No valid credentials. Set DEBUG_MODE=true or call setCredentials() from backend.',
      );
    }

    _log('[STEP 8] Init SDK → ${initResult.isSuccess?"SUCCESS":"FAILED"} | status:${initResult.status.name} | code:${initResult.errorCode??"none"}');

    if (!initResult.isSuccess) {
      appLogger.e('[STEP 8] Init SDK → FAILED | status:${initResult.status.name} | code:${initResult.errorCode??"none"}');
      _lastResult = initResult;
      _currentStep = KycStep.error;
      _errorMessage = initResult.additionalDataMessage ?? initResult.status.displayName;
      _isLoading = false;
      notifyListeners();
      return initResult;
    }

    _currentStep = KycStep.termsOfUse;
    _log('[STEP 10] Showing Terms of Use...');
    notifyListeners();

    final termsResult = await _repository.showTermsOfUse();
    
    if (!termsResult.isSuccess) {
      final errType = termsResult.liquidError.name;
      final errCode = termsResult.errorCode ?? 'none';
      final errMsg = termsResult.additionalDataMessage ?? 'none';
      appLogger.e('[STEP 10] Terms → FAILED | status:${termsResult.status.name} | type:$errType | code:$errCode | msg:$errMsg');
      
      _log('[STEP 10] Terms → FAILED | ${termsResult.status.name} | code:$errCode');
      _lastResult = termsResult;
      
      if (termsResult.isTermsNotAgreed) {
        _currentStep = KycStep.idle;
        _errorMessage = 'Please agree to terms of use';
      } else if (termsResult.isImplementationError) {
        _currentStep = KycStep.error;
        _errorMessage = 'System Error: SDK belum diinisialisasi dengan benar. Hubungi support.';
        appLogger.e('[STEP 10] ERROR: SDK not initialized properly - check Android logcat for registerLaunchers() logs');
      } else if (termsResult.isSessionExpired) {
        _currentStep = KycStep.error;
        _errorMessage = 'Sesi berakhir. Token kadaluarsa (~90min lifetime). Minta token baru dari BE.';
      } else if (termsResult.isMaintenance) {
        _currentStep = KycStep.error;
        _errorMessage = termsResult.userFriendlyMessage;
      } else {
        _currentStep = KycStep.error;
        _errorMessage = termsResult.userFriendlyMessage;
      }
      
      _isLoading = false;
      notifyListeners();
      return termsResult;
    }
    _log('[STEP 10] Terms → SUCCESS | accepted');

    // Get verification order based on method
    // COMPLY_HE: IC Card → Face (NO document scan per SDK specs)
    final verificationOrder = _selectedMethod.verificationOrder;
    _log('[STEP 11] Verify order: $verificationOrder | doc:${_selectedDocumentType.value}');

    int stepNum = 11;
    for (final step in verificationOrder) {
      if (step == 'icCard') {
        _log('[STEP $stepNum] IC Card (NFC) → STARTING...');
        _currentStep = KycStep.icCardRead;
        notifyListeners();

        _chipVerificationResult = await _repository.verifyIdChip(
          documentType: _selectedDocumentType,
          verificationMethod: _selectedMethod,
        );

        if (!_chipVerificationResult!.isSuccess) {
          final errMsg = _chipVerificationResult!.userFriendlyMessage;
          _log('[STEP $stepNum] IC Card (NFC) → FAILED | code:${_chipVerificationResult!.errorCode} | msg:$errMsg');
          appLogger.e('[STEP $stepNum] IC Card (NFC) → FAILED | code:${_chipVerificationResult!.errorCode} | msg:$errMsg');
          _currentStep = KycStep.error;
          _errorMessage = errMsg;
          _isLoading = false;
          notifyListeners();
          return KycResult.error(errorCode: 'CHIP_ERROR', message: _errorMessage);
        }
        _log('[STEP $stepNum] IC Card (NFC) → SUCCESS');
      }

      if (step == 'document') {
        _log('[STEP $stepNum] Document Scan (OCR) → STARTING...');
        _currentStep = KycStep.documentScan;
        notifyListeners();

        _documentResult = await _repository.verifyDocument(
          documentType: _selectedDocumentType,
          verificationMethod: _selectedMethod,
        );

        if (!_documentResult!.isSuccess) {
          final errMsg = _documentResult!.userFriendlyMessage;
          _log('[STEP $stepNum] Document Scan (OCR) → FAILED | code:${_documentResult!.errorCode} | msg:$errMsg');
          appLogger.e('[STEP $stepNum] Document Scan (OCR) → FAILED | code:${_documentResult!.errorCode} | msg:$errMsg');
          _currentStep = KycStep.error;
          _errorMessage = errMsg;
          _isLoading = false;
          notifyListeners();
          return KycResult.error(errorCode: 'DOCUMENT_ERROR', message: _errorMessage);
        }
        _log('[STEP $stepNum] Document Scan (OCR) → SUCCESS');

        _ocrResult = await _repository.getOcrResults();
        _log('[STEP $stepNum] OCR data extracted → name:${_ocrResult?.name ?? "N/A"}');
      }

      if (step == 'face') {
        _log('[STEP $stepNum] Face Verify → STARTING...');
        _currentStep = KycStep.faceScan;
        notifyListeners();

        _faceResult = await _repository.verifyFace(
          faceVerificationType: _selectedFaceType,
        );

        if (!_faceResult!.isSuccess) {
          final errMsg = _faceResult!.userFriendlyMessage;
          _log('[STEP $stepNum] Face Verify → FAILED | code:${_faceResult!.errorCode} | msg:$errMsg');
          appLogger.e('[STEP $stepNum] Face Verify → FAILED | code:${_faceResult!.errorCode} | msg:$errMsg');
          _currentStep = KycStep.error;
          _errorMessage = errMsg;
          _isLoading = false;
          notifyListeners();
          return KycResult.error(errorCode: 'FACE_ERROR', message: _errorMessage);
        }
        _log('[STEP $stepNum] Face Verify → SUCCESS | autoVerify:${_faceResult!.autoVerificationResult?.result.name ?? "N/A"}');
      }
      stepNum++;
    }

    _log('[FINAL] Activate KYC → STARTING...');
    _currentStep = KycStep.activating;
    notifyListeners();

    final activateResult = await _repository.activate();
    _lastResult = activateResult;

    if (activateResult.isSuccess) {
      _log('[FINAL] Activate KYC → SUCCESS | KYC Completed!');
      appLogger.i('[FINAL] Activate KYC → SUCCESS | KYC Completed!');
      
      // Fetch chip data from BE if SDK didn't return it
      if (_chipVerificationResult?.chipData == null && _dynamicApplicantId != null) {
        _log('[BE] Fetching IC Card Info from BE...');
        appLogger.i('[BE] Fetching IC Card Info from BE...');
        _beICCardInfo = await _beApi.getICCardInfo(_dynamicApplicantId!);
        if (_beICCardInfo?.isSuccess == true) {
          appLogger.i('[BE] IC Card Info received: name=${_beICCardInfo?.name}');
          _log('[BE] IC Card Info received from BE');
        } else {
          appLogger.e('[BE] Failed to get IC Card Info: ${_beICCardInfo?.errorMessage}');
          _log('[BE] Failed to get IC Card Info');
        }
      }
      
      _currentStep = KycStep.completed;
    } else {
      _log('[FINAL] Activate KYC → FAILED | status:${activateResult.status.displayName} | msg:${activateResult.additionalDataMessage??"none"}');
      appLogger.e('[FINAL] Activate KYC → FAILED | status:${activateResult.status.displayName} | msg:${activateResult.additionalDataMessage??"none"}');
      _currentStep = KycStep.error;
      _errorMessage = activateResult.additionalDataMessage ?? activateResult.status.displayName;
    }

    _isLoading = false;
    notifyListeners();
    return activateResult;
  }

  Future<void> startDocumentScan() async {
    _currentStep = KycStep.documentScan;
    _isLoading = true;
    notifyListeners();

    _documentResult = await _repository.verifyDocument(
      documentType: _selectedDocumentType,
      verificationMethod: _selectedMethod,
    );

    if (_documentResult!.isSuccess) {
      _ocrResult = await _repository.getOcrResults();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startIcCardRead() async {
    _currentStep = KycStep.icCardRead;
    _isLoading = true;
    notifyListeners();

    _chipVerificationResult = await _repository.verifyIdChip(
      documentType: _selectedDocumentType,
      verificationMethod: _selectedMethod,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startFaceScan() async {
    _currentStep = KycStep.faceScan;
    _isLoading = true;
    notifyListeners();

    _faceResult = await _repository.verifyFace(
      faceVerificationType: _selectedFaceType,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> activate() async {
    _currentStep = KycStep.activating;
    _isLoading = true;
    notifyListeners();

    _lastResult = await _repository.activate();

    if (_lastResult!.isSuccess) {
      _currentStep = KycStep.completed;
    } else {
      _currentStep = KycStep.error;
      _errorMessage = _lastResult!.additionalDataMessage;
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _currentStep = KycStep.idle;
    _lastResult = null;
    _documentResult = null;
    _faceResult = null;
    _chipVerificationResult = null;
    _chipIdentificationResult = null;
    _ocrResult = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void cancel() {
    _currentStep = KycStep.idle;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  bool get isCompleted => _currentStep == KycStep.completed;
  bool get hasError => _currentStep == KycStep.error;
  bool get isInProgress => _currentStep != KycStep.idle && _currentStep != KycStep.completed && _currentStep != KycStep.error;

  Map<String, dynamic> getKycSummary() {
    return {
      'method': _selectedMethod.displayName,
      'documentType': _selectedDocumentType.displayName,
      'documentResult': _documentResult?.isSuccess ?? false,
      'faceResult': _faceResult?.isSuccess ?? false,
      'chipResult': _chipVerificationResult?.isSuccess ?? false,
      'overallResult': _lastResult?.isSuccess ?? false,
      'ocrData': _ocrResult?.toMap(),
    };
  }
}