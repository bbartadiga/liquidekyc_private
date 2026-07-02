import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constant/liquid_constants.dart';
import '../core/screens/debug_log_screen.dart';
import '../persentation/viewmodels/kyc_viewmodel.dart';
import '../persentation/views/screens/kyc_home_screen.dart';

class LiquidEkycApp extends StatelessWidget {
  const LiquidEkycApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KycViewModel(),
      child: MaterialApp(
        title: 'Liquid eKYC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        home: KycHomeScreen(),
        routes: {
          '/debug': (context) => const DebugLogScreen(),
        },
      ),
    );
  }
}

class LiquidEkycConfig {
  static const String apiUrl = LiquidConfig.url;
  // Production mode: uncomment these
  // static const String applicantId = LiquidConfig.applicantId;
  // static const String token = LiquidConfig.token;
  static const String apiKey = LiquidConfig.apiKey;

  static bool get isConfigured {
    return apiUrl.isNotEmpty &&
        apiKey.isNotEmpty &&
        apiKey != 'YOUR_API_KEY_FOR_TRIAL';
  }

  static bool get isTrialMode {
    return apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY_FOR_TRIAL';
  }
}
