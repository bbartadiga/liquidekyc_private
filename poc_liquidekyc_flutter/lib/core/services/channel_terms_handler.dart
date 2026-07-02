import 'dart:async';
import 'package:flutter/services.dart';
import '../constant/liquid_constants.dart';
import 'app_logger.dart';
import 'liquid_ekyc_channel.dart';

class ChannelTermsHandler {
  static Future<Map<String, dynamic>?> showTermsOfUse(
    LiquidEkycChannel channel,
  ) async {
    channel.log('[STEP 10] Channel.showTermsOfUse() called');
    appLogger.i('[STEP 10] Channel.showTermsOfUse() called');
    appLogger.i('  isDebugMode: ${channel.isDebugMode}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      channel.log('[STEP 10] DEBUG MODE - returning mock terms accepted');
      appLogger.i('[STEP 10] DEBUG MODE - returning mock terms accepted');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': 'DEBUG MODE',
        'additionalDataMessage': 'Terms accepted (debug mode)',
      };
    }
    
    try {
      appLogger.i('===========================================');
      appLogger.i('[STEP 10] Calling native plugin via MethodChannel...');
      appLogger.i('  Method: showTermsOfUse');
      appLogger.i('  Channel: ${LiquidConfig.channelName}');
      appLogger.i('===========================================');

      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'showTermsOfUse',
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          appLogger.e('===========================================');
          appLogger.e('[STEP 10] TIMEOUT! Native did not respond in 60 seconds!');
          appLogger.e('[STEP 10] Possible causes:');
          appLogger.e('  1. Native crash during SDK init');
          appLogger.e('  2. showTermsOfUseLauncher.launch() blocking');
          appLogger.e('  3. SDK internal error');
          appLogger.e('===========================================');
          return {
            'resultStatus': 'ERROR',
            'errorCode': 'SE90001',
            'additionalDataTitle': 'Timeout',
            'additionalDataMessage': 'Native SDK tidak merespon dalam 60 detik. Kemungkinan terjadi crash di native layer.'
          };
        },
      );
      
      final resultStatus = result?['resultStatus'] ?? 'unknown';
      final errorCode = result?['errorCode'];
      final errorMessage = result?['additionalDataMessage'] ?? result?['message'];
      
      channel.log('[STEP 10] RESULT - Status: $resultStatus, ErrorCode: $errorCode');
      appLogger.i('===========================================');
      appLogger.i('[STEP 10] RESULT RECEIVED');
      appLogger.i('  Status: $resultStatus');
      appLogger.i('  ErrorCode: ${errorCode ?? "none"}');
      appLogger.i('  Message: ${errorMessage ?? "none"}');
      appLogger.i('===========================================');
      
      if (resultStatus == 'ERROR') {
        appLogger.e('[STEP 10] SDK RETURNED ERROR!');
        appLogger.e('  ErrorCode: $errorCode');
        appLogger.e('  Message: $errorMessage');
      }
      
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      channel.log('[STEP 10] PlatformException: ${e.code} - ${e.message}');
      appLogger.e('===========================================');
      appLogger.e('[STEP 10] PlatformException (Native Error)!');
      appLogger.e('  Code: ${e.code}');
      appLogger.e('  Message: ${e.message}');
      appLogger.e('  Details: ${e.details}');
      appLogger.e('===========================================');
      return {
        'success': false,
        'resultStatus': 'ERROR',
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      channel.log('[STEP 10] Exception: $e');
      appLogger.e('===========================================');
      appLogger.e('[STEP 10] Exception (Unknown Error)!');
      appLogger.e('  Error: $e');
      appLogger.e('  Stack: ${StackTrace.current}');
      appLogger.e('===========================================');
      return {
        'success': false,
        'resultStatus': 'ERROR',
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }
}