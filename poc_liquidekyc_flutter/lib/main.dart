import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.init();
  runApp(const LiquidEkycApp());
}