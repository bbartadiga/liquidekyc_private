class LiquidConfig {
  static const String channelName = 'com.liquid.ekyc/channel';

  // ============================================================
  // MODE CONFIGURATION - GANTI TRUE/FALSE DISINI
  // ============================================================
  // debugMode:
  //   true  = mock response, no SDK call, no camera
  //   false = call actual SDK, camera works
  // bypassBe:
  //   true  = skip BE call, use hardcoded credentials
  //   false = call BE to get token (need BE accessible)
  // ============================================================
  static const bool debugMode = false;
  static const bool bypassBe = false;

  // ============================================================
  // ENVIRONMENT SWITCH
  //   false = STAGING (default)
  //   true  = PRODUCTION
  //
  // Catatan: 第2世代在留カード (Gen-2 Residence Card) BELUM bisa dites di
  // env staging. Sudah tersedia di env production.
  // Ref: "17. 2nd Generation Residence Card_Specified Residence Card/1. …対応のご案内.pdf"
  //      (IC読取方式: 正式版 2026年7〜8月頃提供予定)
  //
  // Kredensial production BELUM diisi — minta ke Liquid CS (cs@liquidinc.asia)
  // atau isi dari "18. APIKey and Credential for BNI" sheet (tab 本番環境).
  // ============================================================
  static const bool useProduction = false;

  // ---- STAGING ----
  // SDK API URL   : applicantsdk-api.stg-liquid-ekyc.com
  // Connector URL : https://connector-bni.stg-liquid-ekyc.com
  //   (app ini lewat proxy BNI: https://103.108.254.29:8066/inbound-liquid)
  static const String _stgUrl = 'https://applicantsdk-api.stg-liquid-ekyc.com';
  static const String _stgApiKey =
      'JDJhJDEwJFRIQTBRTXllRG9tdnNNVEx3dHlVcXV4YTdvUWRyczZpbTJNVkZkNFYuM1hlL0taWXlMSDVX';
  static const String _stgBeUrl = 'https://103.108.254.29:8066';
  static const String _stgConnectorApiKey =
      'JDJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD';

  // ---- PRODUCTION ---- (isi dari Liquid CS)
  static const String _prodUrl = 'https://applicantsdk-api.liquid-ekyc.com';
  static const String _prodApiKey = '';
  static const String _prodBeUrl = '';
  static const String _prodConnectorApiKey = '';

  /// Credentials production belum diisi (ref: sheet "18. APIKey and Credential
  /// for BNI" tab 本番環境).
  ///
  /// Kalau switch production dinyalakan tanpa credentials, URL BE jadi string
  /// kosong → `Uri.parse('/inbound-liquid/...')` nggak punya scheme → semua
  /// request gagal dengan "No scheme specified". Jadi fallback ke staging.
  static bool get hasProductionConfig =>
      _prodUrl.isNotEmpty &&
      _prodApiKey.isNotEmpty &&
      _prodBeUrl.isNotEmpty &&
      _prodConnectorApiKey.isNotEmpty;

  /// Switch production yang efektif — cuma true kalau credentials-nya ada.
  static bool get effectiveUseProduction =>
      useProduction && hasProductionConfig;

  static String get url => effectiveUseProduction ? _prodUrl : _stgUrl;
  static String get apiKey => effectiveUseProduction ? _prodApiKey : _stgApiKey;
  static String get beUrl => effectiveUseProduction ? _prodBeUrl : _stgBeUrl;
  static String get connectorApiKey =>
      effectiveUseProduction ? _prodConnectorApiKey : _stgConnectorApiKey;

  // Credentials - STAGING (BNI Staging Environment)
  //    applicantId/token di bawah ini HARDCODE & token hanya berlaku 90 menit
  //    (ref: 017 SDKApply API). Jangan dipakai sebagai sumber kebenaran —
  //    flow normal selalu ambil token baru dari BE saat user klik "Ambil Token".

  // ApplicantId & Token - dari backend (dynamic) atau set manual untuk dev
  static const String applicantId = '111902224425';
  static const String token = 'a35f3549a21cfa7150615e4fe5aa6b2bfcb8dbf7798a65d1a1ec400e96d4ee55';

  static const int minSdkVersion = 24;
  static const Duration networkTimeout = Duration(seconds: 90);

  static bool get isDebugMode => debugMode;
  static bool get isRealMode => !debugMode;
  static bool get isProduction => effectiveUseProduction;
}

