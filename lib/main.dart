import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/constant/liquid_constants.dart';
import 'core/services/app_logger.dart';
import 'core/services/liquid_ekyc_channel.dart';
import 'core/services/telegram_log_uploader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.init();
  TelegramLogUploader.init(minLevel: LogLevel.debug);

  // Pasang handler log native (invokeMethod dari Kotlin) sebelum plugin
  // native mulai nelen log — kalau belakangan, log SDK awal akan hilang.
  LiquidEkycChannel();

  if (LiquidConfig.useProduction && !LiquidConfig.hasProductionConfig) {
    appLogger.e(
      'Production mode aktif tapi credentials production belum diisi — '
      'fallback ke STAGING. Isi _prodApiKey / _prodBeUrl / _prodConnectorApiKey '
      'di liquid_config.dart dulu.',
    );
  }
  appLogger.i(
    'Config | env:${LiquidConfig.effectiveUseProduction ? "PRODUCTION" : "STAGING"} '
    '| sdkUrl:${LiquidConfig.url} | beUrl:${LiquidConfig.beUrl}',
  );

  runApp(const LiquidEkycApp());
}