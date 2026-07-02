import 'dart:async';
import 'package:flutter/services.dart';
import '../constant/liquid_constants.dart';
import 'app_logger.dart';
import 'liquid_ekyc_channel.dart';

class ChannelVerificationHandler {
  static Future<Map<String, dynamic>?> verifyIdDocument(
    LiquidEkycChannel channel, {
    required LiquidDocumentType documentType,
    required VerificationMethod verificationMethod,
    bool showReviewScreen = true,
  }) async {
    channel.log('[STEP 12] verifyIdDocument() - docType: ${documentType.value}');
    appLogger.i('[STEP 12] verifyIdDocument() - docType: ${documentType.value}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      channel.log('[STEP 12] DEBUG - mock SUCCESS');
      appLogger.i('[STEP 12] DEBUG - mock SUCCESS');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': null,
        'additionalDataMessage': null,
        'autoVerificationResult': {
          'result': 'PASS',
          'message': 'Debug mode - document verified',
        },
      };
    }
    try {
      channel.log('[STEP 12] Calling native...');
      appLogger.i('[STEP 12] Calling native plugin...');
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'verifyIdDocument',
        {
          'documentType': documentType.value,
          'verificationMethod': verificationMethod.value,
          'showReviewScreen': showReviewScreen,
        },
      );
      
      final status = result?['resultStatus'] ?? 'N/A';
      final errorCode = result?['errorCode'];
      final errorMsg = result?['additionalDataMessage'] ?? result?['message'];
      
      channel.log('[STEP 12] RESULT - Status: $status, ErrorCode: $errorCode');
      appLogger.i('[STEP 12] RESULT - Status: $status, ErrorCode: $errorCode');
      
      // Handle empty error message from SDK
      if (status == 'ERROR' && (errorMsg == null || errorMsg.toString().isEmpty)) {
        channel.log('[STEP 12] ERROR - empty message from SDK');
        appLogger.e('[STEP 12] ERROR - SDK returned empty message');
        appLogger.e('  ErrorCode: $errorCode');
        appLogger.e('  Full result: $result');
        
        // Provide user-friendly fallback message based on error code
        String fallbackMsg;
        if (errorCode == 'SE10022') {
          fallbackMsg = 'Session expired after 90 minutes.';
        } else if (errorCode == 'SE10021') {
          fallbackMsg = 'Screen timeout - device inactive for 10 minutes. Restart verification.';
        } else if (errorCode == 'SE10011') {
          fallbackMsg = 'Camera access denied. Enable camera permission in settings.';
        } else if (errorCode == 'SE10012') {
          fallbackMsg = 'Camera not allowed when SDK started. Change device settings.';
        } else if (errorCode == 'SE05001') {
          fallbackMsg = 'Communication failure. Try in a place with better signal.';
        } else if (errorCode == 'SE90003') {
          fallbackMsg = 'Document scan timeout or quality too low. Ensure good lighting and hold document steady.';
        } else if (errorCode == 'SE90001') {
          fallbackMsg = 'Implementation error - SDK not properly initialized.';
        } else if (errorCode == 'SE80001') {
          fallbackMsg = 'Verification cancelled by user.';
        } else {
          fallbackMsg = 'Document scan failed (Code: ${errorCode ?? 'UNKNOWN'}). Please try again.';
        }
        
        return {
          'resultStatus': 'ERROR',
          'errorCode': errorCode ?? 'SE90003',
          'additionalDataTitle': 'Document Scan Failed',
          'additionalDataMessage': fallbackMsg,
          'autoVerificationResult': {
            'result': 'FAIL',
            'message': fallbackMsg,
          },
        };
      }
      
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      channel.log('[STEP 12] PlatformException: ${e.code} - ${e.message}');
      appLogger.e('[STEP 12] ERROR: ${e.code} - ${e.message}');
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      channel.log('[STEP 12] Exception: $e');
      appLogger.e('[STEP 12] Exception: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> verifyIdChip(
    LiquidEkycChannel channel, {
    required LiquidDocumentType documentType,
    required VerificationMethod verificationMethod,
    bool showReviewScreen = true,
  }) async {
    channel.log('[STEP 11] verifyIdChip() - docType: ${documentType.value}');
    appLogger.i('[STEP 11] verifyIdChip() - docType: ${documentType.value}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(seconds: 3));
      channel.log('[STEP 11] DEBUG - mock SUCCESS');
      appLogger.i('[STEP 11] DEBUG - mock SUCCESS');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': null,
        'additionalDataMessage': null,
        'autoVerificationResult': {
          'result': 'PASS',
          'message': 'Debug mode - IC chip verified',
        },
      };
    }
    try {
      channel.log('[STEP 11] Calling native...');
      appLogger.i('[STEP 11] Calling native plugin...');
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'verifyIdChip',
        {
          'documentType': documentType.value,
          'verificationMethod': verificationMethod.value,
          'showReviewScreen': showReviewScreen,
        },
      );
      
      final status = result?['resultStatus'] ?? 'N/A';
      final errorCode = result?['errorCode'];
      final errorMsg = result?['additionalDataMessage'] ?? result?['message'];
      
      channel.log('[STEP 11] RESULT - Status: $status, ErrorCode: $errorCode');
      appLogger.i('[STEP 11] RESULT - Status: $status, ErrorCode: $errorCode');
      
      // Log autoVerificationResult structure in detail
      final autoVerifyResult = result?['autoVerificationResult'];
      if (autoVerifyResult != null) {
        channel.log('[STEP 11] autoVerificationResult: $autoVerifyResult');
        appLogger.i('[STEP 11] autoVerificationResult: $autoVerifyResult');
        if (autoVerifyResult is Map) {
          final facePhoto = autoVerifyResult['autoVerificationFacePhoto'];
          final face = autoVerifyResult['autoVerificationFace'];
          final facePassive = autoVerifyResult['autoVerificationFacePassive'];
          channel.log('[STEP 11]   - facePhoto: $facePhoto');
          channel.log('[STEP 11]   - face: $face');
          channel.log('[STEP 11]   - facePassive: $facePassive');
          appLogger.i('[STEP 11]   - facePhoto: $facePhoto');
          appLogger.i('[STEP 11]   - face: $face');
          appLogger.i('[STEP 11]   - facePassive: $facePassive');
        }
      } else {
        channel.log('[STEP 11] autoVerificationResult: NULL');
        appLogger.i('[STEP 11] autoVerificationResult: NULL');
      }
      
      // Log documentImage if present
      final docImage = result?['documentImage'];
      if (docImage != null) {
        channel.log('[STEP 11] documentImage: present (base64 length: ${(docImage as Map)?['data']?.toString().length ?? 0})');
        appLogger.i('[STEP 11] documentImage: present');
      } else {
        channel.log('[STEP 11] documentImage: NULL');
        appLogger.i('[STEP 11] documentImage: NULL');
      }
      
      // Log chip data if present
      final chipData = result?['liquidChipData'];
      if (chipData != null && chipData is Map) {
        channel.log('[STEP 11] liquidChipData: present');
        appLogger.i('[STEP 11] liquidChipData: present');
        channel.log('[STEP 11]   name: ${chipData['name']}');
        channel.log('[STEP 11]   nameKana: ${chipData['nameKana']}');
        channel.log('[STEP 11]   birthday: ${chipData['birthday']}');
        channel.log('[STEP 11]   sex: ${chipData['sex']}');
        channel.log('[STEP 11]   address: ${chipData['address']}');
        channel.log('[STEP 11]   idNumber: ${chipData['idNumber']}');
        channel.log('[STEP 11]   issueDate: ${chipData['issueDate']}');
        channel.log('[STEP 11]   expireDate: ${chipData['expireDate']}');
        channel.log('[STEP 11]   idFacePhoto: ${chipData['idFacePhoto'] != null ? "present" : "null"}');
        channel.log('[STEP 11]   residenceCardType: ${chipData['residenceCardType']}');
        appLogger.i('[STEP 11]   name: ${chipData['name']}');
        appLogger.i('[STEP 11]   nameKana: ${chipData['nameKana']}');
        appLogger.i('[STEP 11]   birthday: ${chipData['birthday']}');
      } else {
        channel.log('[STEP 11] liquidChipData: NULL');
        appLogger.i('[STEP 11] liquidChipData: NULL');
      }
      
      // Log full result keys
      channel.log('[STEP 11] RESULT keys: ${result?.keys.toList()}');
      appLogger.i('[STEP 11] RESULT keys: ${result?.keys.toList()}');
      
      // Handle empty error message from SDK
      if (status == 'ERROR' && (errorMsg == null || errorMsg.toString().isEmpty)) {
        channel.log('[STEP 11] ERROR - empty message from SDK');
        appLogger.e('[STEP 11] ERROR - SDK returned empty message');
        appLogger.e('  ErrorCode: $errorCode');
        appLogger.e('  Full result: $result');
        
        String fallbackMsg = 'IC Card scan failed (Code: ${errorCode ?? 'UNKNOWN'}). Please ensure NFC is enabled and card is placed correctly.';
        
        return {
          'resultStatus': 'ERROR',
          'errorCode': errorCode ?? 'SE80001',
          'additionalDataTitle': 'IC Card Scan Failed',
          'additionalDataMessage': fallbackMsg,
          'autoVerificationResult': {
            'result': 'FAIL',
            'message': fallbackMsg,
          },
        };
      }
      
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      channel.log('[STEP 11] PlatformException: ${e.code} - ${e.message}');
      appLogger.e('[STEP 11] ERROR: ${e.code} - ${e.message}');
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      channel.log('[STEP 11] Exception: $e');
      appLogger.e('[STEP 11] Exception: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> verifyFace(
    LiquidEkycChannel channel, {
    bool showReviewScreen = true,
    FaceVerificationType faceVerificationType = FaceVerificationType.active,
  }) async {
    channel.log('[STEP 13] verifyFace() - type: ${faceVerificationType.value}');
    appLogger.i('[STEP 13] verifyFace() - type: ${faceVerificationType.value}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      channel.log('[STEP 13] DEBUG - mock SUCCESS');
      appLogger.i('[STEP 13] DEBUG - mock SUCCESS');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': null,
        'additionalDataMessage': null,
        'livenessResult': 'PASS',
        'matchScore': 850,
        'autoVerificationResult': {
          'result': 'PASS',
          'message': 'Debug mode - face verified',
        },
      };
    }
    try {
      channel.log('[STEP 13] Calling native...');
      appLogger.i('[STEP 13] Calling native plugin...');
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'verifyFace',
        {
          'showReviewScreen': showReviewScreen,
          'faceVerificationType': faceVerificationType.value,
        },
      );
      
      final status = result?['resultStatus'] ?? 'N/A';
      final errorCode = result?['errorCode'];
      final errorMsg = result?['additionalDataMessage'] ?? result?['message'];
      
      channel.log('[STEP 13] RESULT - Status: $status, ErrorCode: $errorCode');
      appLogger.i('[STEP 13] RESULT - Status: $status, ErrorCode: $errorCode');
      
      // Log autoVerificationResult structure in detail
      final faceAutoVerifyResult = result?['autoVerificationResult'];
      if (faceAutoVerifyResult != null) {
        channel.log('[STEP 13] autoVerificationResult: $faceAutoVerifyResult');
        appLogger.i('[STEP 13] autoVerificationResult: $faceAutoVerifyResult');
        if (faceAutoVerifyResult is Map) {
          final facePhoto = faceAutoVerifyResult['autoVerificationFacePhoto'];
          final face = faceAutoVerifyResult['autoVerificationFace'];
          final facePassive = faceAutoVerifyResult['autoVerificationFacePassive'];
          channel.log('[STEP 13]   - facePhoto: $facePhoto');
          channel.log('[STEP 13]   - face: $face');
          channel.log('[STEP 13]   - facePassive: $facePassive');
          appLogger.i('[STEP 13]   - facePhoto: $facePhoto');
          appLogger.i('[STEP 13]   - face: $face');
          appLogger.i('[STEP 13]   - facePassive: $facePassive');
        }
      } else {
        channel.log('[STEP 13] autoVerificationResult: NULL');
        appLogger.i('[STEP 13] autoVerificationResult: NULL');
      }
      
      // Log liveness and match score
      channel.log('[STEP 13] livenessResult: ${result?['livenessResult']}, matchScore: ${result?['matchScore']}');
      appLogger.i('[STEP 13] livenessResult: ${result?['livenessResult']}, matchScore: ${result?['matchScore']}');
      
      // Log full result keys
      channel.log('[STEP 13] RESULT keys: ${result?.keys.toList()}');
      appLogger.i('[STEP 13] RESULT keys: ${result?.keys.toList()}');
      
      // Handle empty error message from SDK
      if (status == 'ERROR' && (errorMsg == null || errorMsg.toString().isEmpty)) {
        channel.log('[STEP 13] ERROR - empty message from SDK');
        appLogger.e('[STEP 13] ERROR - SDK returned empty message');
        appLogger.e('  ErrorCode: $errorCode');
        appLogger.e('  Full result: $result');
        
        String fallbackMsg = 'Face verification failed (Code: ${errorCode ?? 'UNKNOWN'}). Please ensure face is clearly visible and lighting is good.';
        
        return {
          'resultStatus': 'ERROR',
          'errorCode': errorCode ?? 'SE10002',
          'additionalDataTitle': 'Face Verification Failed',
          'additionalDataMessage': fallbackMsg,
          'autoVerificationResult': {
            'result': 'FAIL',
            'message': fallbackMsg,
          },
        };
      }
      
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      channel.log('[STEP 13] PlatformException: ${e.code} - ${e.message}');
      appLogger.e('[STEP 13] ERROR: ${e.code} - ${e.message}');
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      channel.log('[STEP 13] Exception: $e');
      appLogger.e('[STEP 13] Exception: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> identifyIdChip(
    LiquidEkycChannel channel,
  ) async {
    channel.log('identifyIdChip called - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(seconds: 3));
      channel.log('identifyIdChip returning DEBUG response');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': null,
        'additionalDataMessage': null,
        'municipalityName': 'Debug City',
        'serialNumber': 'DB12345678',
        'myNumber': '1234567890123',
        'name': 'Debug User',
        'address': '123 Debug Street, Debug City',
        'dateOfBirth': '1990-01-01',
        'sex': 'MALE',
      };
    }
    try {
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'identifyIdChip',
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      channel.log('identifyIdChip ERROR: ${e.code}');
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> identifyIdMyna(
    LiquidEkycChannel channel,
  ) async {
    channel.log('identifyIdMyna called - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      channel.log('identifyIdMyna returning DEBUG response');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': null,
        'additionalDataMessage': null,
        'name': 'Debug Myna User',
        'address': '456 Debug Ave, Debug Town',
        'dateOfBirth': '1995-05-15',
        'sex': 'FEMALE',
      };
    }
    try {
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'identifyIdMyna',
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }
}