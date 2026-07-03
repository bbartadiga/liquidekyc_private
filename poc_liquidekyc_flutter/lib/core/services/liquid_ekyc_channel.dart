import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constant/liquid_constants.dart';
import 'app_logger.dart';
import 'channel_init_handler.dart';
import 'channel_terms_handler.dart';
import 'channel_verification_handler.dart';
import 'channel_finalize_handler.dart';

class LiquidEkycChannel {
  static const MethodChannel _channel =
      MethodChannel(LiquidConfig.channelName);

  static final LiquidEkycChannel _instance = LiquidEkycChannel._internal();
  factory LiquidEkycChannel() => _instance;
  LiquidEkycChannel._internal();

  MethodChannel get channel => _channel;

  void log(String message) {
    if (kDebugMode) {
      debugPrint('[LiquidSDK] $message');
    }
  }

  bool get isDebugMode => LiquidConfig.isDebugMode;

  Future<Map<String, dynamic>?> startVerify({
    required String url,
    required String applicantId,
    required String token,
  }) => ChannelInitHandler.startVerify(
    this,
    url: url,
    applicantId: applicantId,
    token: token,
  );

  Future<Map<String, dynamic>?> startVerifyTrial({
    required String url,
    required String apiKey,
  }) => ChannelInitHandler.startVerifyTrial(
    this,
    url: url,
    apiKey: apiKey,
  );

  Future<Map<String, dynamic>?> showTermsOfUse() =>
      ChannelTermsHandler.showTermsOfUse(this);

  Future<Map<String, dynamic>?> verifyIdDocument({
    required LiquidDocumentType documentType,
    required VerificationMethod verificationMethod,
    bool showReviewScreen = true,
  }) => ChannelVerificationHandler.verifyIdDocument(
    this,
    documentType: documentType,
    verificationMethod: verificationMethod,
    showReviewScreen: showReviewScreen,
  );

  Future<Map<String, dynamic>?> verifyIdChip({
    required LiquidDocumentType documentType,
    required VerificationMethod verificationMethod,
    bool showReviewScreen = true,
  }) => ChannelVerificationHandler.verifyIdChip(
    this,
    documentType: documentType,
    verificationMethod: verificationMethod,
    showReviewScreen: showReviewScreen,
  );

  Future<Map<String, dynamic>?> identifyIdChip() =>
      ChannelVerificationHandler.identifyIdChip(this);

  Future<Map<String, dynamic>?> identifyIdMyna() =>
      ChannelVerificationHandler.identifyIdMyna(this);

  Future<Map<String, dynamic>?> verifyFace({
    bool showReviewScreen = true,
    FaceVerificationType faceVerificationType = FaceVerificationType.active,
  }) => ChannelVerificationHandler.verifyFace(
    this,
    showReviewScreen: showReviewScreen,
    faceVerificationType: faceVerificationType,
  );

  Future<Map<String, dynamic>?> activate() =>
      ChannelFinalizeHandler.activate(this);

  Future<Map<String, dynamic>?> customizeDesign({
    String? buttonColor,
    DisplayLanguage? language,
  }) => ChannelFinalizeHandler.customizeDesign(
    this,
    buttonColor: buttonColor,
    language: language,
  );

  Future<String?> getSdkVersion() =>
      ChannelFinalizeHandler.getSdkVersion(this);

  Future<bool> isNfcAvailable() =>
      ChannelFinalizeHandler.isNfcAvailable(this);

  Future<bool> changeLanguage(DisplayLanguage language) =>
      ChannelFinalizeHandler.changeLanguage(this, language);

  Future<Map<String, dynamic>?> getOcrResults() =>
      ChannelFinalizeHandler.getOcrResults(this);
}