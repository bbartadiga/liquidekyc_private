import 'dart:async';
import 'package:flutter/services.dart';
import '../constant/liquid_constants.dart';
import 'app_logger.dart';
import 'liquid_ekyc_channel.dart';

Map<String, dynamic> _convertMap(dynamic source) {
  if (source == null) return {};
  if (source is Map) {
    return Map<String, dynamic>.fromEntries(
      source.entries.map((e) => MapEntry(
        e.key.toString(),
        e.value is Map ? _convertMap(e.value) : e.value,
      )),
    );
  }
  return {};
}

class ChannelInitHandler {
  static Future<Map<String, dynamic>?> startVerify(
    LiquidEkycChannel channel, {
    required String url,
    required String applicantId,
    required String token,
  }) async {
    channel.log('[STEP 9] Channel.startVerify() called');
    channel.log('  applicantId: $applicantId');
    channel.log('  url: $url');

    appLogger.i('[STEP 9] Channel.startVerify() called');
    appLogger.i('  applicantId: $applicantId');
    appLogger.i('  url: $url');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      channel.log('[STEP 9] DEBUG MODE - returning mock success');
      appLogger.i('[STEP 9] DEBUG MODE - returning mock success');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': 'DEBUG MODE',
        'additionalDataMessage': 'Debug mode - verification simulated',
      };
    }
    try {
      channel.log('[STEP 9] Calling native plugin (startVerify)...');
      appLogger.i('[STEP 9] Calling native plugin (startVerify)...');

      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>('startVerify', {
        'url': url,
        'applicantId': applicantId,
        'token': token,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          appLogger.e('[STEP 9] TIMEOUT! startVerify did not respond in 30 seconds!');
          return {
            'resultStatus': 'ERROR',
            'errorCode': 'SE90001',
            'additionalDataTitle': 'Timeout',
            'additionalDataMessage': 'Native SDK initialization timeout'
          };
        },
      );
      channel.log('[STEP 9] Native plugin result: ${result?['resultStatus'] ?? 'unknown'}');
      appLogger.i('[STEP 9] Native plugin result: ${result?['resultStatus'] ?? 'unknown'}');
      return _convertMap(result);
    } on PlatformException catch (e) {
      channel.log('[STEP 9] PlatformException: ${e.code} - ${e.message}');
      appLogger.e('[STEP 9] PlatformException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'errorCode': e.code,
        'message': e.message,
      };
    } catch (e) {
      channel.log('[STEP 9] Exception: $e');
      appLogger.e('[STEP 9] Exception: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> startVerifyTrial(
    LiquidEkycChannel channel, {
    required String url,
    required String apiKey,
  }) async {
    channel.log('startVerifyTrial called - Mode: ${channel.isDebugMode ? "DEBUG" : "REAL"}');

    if (channel.isDebugMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      channel.log('startVerifyTrial returning DEBUG response');
      return {
        'resultStatus': 'SUCCESS',
        'errorCode': null,
        'additionalDataTitle': 'DEBUG MODE',
        'additionalDataMessage': 'Debug mode - trial verification simulated',
      };
    }
    try {
      final result = await channel.channel.invokeMethod<Map<dynamic, dynamic>>(
        'startVerifyTrial',
        {
          'url': url,
          'apiKey': apiKey,
        },
      );
      return _convertMap(result);
    } on PlatformException catch (e) {
      channel.log('startVerifyTrial ERROR: ${e.code}');
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