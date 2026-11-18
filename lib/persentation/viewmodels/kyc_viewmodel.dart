import 'package:flutter/foundation.dart';
import '../../core/constant/liquid_constants.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/chip_attempt_guard.dart';
import '../../data/models/kyc_result.dart';
import '../../data/models/document_result.dart';
import '../../data/models/face_results.dart';
import '../../data/models/chip_result.dart';
import '../../data/repositories/kyc_repository.dart';
import '../../data/models/ic_card_info_response.dart';
import '../../data/models/liveness_images_response.dart';
import '../../data/models/ocr_results_response.dart';
import '../../data/models/photos_response.dart';
import '../../data/models/verification_results_response.dart';
import '../../data/services/kyc_be_api.dart';
import '../../data/services/kyc_be_data_service.dart';
import '../../data/services/kyc_credentials_service.dart';
import '../../data/services/kyc_verification_runner.dart';
import '../../data/services/kyc_retry_queue.dart';
import '../../data/services/kyc_queue_worker.dart';

class KycViewModel extends ChangeNotifier {
  final KycRepository _repository;
  final KycBeApi _beApi = KycBeApi();
  late final KycCredentialsService _credentialsService;
  late final KycBeDataService _beDataService;
  late final KycVerificationRunner _verificationRunner;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[KycViewModel] $message');
    }
  }

  KycViewModel({KycRepository? repository})
      : _repository = repository ?? KycRepository() {
    // Set up progress callback untuk BE API
    _beApi.onProgress = (step, isLoading) {
      _currentProgressStep = step;
      _isFetchingBeData = isLoading;
      notifyListeners();
    };

    _credentialsService = KycCredentialsService(beApi: _beApi);
    _beDataService = KycBeDataService(beApi: _beApi);
    _verificationRunner = KycVerificationRunner(repository: _repository);

    _initQueue();
    _initSdk();
    if (LiquidConfig.applicantId.isNotEmpty && LiquidConfig.token.isNotEmpty) {
      setCredentials(
        applicantId: LiquidConfig.applicantId,
        token: LiquidConfig.token,
        sdkUrl: LiquidConfig.url,
      );
    }
  }

  Future<void> _initQueue() async {
    await KycRetryQueue.init();
    await ChipAttemptGuard.init();
    KycQueueWorker.initialize(
      onRetryComplete: (endpoint, success, error) {
        _log('Queue retry ${success ? "SUCCESS" : "FAILED"}: $endpoint');
        if (success) {
          _pendingQueueCount--;
          notifyListeners();
        }
      },
    );
    KycQueueWorker.start();
    _pendingQueueCount = await KycQueueWorker.getPendingCount();
    _log('Queue initialized. Pending: $_pendingQueueCount');
  }

  int _pendingQueueCount = 0;
  int get pendingQueueCount => _pendingQueueCount;
  bool get hasQueuedRequests => _pendingQueueCount > 0;

  KycStep _currentStep = KycStep.idle;
  KycResult? _lastResult;
  DocumentResult? _documentResult;
  FaceResult? _faceResult;
  ChipVerificationResult? _chipVerificationResult;
  ChipIdentificationResult? _chipIdentificationResult;
  OcrResult? _ocrResult;
  bool _isRegisterApplicationInfoSuccess = false;
  String? _errorMessage;

  /// Error terakhir bisa bikin kartu fisik terkunci (chip My Number Card).
  bool _cardLockRisk = false;
  bool _isLoading = false;
  bool _isFetchingBeData = false;  // Track BE API loading
  String _currentProgressStep = '';  // Current step being processed
  bool _nfcAvailable = false;
  String? _sdkVersion;
  String _language = 'AUTO';
  String _buttonColor = '#000000';

  // Data dari Connector API (BE)
  ICCardInfoResponse? beICCardInfo;
  VerificationResultsResponse? beVerificationResults;
  OcrResultsBeResponse? beOcrResults;
  PhotosResponse? bePhotos;
  LivenessImagesResponse? beLivenessImages;

  KycStep get currentStep => _currentStep;
  KycResult? get lastResult => _lastResult;
  DocumentResult? get documentResult => _documentResult;
  FaceResult? get faceResult => _faceResult;
  ChipVerificationResult? get chipVerificationResult => _chipVerificationResult;
  ChipIdentificationResult? get chipIdentificationResult => _chipIdentificationResult;
  OcrResult? get ocrResult => _ocrResult;
  bool get isRegisterApplicationInfoSuccess => _isRegisterApplicationInfoSuccess;
  String? get errorMessage => _errorMessage;

  /// true kalau error terakhir berpotensi mengunci kartu fisik.
  bool get cardLockRisk => _cardLockRisk;
  bool get isLoading => _isLoading;
  bool get isFetchingBeData => _isFetchingBeData;
  String get currentProgressStep => _currentProgressStep;
  bool get nfcAvailable => _nfcAvailable;
  String? get sdkVersion => _sdkVersion;
  DisplayLanguage get currentLanguage => DisplayLanguage.fromString(_language);
  String get buttonColor => _buttonColor;

  VerificationMethod _selectedMethod = VerificationMethod.defaultMethod;  // COMPLY_HE
  LiquidDocumentType _selectedDocumentType = LiquidDocumentType.defaultType;  // Residence Card
  FaceVerificationType _selectedFaceType = FaceVerificationType.active;
  Nationality _selectedNationality = Nationality.indonesia;

  // Dynamic credentials dari Backend (Production Mode)
  String? _dynamicApplicantId;
  String? _dynamicToken;
  String? _dynamicSdkUrl;
  bool _hasDynamicCredentials = false;

  VerificationMethod get selectedMethod => _selectedMethod;
  LiquidDocumentType get selectedDocumentType => _selectedDocumentType;
  FaceVerificationType get selectedFaceType => _selectedFaceType;
  Nationality get selectedNationality => _selectedNationality;

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

  /// Dokumen yang benar-benar dibaca dari chip (null kalau SDK tidak mengirim)
  String? get actualDocumentTypeValue =>
      _chipVerificationResult?.chipData?.liquidDocumentType;

  LiquidDocumentType? get actualDocumentType {
    final value = actualDocumentTypeValue;
    if (value == null || value.isEmpty) return null;
    return LiquidDocumentType.fromString(value);
  }

  bool get isDocumentTypeMismatch {
    final actual = actualDocumentType;
    if (actual == null) return false;
    return !_selectedDocumentType.isCompatibleWith(actual);
  }

  /// Bandingkan dokumen yang diminta dengan dokumen yang dibaca dari chip.
  void _checkDocumentTypeMatch() {
    final actual = actualDocumentType;
    if (actual == null) {
      appLogger.w('[Mismatch] Dokumen aktual tidak dilaporkan SDK');
      return;
    }
    if (isDocumentTypeMismatch) {
      appLogger.e(
        '[Mismatch] Dokumen tidak sesuai! diminta=${_selectedDocumentType.value} '
        'dibaca=${actual.value}',
      );
    } else {
      appLogger.i(
        '[Mismatch] Dokumen sesuai: ${_selectedDocumentType.value} '
        '(dibaca=${actual.value})',
      );
    }
  }

  void setNationality(Nationality nationality) {
    _selectedNationality = nationality;
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
    _log('===== FETCH CREDENTIALS FROM BE =====');
    _isLoading = true;
    notifyListeners();

    try {
      final credentials = await _credentialsService.fetch(
        applicantId: applicantId,
        beBaseUrl: beBaseUrl,
        applicantName: applicantName,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        email: email,
      );

      if (!credentials.isSuccess) {
        _isLoading = false;
        _errorMessage = credentials.errorMessage;
        _log('[ERROR] ${credentials.errorMessage}');
        notifyListeners();
        return false;
      }

      setCredentials(
        applicantId: credentials.applicantId,
        token: credentials.token,
        sdkUrl: credentials.sdkUrl,
      );

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
      final credentials = await _credentialsService.createNewApplicant(
        beBaseUrl: beBaseUrl,
      );

      if (!credentials.isSuccess) {
        _isLoading = false;
        _errorMessage = credentials.errorMessage;
        _log('Failed to create applicant: ${credentials.errorMessage}');
        notifyListeners();
        return false;
      }

      setCredentials(
        applicantId: credentials.applicantId,
        token: credentials.token,
        sdkUrl: credentials.sdkUrl,
      );

      _isLoading = false;
      notifyListeners();
      return true;
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
        if (_selectedDocumentType == LiquidDocumentType.driverLicense ||
            _selectedDocumentType == LiquidDocumentType.myNumberCard ||
            _selectedDocumentType == LiquidDocumentType.myNumberCardWithMyNumber ||
            _selectedDocumentType == LiquidDocumentType.myNumberCardIntegratedDriverLicense ||
            _selectedDocumentType == LiquidDocumentType.residenceCard ||
            _selectedDocumentType == LiquidDocumentType.residenceDocumentGen2 ||
            _selectedDocumentType == LiquidDocumentType.specifiedResidenceCard ||
            _selectedDocumentType == LiquidDocumentType.specifiedSpecialPermanentResidentCertificate) {
          // These document types support IC Card reading
          // Keep the current method if it supports IC card
        } else {
          // Fall back to residence card for unsupported types (project default)
          _selectedDocumentType = LiquidDocumentType.defaultType;
        }
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

    // Verifikasi inti: IC chip → document → face (urutan dari method)
    final outcome = await _verificationRunner.run(
      method: _selectedMethod,
      documentType: _selectedDocumentType,
      faceType: _selectedFaceType,
      currentOcrResult: _ocrResult,
      onStep: (step) {
        _currentStep = step;
        notifyListeners();
      },
      onChipVerified: _checkDocumentTypeMatch,
    );

    _chipVerificationResult = outcome.chipResult ?? _chipVerificationResult;
    _documentResult = outcome.documentResult ?? _documentResult;
    _faceResult = outcome.faceResult ?? _faceResult;
    _ocrResult = outcome.ocrResult ?? _ocrResult;

    if (!outcome.isSuccess) {
      _currentStep = KycStep.error;
      _errorMessage = outcome.errorMessage;
      _cardLockRisk = outcome.cardLockRisk;
      _isLoading = false;
      notifyListeners();
      return KycResult.error(
        errorCode: outcome.errorCode ?? 'VERIFICATION_ERROR',
        message: _errorMessage,
      );
    }

    // ========================================
    // [STEP BE-1] Register Application Info (REQUIRED by Liquid)
    // WAJIB dipanggil sebelum activate() dan sebelum API lain berfungsi
    // ========================================
    if (_dynamicApplicantId != null && !_isRegisterApplicationInfoSuccess) {
      // Urutan sumber data: chip (signed JPKI, paling otoritatif) →
      // OCR (dipakai kalau method-nya nggak baca chip) → data BE → fallback.
      // Tanpa OCR di tengah, flow tanpa chip (FRONT/COMPLY_TO) ngeirim
      // data palsu ('User'/'19900101'/'Address') ke BE.
      final registered = await _beDataService.registerApplicationInfo(
        applicantId: _dynamicApplicantId!,
        applicantName: _chipVerificationResult?.chipData?.displayName ??
                       _ocrResult?.name ??
                       beICCardInfo?.displayName ??
                       'User',
        dateOfBirth: _chipVerificationResult?.chipData?.displayBirthday ??
                     _ocrResult?.birthday ??
                     beICCardInfo?.displayBirthday ??
                     '19900101',
        address: _chipVerificationResult?.chipData?.fullAddress ??
                 _ocrResult?.fullAddress ??
                 beICCardInfo?.fullAddress ??
                 'Address',
      );
      _isRegisterApplicationInfoSuccess = registered;
      _log('[BE-1] RegisterApplicationInfo → ${registered ? "SUCCESS" : "FAILED"}');
    }

    // ========================================
    // [STEP BE-2] Get Verification Results (Face Match Score, Liveness)
    // ========================================
    if (_dynamicApplicantId != null && beVerificationResults == null) {
      beVerificationResults =
          await _beDataService.fetchVerificationResults(_dynamicApplicantId!);
      _log('[BE-2] VerificationResults → ${beVerificationResults?.isSuccess == true ? "SUCCESS" : "FAILED"}');
    }

    _log('[FINAL] Activate KYC → STARTING...');
    _currentStep = KycStep.activating;
    notifyListeners();

    final activateResult = await _repository.activate();
    _lastResult = activateResult;

    if (activateResult.isSuccess) {
      _log('[FINAL] Activate KYC → SUCCESS | KYC Completed!');
      appLogger.i('[FINAL] Activate KYC → SUCCESS | KYC Completed!');
      
      // ========================================
      // [BE-3..BE-5] Ambil data resmi dari BE
      // ========================================
      if (_dynamicApplicantId != null) {
        final beData = await _beDataService.fetchPostActivationData(
          _dynamicApplicantId!,
          includeICCardInfo: _chipVerificationResult?.chipData == null,
        );

        beICCardInfo ??= beData.icCardInfo;
        beOcrResults ??= beData.ocrResults;
        beLivenessImages ??= beData.livenessImages;
        bePhotos ??= beData.photos;
      }

      // ========================================
      // [BE-6] Register KYC Result (for masking)
      // Optional - untuk trigger auto-masking
      // ========================================
      if (_dynamicApplicantId != null && _isRegisterApplicationInfoSuccess) {
        await _beDataService.registerKycResult(_dynamicApplicantId!);
      }

      // Reset progress state after all BE API calls done
      _currentProgressStep = '';
      _isFetchingBeData = false;
      notifyListeners();

      _currentStep = KycStep.completed;
    } else {
      _log('[FINAL] Activate KYC → FAILED | status:${activateResult.status.displayName} | msg:${activateResult.additionalDataMessage??"none"}');
      appLogger.e('[FINAL] Activate KYC → FAILED | status:${activateResult.status.displayName} | msg:${activateResult.additionalDataMessage??"none"}');
      _currentStep = KycStep.error;
      _errorMessage = activateResult.additionalDataMessage ?? activateResult.status.displayName;
    }

    // Reset progress state on error too
    _currentProgressStep = '';
    _isFetchingBeData = false;
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
    _cardLockRisk = false;
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
      'queuedRequests': _pendingQueueCount,
    };
  }

  @override
  void dispose() {
    KycQueueWorker.dispose();
    super.dispose();
  }
}