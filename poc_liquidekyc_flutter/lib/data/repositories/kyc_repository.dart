import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../models/kyc_result.dart';
import '../models/document_result.dart';
import '../models/face_results.dart';
import '../models/chip_result.dart';
import '../../core/constant/liquid_constants.dart';
import '../../core/services/liquid_ekyc_channel.dart';
import '../../core/services/app_logger.dart';

class KycRepository {
  final LiquidEkycChannel _channel;

  KycRepository({LiquidEkycChannel? channel})
      : _channel = channel ?? LiquidEkycChannel();

  Future<KycResult> initialize({
    required String url,
    required String apiKey,
  }) async {
    debugPrint('[STEP 8] Repository.initialize() called');
    debugPrint('  Mode: DEBUG');
    debugPrint('  url: $url');
    appLogger.i('[STEP 8] Repository.initialize() called');
    appLogger.i('  Mode: DEBUG');
    appLogger.i('  url: $url');
    appLogger.i('  apiKey: ${apiKey.substring(0, 20)}...');

    final result = await _channel.startVerifyTrial(
      url: url,
      apiKey: apiKey,
    );
    debugPrint('[STEP 8] initialize() result: ${result?['resultStatus'] ?? 'unknown'}');
    appLogger.i('[STEP 8] initialize() result: ${result?['resultStatus'] ?? 'unknown'}');
    return KycResult.fromMap(result);
  }

  Future<KycResult> initializeWithCredentials({
    required String url,
    required String applicantId,
    required String token,
  }) async {
    debugPrint('[STEP 8] Repository.initializeWithCredentials() called');
    debugPrint('  Mode: PRODUCTION');
    debugPrint('  url: $url');
    debugPrint('  applicantId: $applicantId');
    appLogger.i('[STEP 8] Repository.initializeWithCredentials() called');
    appLogger.i('  Mode: PRODUCTION');
    appLogger.i('  url: $url');
    appLogger.i('  applicantId: $applicantId');
    appLogger.i('  token: $token');

    final result = await _channel.startVerify(
      url: url,
      applicantId: applicantId,
      token: token,
    );
    debugPrint('[STEP 8] initializeWithCredentials() result: ${result?['resultStatus'] ?? 'unknown'}');
    appLogger.i('[STEP 8] initializeWithCredentials() result: ${result?['resultStatus'] ?? 'unknown'}');
    return KycResult.fromMap(result);
  }

  Future<KycResult> showTermsOfUse() async {
    debugPrint('[STEP 10] Repository.showTermsOfUse() called');
    appLogger.i('===========================================');
    appLogger.i('[STEP 10] Repository.showTermsOfUse() called');
    appLogger.i('  Calling Channel to show Terms screen...');
    appLogger.i('===========================================');

    final result = await _channel.showTermsOfUse();
    
    final status = result?['resultStatus'] ?? 'unknown';
    final errorCode = result?['errorCode'];
    final message = result?['additionalDataMessage'] ?? result?['message'];
    
    debugPrint('[STEP 10] RESULT - Status: $status');
    appLogger.i('===========================================');
    appLogger.i('[STEP 10] RESULT RECEIVED');
    appLogger.i('  Status: $status');
    if (errorCode != null) {
      appLogger.e('  ErrorCode: $errorCode');
    }
    if (message != null) {
      appLogger.e('  Message: $message');
    }
    appLogger.i('===========================================');
    
    return KycResult.fromMap(result);
  }

  Future<DocumentResult> verifyDocument({
    required LiquidDocumentType documentType,
    required VerificationMethod verificationMethod,
    bool showReviewScreen = true,
  }) async {
    debugPrint('[STEP 12] Repository.verifyDocument() called');
    debugPrint('  docType: ${documentType.value}, method: ${verificationMethod.value}');
    appLogger.i('[STEP 12] Repository.verifyDocument() called');
    appLogger.i('  docType: ${documentType.value}, method: ${verificationMethod.value}');

    final result = await _channel.verifyIdDocument(
      documentType: documentType,
      verificationMethod: verificationMethod,
      showReviewScreen: showReviewScreen,
    );
    debugPrint('[STEP 12] Repository.verifyDocument() result: ${result?['resultStatus'] ?? 'unknown'}');
    appLogger.i('[STEP 12] Repository.verifyDocument() result: ${result?['resultStatus'] ?? 'unknown'}');
    return DocumentResult.fromMap(result);
  }

  Future<ChipVerificationResult> verifyIdChip({
    required LiquidDocumentType documentType,
    required VerificationMethod verificationMethod,
    bool showReviewScreen = true,
  }) async {
    debugPrint('[STEP 11] Repository.verifyIdChip() called');
    debugPrint('  docType: ${documentType.value}');
    appLogger.i('[STEP 11] Repository.verifyIdChip() called');
    appLogger.i('  docType: ${documentType.value}');

    final result = await _channel.verifyIdChip(
      documentType: documentType,
      verificationMethod: verificationMethod,
      showReviewScreen: showReviewScreen,
    );
    debugPrint('[STEP 11] Repository.verifyIdChip() result: ${result?['resultStatus'] ?? 'unknown'}');
    appLogger.i('[STEP 11] Repository.verifyIdChip() result: ${result?['resultStatus'] ?? 'unknown'}');
    return ChipVerificationResult.fromMap(result);
  }

  Future<ChipIdentificationResult> identifyIdChip() async {
    final result = await _channel.identifyIdChip();
    return ChipIdentificationResult.fromMap(result);
  }

  Future<MynaIdentificationResult> identifyIdMyna() async {
    final result = await _channel.identifyIdMyna();
    return MynaIdentificationResult.fromMap(result);
  }

  Future<FaceResult> verifyFace({
    bool showReviewScreen = true,
    FaceVerificationType faceVerificationType = FaceVerificationType.active,
  }) async {
    debugPrint('[STEP 13] Repository.verifyFace() called');
    debugPrint('  type: ${faceVerificationType.value}');
    appLogger.i('[STEP 13] Repository.verifyFace() called');
    appLogger.i('  type: ${faceVerificationType.value}');

    final result = await _channel.verifyFace(
      showReviewScreen: showReviewScreen,
      faceVerificationType: faceVerificationType,
    );
    debugPrint('[STEP 13] Repository.verifyFace() result: ${result?['resultStatus'] ?? 'unknown'}');
    appLogger.i('[STEP 13] Repository.verifyFace() result: ${result?['resultStatus'] ?? 'unknown'}');
    return FaceResult.fromMap(result);
  }

  Future<KycResult> activate() async {
    appLogger.i('[FINAL] Repository.activate()');
    appLogger.i('  Finalizing KYC verification...');

    final result = await _channel.activate();
    
    final status = result?['resultStatus'] ?? 'unknown';
    appLogger.i('[FINAL] activate() result: $status');

    return KycResult.fromMap(result);
  }

  Future<OcrResult> getOcrResults() async {
    appLogger.i('Repository.getOcrResults() - fetching from SDK...');
    final result = await _channel.getOcrResults();
    if (result != null && result['ocr'] != null) {
      appLogger.i('Repository.getOcrResults() - SDK returned OCR data');
      return OcrResult.fromMap(result['ocr'] as Map<String, dynamic>);
    }
    appLogger.w('Repository.getOcrResults() - SDK returned null, returning empty');
    return OcrResult();
  }

  Future<bool> changeLanguage(DisplayLanguage language) async {
    return await _channel.changeLanguage(language);
  }

  Future<bool> customizeDesign({String? buttonColor, DisplayLanguage? language}) async {
    final result = await _channel.customizeDesign(
      buttonColor: buttonColor,
      language: language,
    );
    return result?['status'] == 'configured';
  }

  Future<bool> checkNfcAvailability() async {
    return await _channel.isNfcAvailable();
  }

  Future<String?> getSdkVersion() async {
    return await _channel.getSdkVersion();
  }

  Future<KycResult> executeKycFlow({
    required VerificationMethod method,
    required LiquidDocumentType documentType,
    bool showReviewScreen = true,
    FaceVerificationType faceType = FaceVerificationType.active,
    required Future<KycResult> Function() onInit,
    required Future<KycResult> Function() onTerms,
    required Future<DocumentResult> Function() onDocument,
    required Future<ChipVerificationResult> Function() onChip,
    required Future<FaceResult> Function() onFace,
    required Future<KycResult> Function() onActivate,
  }) async {
    final initResult = await onInit();
    if (!initResult.isSuccess) return initResult;

    final termsResult = await onTerms();
    if (!termsResult.isSuccess) return termsResult;

    DocumentResult? docResult;
    ChipVerificationResult? chipResult;
    FaceResult? faceResult;

    if (method.requiresDocument) {
      docResult = await onDocument();
      if (!docResult.isSuccess) {
        return KycResult.error(
          errorCode: 'DOCUMENT_ERROR',
          message: 'Document verification failed',
        );
      }
    }

    if (method.requiresIcCard) {
      chipResult = await onChip();
      if (!chipResult.isSuccess) {
        return KycResult.error(
          errorCode: 'CHIP_ERROR',
          message: 'IC card verification failed',
        );
      }
    }

    if (method.requiresFace) {
      faceResult = await onFace();
      if (!faceResult.isSuccess) {
        return KycResult.error(
          errorCode: 'FACE_ERROR',
          message: 'Face verification failed',
        );
      }
    }

    final activateResult = await onActivate();
    return activateResult;
  }
}