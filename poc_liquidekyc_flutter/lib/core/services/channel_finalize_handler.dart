import 'dart:async';
import 'package:flutter/services.dart';
import '../constant/liquid_constants.dart';
import 'app_logger.dart';
import 'liquid_ekyc_channel.dart';

class ChannelFinalizeHandler {
  static Future<Map<String, dynamic>?> activate(
    LiquidEkycChannel channel,
  ) async {
    channel.log('[FINAL] Channel.activate() called - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');
    appLogger.i('[FINAL] Channel.activate()');
    appLogger.i('  Calling native plugin to finalize verification...');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(seconds: 1));
      channel.log('[FINAL] DEBUG MODE - returning mock activation success');
      appLogger.i('[FINAL] DEBUG MODE - returning mock activation success');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': 'DEBUG',
        'additionalDataMessage': 'Activation completed (DEBUG)',
      };
    }
    try {
      channel.log('[FINAL] Calling native activate...');
      appLogger.i('[FINAL] Invoking Flutter MethodChannel...');
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>('activate');
      final resultStatus = result?['resultStatus'] ?? 'unknown';
      final errorCode = result?['errorCode'];
      final message = result?['additionalDataMessage'] ?? result?['message'];
      channel.log('[FINAL] Activate result: $resultStatus');
      appLogger.i('[FINAL] RESULT - Status: $resultStatus, ErrorCode: $errorCode');
      if (resultStatus == 'ERROR') {
        appLogger.e('[FINAL] Activation ERROR!');
        appLogger.e('  ErrorCode: $errorCode');
        appLogger.e('  Message: $message');
      } else {
        appLogger.i('[FINAL] Activation SUCCESS!');
      }
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      channel.log('[FINAL] PlatformException: ${e.code} - ${e.message}');
      appLogger.e('[FINAL] PlatformException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'resultStatus': 'ERROR',
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      channel.log('[FINAL] Exception: $e');
      appLogger.e('[FINAL] Exception: $e');
      return {
        'success': false,
        'resultStatus': 'ERROR',
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> customizeDesign(
    LiquidEkycChannel channel, {
    String? buttonColor,
    DisplayLanguage? language,
  }) async {
    channel.log('customizeDesign called - buttonColor: $buttonColor, language: ${language?.value} - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      channel.log('customizeDesign returning DEBUG response');
      return {
        'status': 'configured',
        'buttonColor': buttonColor,
        'language': language?.value ?? 'AUTO',
      };
    }
    try {
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'customizeDesign',
        {
          'buttonColor': buttonColor,
          'language': language?.value,
        },
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

  static Future<String?> getSdkVersion(
    LiquidEkycChannel channel,
  ) async {
    channel.log('getSdkVersion called - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      return '1.47.0 (DEBUG MODE)';
    }
    try {
      final result = await channel.channel.invokeMethod<String>('getSdkVersion');
      channel.log('getSdkVersion result: $result');
      return result;
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<bool> isNfcAvailable(
    LiquidEkycChannel channel,
  ) async {
    channel.log('isNfcAvailable called - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      return true;
    }
    try {
      final result = await channel.channel.invokeMethod<bool>('isNfcAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> changeLanguage(
    LiquidEkycChannel channel,
    DisplayLanguage language,
  ) async {
    channel.log('changeLanguage called: ${language.value} - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      return true;
    }
    try {
      await channel.channel.invokeMethod('changeLanguage', {
        'language': language.value,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}