import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/app_logger.dart';
import 'core/services/telegram_log_uploader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.init();
  TelegramLogUploader.init(minLevel: LogLevel.debug);
  runApp(const LiquidEkycApp());
}