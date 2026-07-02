class LiquidConfig {
  static const String channelName = 'com.liquid.ekyc/channel';


  //sdk API key
  static const String url = 'https://applicantsdk-api.stg-liquid-ekyc.com';
  static const String applicantId = 'YOUR_APPLICANT_ID';
  static const String token = 'YOUR_AUTH_TOKEN';
  static const String apiKey = 'JDJhJDEwJFRIQTBRTXllRG9tdnNNVEx3dHlVcXV4YTdvUWRyczZpbTJNVkZkNFYuM1hlL0taWXlMSDVX';

  static const int minSdkVersion = 24;
  static const Duration networkTimeout = Duration(seconds: 90);
}

class LiquidCredentials {
  static const String apiUrl = LiquidConfig.url;
  static const String applicantId = LiquidConfig.applicantId;
  static const String token = LiquidConfig.token;
  static const String apiKey = LiquidConfig.apiKey;

  static bool get isConfigured {
    return apiUrl != LiquidConfig.url &&
        (applicantId != LiquidConfig.applicantId ||
         apiKey != LiquidConfig.apiKey);
  }

  static bool get isTrialMode {
    return apiKey.isNotEmpty && apiKey != LiquidConfig.apiKey;
  }

  static bool get isProductionMode {
    return applicantId != LiquidConfig.applicantId && token != LiquidConfig.token;
  }
}